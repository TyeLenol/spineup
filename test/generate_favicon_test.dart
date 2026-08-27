import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate Favicon', () async {
    final size = const Size(1024, 1024);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

    // Fill background (AppTheme.primarySage is Color(0xFF6B8068))
    final bgPaint = Paint()..color = const Color(0xFF6B8068);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Spine Logo Painter logic scaled to center
    // the original is 128x128. Let's scale up to fit well in 1024x1024.
    // e.g. center a 768x768 box.
    final padding = 128.0;
    final boxSize = size.width - (padding * 2);

    canvas.translate(padding, padding);
    final color = const Color(0xFF1B231A); // AppTheme.onPrimaryDark

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12 * (boxSize / 100) // Scale stroke width proportionally
      ..strokeCap = StrokeCap.round;

    final scaleX = boxSize / 100;
    final scaleY = boxSize / 100;

    final path = Path();
    path.moveTo(30 * scaleX, 70 * scaleY);
    path.cubicTo(
      30 * scaleX,
      50 * scaleY,
      70 * scaleX,
      50 * scaleY,
      70 * scaleX,
      30 * scaleY,
    );
    path.cubicTo(
      70 * scaleX,
      15 * scaleY,
      50 * scaleX,
      15 * scaleY,
      30 * scaleX,
      30 * scaleY,
    );

    canvas.drawPath(path, strokePaint);

    // Draw dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(30 * scaleX, 85 * scaleY),
      8 * scaleX, // Scale dot radius
      dotPaint,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    
    // Convert to PNG first, because JPEG encoding is not built-in dart:ui
    // We will save as PNG, and then the user can use it as is or we can convert it.
    // Wait, dart:ui only supports PNG encoding reliably.
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final file = File('favicon.png');
    await file.writeAsBytes(buffer);
    print('Generated favicon.png');
  });
}
