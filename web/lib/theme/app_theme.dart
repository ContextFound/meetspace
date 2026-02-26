import 'package:flutter/material.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark);

  void toggle() {
    value = value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDark => value == ThemeMode.dark;
}

final themeNotifier = ThemeNotifier();

const _black = Color(0xFF000000);
const _white = Color(0xFFFFFFFF);
const _offWhite = Color(0xFFE0E0E0);
const _grey = Color(0xFF757575);
const _greyLight = Color(0xFF9E9E9E);

ThemeData get meetSpaceLightTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: _black,
      onPrimary: _white,
      secondary: _black,
      onSecondary: _white,
      surface: _white,
      onSurface: _black,
      error: _black,
      onError: _white,
      outline: _grey,
    ),
    scaffoldBackgroundColor: _white,
    appBarTheme: const AppBarTheme(
      backgroundColor: _white,
      foregroundColor: _black,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: _black,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
      ),
    ),
    textTheme: _textTheme(_black),
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _grey.withValues(alpha: 0.7)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: _black, width: 1.5),
      ),
      labelStyle: const TextStyle(color: _grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _black,
        side: const BorderSide(color: _black),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _black,
        foregroundColor: _white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    dividerColor: _grey.withValues(alpha: 0.4),
    cardTheme: CardThemeData(
      color: _white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: _grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}

ThemeData get meetSpaceDarkTheme {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: _offWhite,
      onPrimary: _black,
      secondary: _offWhite,
      onSecondary: _black,
      surface: _black,
      onSurface: _offWhite,
      error: _offWhite,
      onError: _black,
      outline: _greyLight,
    ),
    scaffoldBackgroundColor: _black,
    appBarTheme: const AppBarTheme(
      backgroundColor: _black,
      foregroundColor: _offWhite,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: _offWhite,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
      ),
    ),
    textTheme: _textTheme(_offWhite),
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _greyLight.withValues(alpha: 0.7)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: _offWhite, width: 1.5),
      ),
      labelStyle: const TextStyle(color: _greyLight),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _offWhite,
        side: const BorderSide(color: _offWhite),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _offWhite,
        foregroundColor: _black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    dividerColor: _greyLight.withValues(alpha: 0.4),
    cardTheme: CardThemeData(
      color: _black,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: _greyLight.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}

TextTheme _textTheme(Color onSurface) {
  return TextTheme(
    headlineLarge: TextStyle(
      color: onSurface,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      color: onSurface,
      fontSize: 22,
      fontWeight: FontWeight.w500,
    ),
    titleLarge: TextStyle(
      color: onSurface,
      fontSize: 18,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: TextStyle(
      color: onSurface,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(color: onSurface, fontSize: 16),
    bodyMedium: TextStyle(color: onSurface, fontSize: 14),
    bodySmall: TextStyle(
      color: onSurface.withValues(alpha: 0.8),
      fontSize: 12,
    ),
    labelLarge: TextStyle(
      color: onSurface,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  );
}
