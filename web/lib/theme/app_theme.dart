import 'package:flutter/material.dart';

/// Black and white simplistic theme inspired by meetspace logotype.
ThemeData get meetSpaceTheme {
  const black = Color(0xFF000000);
  const white = Color(0xFFFFFFFF);
  const grey = Color(0xFF757575);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: black,
      onPrimary: white,
      secondary: black,
      onSecondary: white,
      surface: white,
      onSurface: black,
      error: black,
      onError: white,
      outline: grey,
    ),
    scaffoldBackgroundColor: white,
    appBarTheme: const AppBarTheme(
      backgroundColor: white,
      foregroundColor: black,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: black,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
      ),
    ),
    textTheme: _textTheme(black),
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: grey.withValues(alpha: 0.7)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: black, width: 1.5),
      ),
      labelStyle: const TextStyle(color: grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: black,
        side: const BorderSide(color: black),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: black,
        foregroundColor: white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    dividerColor: grey.withValues(alpha: 0.4),
    cardTheme: CardThemeData(
      color: white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: grey.withValues(alpha: 0.3)),
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
