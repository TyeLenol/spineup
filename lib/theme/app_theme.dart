import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Brand Colors (Light Theme)
  static const Color primarySage = Color(0xFF5DCAA5);
  static const Color onPrimaryDark = Color(0xFF0A3324);
  static const Color secondaryCoral = Color(0xFFD85A30);
  static const Color onSecondaryWhite = Color(0xFFFFFFFF);
  static const Color accentLavender = Color(0xFF7F77DD);
  static const Color backgroundCream = Color(0xFFFAEEDA);
  static const Color foregroundDark = Color(0xFF2D2824);
  static const Color cardCream = Color(0xFFF0E2CA);
  static const Color mutedCream = Color(0xFFEADBC0);
  static const Color mutedForeground = Color(0xFF6B6158);
  static const Color borderCream = Color(0xFFDDCDB0);

  // Profile setup palette: quieter and more editorial than the gamified app
  // palette, so sensitive health questions feel calm, private, and deliberate.
  static const Color profileCanvas = Color(0xFFF6F8F5);
  static const Color profileSurface = Color(0xFFFFFFFF);
  static const Color profileSoftSage = Color(0xFFE7F2EC);
  static const Color profileSage = Color(0xFF2F8668);
  static const Color profileMuted = Color(0xFF68736D);
  static const Color profileBorder = Color(0xFFD5E1DA);
  static const Color profileWarm = Color(0xFFF3E8DD);

  // Brand Colors (Dark Theme)
  static const Color darkBackground = Color(0xFF241E19);
  static const Color darkForeground = Color(0xFFF0E9DF);
  static const Color darkCard = Color(0xFF332B24);
  static const Color darkPrimary = Color(0xFF6EE0B8);
  static const Color darkSecondary = Color(0xFFF07145);
  static const Color darkAccent = Color(0xFF9A93E8);
  static const Color darkMuted = Color(0xFF3D352E);
  static const Color darkMutedForeground = Color(0xFFA19890);
  static const Color darkBorder = Color(0xFF4D453E);

  static TextTheme _buildTextTheme(TextTheme base, Color foregroundColor) {
    final headingFont = GoogleFonts.frauncesTextTheme(base);
    final bodyFont = GoogleFonts.outfitTextTheme(base);

    return base.copyWith(
      displayLarge: headingFont.displayLarge?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displayMedium: headingFont.displayMedium?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: headingFont.displaySmall?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: headingFont.headlineLarge?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: headingFont.headlineMedium?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: headingFont.headlineSmall?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: headingFont.titleLarge?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: bodyFont.titleMedium?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: bodyFont.titleSmall?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: bodyFont.bodyLarge?.copyWith(
        color: foregroundColor,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: bodyFont.bodyMedium?.copyWith(
        color: foregroundColor,
        fontSize: 14,
        height: 1.4,
      ),
      bodySmall: bodyFont.bodySmall?.copyWith(
        color: foregroundColor,
        fontSize: 12,
      ),
      labelLarge: bodyFont.labelLarge?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      labelMedium: bodyFont.labelMedium?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: bodyFont.labelSmall?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primarySage,
      onPrimary: onPrimaryDark,
      secondary: secondaryCoral,
      onSecondary: onSecondaryWhite,
      tertiary: accentLavender,
      onTertiary: onSecondaryWhite,
      surface: backgroundCream,
      onSurface: foregroundDark,
      surfaceContainer: cardCream,
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
    );

    final baseText = ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundCream,
      textTheme: _buildTextTheme(baseText, foregroundDark),
      cardTheme: CardThemeData(
        color: cardCream,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderCream, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardCream,
        indicatorColor: secondaryCoral.withValues(alpha: 0.2),
        elevation: 3,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: secondaryCoral,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: mutedForeground,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: secondaryCoral, size: 24);
          }
          return const IconThemeData(color: mutedForeground, size: 24);
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: darkPrimary,
      onPrimary: onPrimaryDark,
      secondary: darkSecondary,
      onSecondary: onSecondaryWhite,
      tertiary: darkAccent,
      onTertiary: Color(0xFF191636),
      surface: darkBackground,
      onSurface: darkForeground,
      surfaceContainer: darkCard,
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
    );

    final baseText = ThemeData.dark().textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      textTheme: _buildTextTheme(baseText, darkForeground),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkCard,
        indicatorColor: darkSecondary.withValues(alpha: 0.2),
        elevation: 3,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: darkSecondary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: darkMutedForeground,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: darkSecondary, size: 24);
          }
          return const IconThemeData(color: darkMutedForeground, size: 24);
        }),
      ),
    );
  }
}
