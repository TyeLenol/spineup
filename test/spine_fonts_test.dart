import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spineup/theme/spine_fonts.dart';

void main() {
  test(
    'uses the registered Fraunces family and preserves requested weight',
    () {
      final style = SpineFonts.fraunces(fontWeight: FontWeight.w800);

      expect(style.fontFamily, 'Fraunces');
      expect(style.fontWeight, FontWeight.w800);
    },
  );

  test('uses the registered Outfit family and preserves requested weight', () {
    final style = SpineFonts.outfit(fontWeight: FontWeight.w600);

    expect(style.fontFamily, 'Outfit');
    expect(style.fontWeight, FontWeight.w600);
  });
}
