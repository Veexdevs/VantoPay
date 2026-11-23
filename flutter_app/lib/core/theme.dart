import 'package:flutter/material.dart';

/// Official VantoPay identity: strictly monochrome, minimalist, premium.
///
/// No accent colours are used — hierarchy is expressed through weight,
/// opacity, spacing and geometry. The official logo assets provide the brand
/// mark.
class VantoPayTheme {
  VantoPayTheme._();

  // Palette — pure black & white only.
  static const Color black = Color(0xFF000000);
  static const Color paper = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0A0A0A); // near-black surface
  static const Color surface = Color(0xFF121212); // elevated dark surface
  static const Color surfaceAlt = Color(0xFF1A1A1A);
  static const Color line = Color(0xFF2A2A2A); // hairline on dark
  static const Color paperLine = Color(0xFFE6E6E6); // hairline on light
  static const Color ghost = Color(0xFF8A8A8E); // muted text

  static const String fontFamily = ''; // system font stack

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: paper,
      onPrimary: black,
      secondary: paper,
      onSecondary: black,
      surface: ink,
      onSurface: paper,
      error: paper,
      onError: black,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: ink,
      canvasColor: ink,
      splashColor: Colors.transparent,
      cardColor: surface,
      dividerColor: line,
      appBarTheme: const AppBarTheme(
        backgroundColor: ink,
        foregroundColor: paper,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            color: paper, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: line)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            backgroundColor: paper,
            foregroundColor: black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            foregroundColor: paper,
            side: const BorderSide(color: line),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14))),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            foregroundColor: ghost,
            textStyle: const TextStyle(fontSize: 14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceAlt,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: line)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: line)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: paper, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: const TextStyle(color: ghost),
          hintStyle: const TextStyle(color: ghost),
          prefixIconColor: ghost,
          suffixIconColor: ghost),
      switchTheme: SwitchThemeData(
          thumbColor: const WidgetStatePropertyAll<Color>(paper),
          trackColor: const WidgetStatePropertyAll<Color>(line),
          trackOutlineColor: const WidgetStatePropertyAll<Color>(line)),
      dividerTheme: const DividerThemeData(
          color: line, thickness: 1, space: 1, indent: 20, endIndent: 20),
    );
  }

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: ink,
      onPrimary: paper,
      secondary: ink,
      onSecondary: paper,
      surface: paper,
      onSurface: ink,
      error: ink,
      onError: paper,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      canvasColor: paper,
      cardColor: paper,
      dividerColor: paperLine,
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            color: ink, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: paperLine)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            backgroundColor: ink,
            foregroundColor: paper,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            side: const BorderSide(color: paperLine),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14))),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6B6B70),
            textStyle: const TextStyle(fontSize: 14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF4F4F5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: paperLine)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: paperLine)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: ink, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: const TextStyle(color: const Color(0xFF6B6B70)),
          hintStyle: const TextStyle(color: const Color(0xFF9A9AA0)),
          prefixIconColor: const Color(0xFF6B6B70),
          suffixIconColor: const Color(0xFF6B6B70)),
      dividerTheme: const DividerThemeData(
          color: paperLine, thickness: 1, space: 1, indent: 20, endIndent: 20),
    );
  }
}
