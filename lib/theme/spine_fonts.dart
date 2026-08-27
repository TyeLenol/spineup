import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Centralised typography for SpineUp.
///
/// The font files are declared as Flutter assets in pubspec.yaml. Keeping the
/// family names here avoids runtime font fetching and makes Android release,
/// debug, Web, and offline renders use the same typefaces.
class SpineFonts {
  SpineFonts._();

  static TextStyle fraunces({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<ui.Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return _textStyle(
      'Fraunces',
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }

  static TextStyle outfit({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<ui.Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return _textStyle(
      'Outfit',
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }

  static TextTheme frauncesTextTheme([TextTheme? textTheme]) {
    return _textTheme('Fraunces', textTheme ?? ThemeData.light().textTheme);
  }

  static TextTheme outfitTextTheme([TextTheme? textTheme]) {
    return _textTheme('Outfit', textTheme ?? ThemeData.light().textTheme);
  }

  static TextStyle _textStyle(
    String family, {
    required TextStyle? textStyle,
    required Color? color,
    required Color? backgroundColor,
    required double? fontSize,
    required FontWeight? fontWeight,
    required FontStyle? fontStyle,
    required double? letterSpacing,
    required double? wordSpacing,
    required TextBaseline? textBaseline,
    required double? height,
    required Locale? locale,
    required Paint? foreground,
    required Paint? background,
    required List<ui.Shadow>? shadows,
    required List<ui.FontFeature>? fontFeatures,
    required TextDecoration? decoration,
    required Color? decorationColor,
    required TextDecorationStyle? decorationStyle,
    required double? decorationThickness,
  }) {
    return (textStyle ?? const TextStyle()).copyWith(
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      fontFamily: family,
    );
  }

  static TextTheme _textTheme(String family, TextTheme base) {
    return base.copyWith(
      displayLarge: _withFamily(family, base.displayLarge),
      displayMedium: _withFamily(family, base.displayMedium),
      displaySmall: _withFamily(family, base.displaySmall),
      headlineLarge: _withFamily(family, base.headlineLarge),
      headlineMedium: _withFamily(family, base.headlineMedium),
      headlineSmall: _withFamily(family, base.headlineSmall),
      titleLarge: _withFamily(family, base.titleLarge),
      titleMedium: _withFamily(family, base.titleMedium),
      titleSmall: _withFamily(family, base.titleSmall),
      bodyLarge: _withFamily(family, base.bodyLarge),
      bodyMedium: _withFamily(family, base.bodyMedium),
      bodySmall: _withFamily(family, base.bodySmall),
      labelLarge: _withFamily(family, base.labelLarge),
      labelMedium: _withFamily(family, base.labelMedium),
      labelSmall: _withFamily(family, base.labelSmall),
    );
  }

  static TextStyle? _withFamily(String family, TextStyle? style) {
    return style?.copyWith(fontFamily: family);
  }
}
