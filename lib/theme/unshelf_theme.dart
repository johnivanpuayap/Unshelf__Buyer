import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

abstract class UnshelfTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: UnshelfTokens.colorLightPrimary,
      onPrimary: UnshelfTokens.colorLightOnPrimary,
      secondary: UnshelfTokens.colorLightAccent,
      onSecondary: UnshelfTokens.colorLightForeground,
      tertiary: UnshelfTokens.colorLightHighlight,
      error: UnshelfTokens.colorLightDestructive,
      onError: UnshelfTokens.colorLightOnPrimary,
      surface: UnshelfTokens.colorLightBackground,
      onSurface: UnshelfTokens.colorLightForeground,
      surfaceContainerHighest: UnshelfTokens.colorLightSurface,
      outline: UnshelfTokens.colorLightBorder,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: UnshelfTokens.colorLightBackground,
      textTheme: _textTheme(colorScheme.onSurface),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      filledButtonTheme: _filledButtonTheme(colorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(colorScheme),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      cardTheme: _cardTheme(colorScheme),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: UnshelfTokens.colorDarkPrimary,
      onPrimary: UnshelfTokens.colorDarkOnPrimary,
      secondary: UnshelfTokens.colorDarkAccent,
      onSecondary: UnshelfTokens.colorDarkForeground,
      tertiary: UnshelfTokens.colorDarkHighlight,
      error: UnshelfTokens.colorDarkDestructive,
      onError: UnshelfTokens.colorDarkOnPrimary,
      surface: UnshelfTokens.colorDarkBackground,
      onSurface: UnshelfTokens.colorDarkForeground,
      surfaceContainerHighest: UnshelfTokens.colorDarkSurface,
      outline: UnshelfTokens.colorDarkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: UnshelfTokens.colorDarkBackground,
      textTheme: _textTheme(colorScheme.onSurface),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      filledButtonTheme: _filledButtonTheme(colorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(colorScheme),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      cardTheme: _cardTheme(colorScheme),
    );
  }

  /// Pre-registers DM Serif Display and DM Sans with the Flutter font system.
  ///
  /// Call this once from [main] (before [runApp]) so fonts are available for
  /// the first frame.  [light] and [light.textTheme] references 'DM Serif
  /// Display' / 'DM Sans' by name; these calls ensure those names resolve to
  /// the actual typefaces downloaded/cached by the google_fonts package.
  static void preloadFonts() {
    GoogleFonts.dmSerifDisplay();
    GoogleFonts.dmSans();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static TextTheme _textTheme(Color onSurface) {
    // Build TextStyle objects with the human-readable font-family names that
    // match what google_fonts registers via preloadFonts().  Constructing
    // styles this way is side-effect-free (no async font loads), which keeps
    // tests clean while still producing the correct fontFamily strings.
    TextStyle serif({
      double? fontSize,
      FontWeight fontWeight = FontWeight.w400,
      double? height,
    }) =>
        TextStyle(
          fontFamily: 'DM Serif Display',
          color: onSurface,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
        );

    TextStyle sans({
      double? fontSize,
      FontWeight fontWeight = FontWeight.w400,
      double? height,
    }) =>
        TextStyle(
          fontFamily: 'DM Sans',
          color: onSurface,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
        );

    return TextTheme(
      displayLarge:
          serif(fontSize: 57, fontWeight: FontWeight.w400, height: 1.12),
      displayMedium:
          serif(fontSize: 45, fontWeight: FontWeight.w400, height: 1.16),
      displaySmall:
          serif(fontSize: 36, fontWeight: FontWeight.w400, height: 1.22),
      headlineLarge:
          serif(fontSize: 32, fontWeight: FontWeight.w400, height: 1.25),
      headlineMedium:
          serif(fontSize: 28, fontWeight: FontWeight.w400, height: 1.29),
      headlineSmall:
          serif(fontSize: 24, fontWeight: FontWeight.w400, height: 1.33),
      titleLarge:
          serif(fontSize: 22, fontWeight: FontWeight.w400, height: 1.27),
      titleMedium:
          sans(fontSize: 16, fontWeight: FontWeight.w600, height: 1.50),
      titleSmall: sans(fontSize: 14, fontWeight: FontWeight.w600, height: 1.43),
      bodyLarge: sans(fontSize: 16, fontWeight: FontWeight.w400, height: 1.50),
      bodyMedium:
          sans(fontSize: 14, fontWeight: FontWeight.w400, height: 1.43),
      bodySmall: sans(fontSize: 12, fontWeight: FontWeight.w400, height: 1.33),
      labelLarge:
          sans(fontSize: 14, fontWeight: FontWeight.w600, height: 1.43),
      labelMedium:
          sans(fontSize: 12, fontWeight: FontWeight.w500, height: 1.33),
      labelSmall:
          sans(fontSize: 11, fontWeight: FontWeight.w500, height: 1.45),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme cs) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          padding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: const StadiumBorder(),
        ),
      );

  static FilledButtonThemeData _filledButtonTheme(ColorScheme cs) =>
      FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.secondary,
          foregroundColor: cs.onSecondary,
          padding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: const StadiumBorder(),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme cs) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.outline, width: 1.5),
          padding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: const StadiumBorder(),
        ),
      );

  static InputDecorationTheme _inputDecorationTheme(ColorScheme cs) =>
      InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.45),
          fontFamily: 'DM Sans',
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.75),
          fontFamily: 'DM Sans',
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: cs.primary,
          fontFamily: 'DM Sans',
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.6), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.6), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error.withValues(alpha: 0.7), width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
      );

  static CardThemeData _cardTheme(ColorScheme cs) => CardThemeData(
        color: cs.surfaceContainerHighest,
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );
}
