import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A GPU-accelerated, interactive fluid mesh gradient canvas.
///
/// Responds dynamically to touch/drag gestures with elastic inertia and renders
/// procedural glowing particle sparks floating upward.
class InteractiveGradientCanvas extends StatefulWidget {
  final Widget? child;
  final List<Color>? palette;

  const InteractiveGradientCanvas({
    super.key,
    this.child,
    this.palette,
  });

  @override
  State<InteractiveGradientCanvas> createState() =>
      _InteractiveGradientCanvasState();
}

class _InteractiveGradientCanvasState extends State<InteractiveGradientCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  // Touch drag offset for interactive liquid shift
  Offset _dragOffset = Offset.zero;

  // Particle positions
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random(42);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Generate initial floating particles
    for (int i = 0; i < 18; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          radius: 1.5 + _random.nextDouble() * 2.5,
          speed: 0.0003 + _random.nextDouble() * 0.0006,
          opacity: 0.2 + _random.nextDouble() * 0.5,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta * 0.6;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.palette ??
        [
          AppTheme.backgroundCream,
          AppTheme.primarySage,
          AppTheme.secondaryCoral,
          AppTheme.accentLavender,
        ];

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: _animCtrl,
        builder: (context, child) {
          // Apply gentle dampening to drag offset
          _dragOffset = Offset(
            _dragOffset.dx * 0.94,
            _dragOffset.dy * 0.94,
          );

          // Update particle positions
          for (final p in _particles) {
            p.y -= p.speed;
            if (p.y < -0.05) p.y = 1.05;
          }

          return CustomPaint(
            painter: _MeshGradientPainter(
              time: _animCtrl.value,
              dragOffset: _dragOffset,
              colors: colors,
              particles: _particles,
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  double radius;
  double speed;
  double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
  });
}

class _MeshGradientPainter extends CustomPainter {
  final double time;
  final Offset dragOffset;
  final List<Color> colors;
  final List<_Particle> particles;

  _MeshGradientPainter({
    required this.time,
    required this.dragOffset,
    required this.colors,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = colors[0],
    );

    final t = time * 2 * math.pi;

    // Node 1: Sage Blob (Top Left / Moving)
    final n1x = w * 0.25 + math.sin(t * 0.8) * 35 + dragOffset.dx * 0.5;
    final n1y = h * 0.30 + math.cos(t * 0.6) * 40 + dragOffset.dy * 0.5;
    final p1 = Paint()
      ..shader = RadialGradient(
        colors: [
          colors[1].withValues(alpha: 0.45),
          colors[1].withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(n1x, n1y), radius: w * 0.70));
    canvas.drawCircle(Offset(n1x, n1y), w * 0.70, p1);

    // Node 2: Coral Blob (Bottom Right / Moving opposite)
    final n2x = w * 0.75 + math.cos(t * 0.7) * 40 - dragOffset.dx * 0.4;
    final n2y = h * 0.45 + math.sin(t * 0.9) * 35 - dragOffset.dy * 0.4;
    final p2 = Paint()
      ..shader = RadialGradient(
        colors: [
          colors[2].withValues(alpha: 0.35),
          colors[2].withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(n2x, n2y), radius: w * 0.65));
    canvas.drawCircle(Offset(n2x, n2y), w * 0.65, p2);

    // Node 3: Lavender Blob (Center Glow)
    final n3x = w * 0.50 + math.sin(t * 1.2) * 25 + dragOffset.dx * 0.2;
    final n3y = h * 0.65 + math.cos(t * 1.1) * 30 + dragOffset.dy * 0.2;
    final p3 = Paint()
      ..shader = RadialGradient(
        colors: [
          colors[3].withValues(alpha: 0.30),
          colors[3].withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(n3x, n3y), radius: w * 0.60));
    canvas.drawCircle(Offset(n3x, n3y), w * 0.60, p3);

    // Draw floating particle sparks
    for (final p in particles) {
      final px = p.x * w + math.sin(t * 2 + p.y * 10) * 12;
      final py = p.y * h;
      final sparkPaint = Paint()
        ..color = Colors.white.withValues(alpha: p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(px, py), p.radius, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(_MeshGradientPainter oldDelegate) => true;
}
