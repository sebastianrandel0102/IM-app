import 'package:flutter/material.dart';

abstract final class Palette {
  static const cream = Color(0xFFF7EEE7),
      paper = Color(0xFFFFFDFC),
      lavender = Color(0xFFE4D1EA);
  static const pink = Color(0xFFF4AFBF),
      blush = Color(0xFFF8CBD7),
      caramel = Color(0xFFD2A06B);
  static const ink = Color(0xFF49342F),
      muted = Color(0xFF826F69),
      outline = Color(0xFF352320);
  static const sage = Color(0xFFB5D3B5), rose = Color(0xFFA94E67);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    scaffoldBackgroundColor: Palette.cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Palette.rose,
      surface: Palette.paper,
      primary: Palette.ink,
      secondary: Palette.rose,
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: Palette.ink,
      displayColor: Palette.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.cream,
      foregroundColor: Palette.ink,
      elevation: 0,
      centerTitle: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 56),
        backgroundColor: Palette.ink,
        foregroundColor: Palette.paper,
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 54),
        foregroundColor: Palette.ink,
        side: const BorderSide(color: Color(0xFFD8C8BE)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.paper,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE6DAD1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE6DAD1)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Palette.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE9DDD3),
      thickness: 1,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Palette.paper,
      indicatorColor: Palette.blush,
      height: 78,
    ),
  );
}
