import 'package:flutter/material.dart';

/// Dropzy brand system — dark UI with vibrant violet accents
/// (District-by-Zomato inspired feel).
class DropzyColors {
  DropzyColors._();

  static const Color primary = Color(0xFF8B5CF6); // violet
  static const Color primaryDark = Color(0xFF6D28D9);
  static const Color primaryTint = Color(0xFF241B38); // dark violet pill/avatar bg

  static const Color bg = Color(0xFF0E0C15); // near-black with a purple cast
  static const Color surface = Color(0xFF1B1826); // dark card
  static const Color surfaceAlt = Color(0xFF221E30);
  static const Color ink = Color(0xFFF4F3F7); // near-white text
  static const Color inkSoft = Color(0xFF9E99AC); // muted text
  static const Color line = Color(0xFF2C2838); // border on dark

  static const Color success = Color(0xFF34D399);
  static const Color info = Color(0xFF818CF8);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);

  static const LinearGradient offerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
  );

  /// Soft purple glow used behind headers.
  static const LinearGradient glow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2A1B4D), Color(0xFF0E0C15)],
  );
}

ThemeData buildDropzyTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final scheme = ColorScheme.fromSeed(
    seedColor: DropzyColors.primary,
    primary: DropzyColors.primary,
    surface: DropzyColors.surface,
    brightness: Brightness.dark,
  );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: DropzyColors.bg,
    primaryColor: DropzyColors.primary,
    canvasColor: DropzyColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: DropzyColors.bg,
      foregroundColor: DropzyColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: DropzyColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: DropzyColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DropzyColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      hintStyle: const TextStyle(color: DropzyColors.inkSoft),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: DropzyColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: DropzyColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: DropzyColors.primary, width: 1.6),
      ),
      labelStyle: const TextStyle(color: DropzyColors.inkSoft),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DropzyColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF2C2838),
        disabledForegroundColor: const Color(0xFF6C6780),
        elevation: 0,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: DropzyColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    dividerTheme: const DividerThemeData(color: DropzyColors.line, space: 1),
    dialogTheme: const DialogThemeData(backgroundColor: DropzyColors.surface),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: DropzyColors.surfaceAlt,
      contentTextStyle: TextStyle(color: DropzyColors.ink),
    ),
  );
}
