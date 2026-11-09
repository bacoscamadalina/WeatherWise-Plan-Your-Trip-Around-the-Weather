import 'package:flutter/material.dart';

abstract final class AtlasColors {
  static const ivory = Color(0xFFFFF9ED);
  static const paper = Color(0xFFFFFEFB);
  static const ink = Color(0xFF153A59);
  static const mutedInk = Color(0xFF587083);
  static const azure = Color(0xFF168AAD);
  static const sky = Color(0xFFD9F1FA);
  static const gold = Color(0xFFFFC94A);
  static const paleGold = Color(0xFFFFF1BB);
  static const coral = Color(0xFFF26B4A);
  static const mint = Color(0xFFDDF3E9);
  static const teal = Color(0xFF197B73);
  static const line = Color(0xFFDCE4E2);
  static const rain = Color(0xFF5BA9D1);
  static const cloud = Color(0xFF91A6B4);
}

abstract final class AtlasTheme {
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AtlasColors.azure,
      onPrimary: Colors.white,
      primaryContainer: AtlasColors.sky,
      onPrimaryContainer: AtlasColors.ink,
      secondary: AtlasColors.teal,
      onSecondary: Colors.white,
      secondaryContainer: AtlasColors.mint,
      onSecondaryContainer: AtlasColors.ink,
      tertiary: Color(0xFFB97500),
      onTertiary: Colors.white,
      tertiaryContainer: AtlasColors.paleGold,
      onTertiaryContainer: AtlasColors.ink,
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      surface: AtlasColors.ivory,
      onSurface: AtlasColors.ink,
      surfaceContainerLowest: AtlasColors.paper,
      surfaceContainerLow: Color(0xFFFFFBF3),
      surfaceContainer: Color(0xFFF7F3E9),
      surfaceContainerHigh: Color(0xFFF0EDE5),
      surfaceContainerHighest: Color(0xFFE8E7E2),
      onSurfaceVariant: AtlasColors.mutedInk,
      outline: Color(0xFF82929B),
      outlineVariant: AtlasColors.line,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: AtlasColors.ivory,
    );
    final text = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontFamily: 'Georgia',
        color: AtlasColors.ink,
        fontWeight: FontWeight.w500,
        letterSpacing: -2.2,
      ),
      displayMedium: base.textTheme.displayMedium?.copyWith(
        fontFamily: 'Georgia',
        color: AtlasColors.ink,
        fontWeight: FontWeight.w500,
        letterSpacing: -1.4,
      ),
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontFamily: 'Georgia',
        color: AtlasColors.ink,
        fontWeight: FontWeight.w600,
        letterSpacing: -.8,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontFamily: 'Georgia',
        color: AtlasColors.ink,
        fontWeight: FontWeight.w600,
        letterSpacing: -.6,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontFamily: 'Georgia',
        color: AtlasColors.ink,
        fontWeight: FontWeight.w600,
        letterSpacing: -.45,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontFamily: 'Georgia',
        color: AtlasColors.ink,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        color: AtlasColors.ink,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: AtlasColors.ink,
        height: 1.45,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: AtlasColors.ink,
        height: 1.42,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        color: AtlasColors.mutedInk,
        height: 1.35,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );

    return base.copyWith(
      textTheme: text,
      iconTheme: const IconThemeData(color: AtlasColors.ink),
      dividerColor: AtlasColors.line,
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: 7),
        color: AtlasColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AtlasColors.paper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AtlasColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AtlasColors.line),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: const WidgetStatePropertyAll(AtlasColors.paper),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        side: const WidgetStatePropertyAll(
          BorderSide(color: AtlasColors.line),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        constraints: const BoxConstraints(minHeight: 54),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AtlasColors.paper,
        selectedColor: AtlasColors.sky,
        side: const BorderSide(color: AtlasColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(
          color: AtlasColors.ink,
          fontFamily: 'Roboto',
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: AtlasColors.gold,
          foregroundColor: AtlasColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AtlasColors.ink,
          side: const BorderSide(color: AtlasColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AtlasColors.azure,
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AtlasColors.ink,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
