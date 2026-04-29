import 'package:flutter/material.dart';

class AppTheme {
  // ─── redBus-inspired Dropzy color palette ───
  static const Color primaryRed = Color(0xFFD82C2C);
  static const Color darkRed = Color(0xFFB71C1C);
  static const Color deepRed = Color(0xFF880E0E);
  static const Color lightRed = Color(0xFFFEF2F2);
  static const Color accentOrange = Color(0xFFE8732A);
  static const Color green = Color(0xFF34C759);
  static const Color blue = Color(0xFF2196F3);
  static const Color amber = Color(0xFFFF9500);

  static const Color _surfaceColor = Color(0xFFF5F5F5);
  static const Color _errorColor = Color(0xFFD32F2F);
  static const double _borderRadius = 14.0;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme.light(
      primary: primaryRed,
      onPrimary: Colors.white,
      secondary: darkRed,
      onSecondary: Colors.white,
      surface: _surfaceColor,
      onSurface: Color(0xFF1F1F1F),
      error: _errorColor,
      onError: Colors.white,
      outline: Color(0xFFE0E0E0),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8F8F8),
    textTheme: _buildTextTheme(),
    inputDecorationTheme: _buildInputDecorationTheme(),
    elevatedButtonTheme: _buildElevatedButtonTheme(),
    cardTheme: _buildCardTheme(),
    appBarTheme: _buildAppBarTheme(),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: primaryRed,
      unselectedItemColor: Color(0xFF9E9E9E),
      backgroundColor: Colors.white,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryRed,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: lightRed,
      selectedColor: primaryRed,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFEEEEEE),
      thickness: 1,
    ),
  );

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1F1F1F)),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F1F1F)),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F1F1F)),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1F1F1F)),
      titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF757575)),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Color(0xFF1F1F1F)),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Color(0xFF424242)),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF757575)),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryRed),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: primaryRed),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF9E9E9E)),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: primaryRed, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: _errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: _errorColor, width: 2),
      ),
      hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
      labelStyle: const TextStyle(color: Color(0xFF757575), fontSize: 14, fontWeight: FontWeight.w500),
      errorStyle: const TextStyle(color: _errorColor, fontSize: 12),
      prefixIconColor: const Color(0xFF9E9E9E),
      suffixIconColor: const Color(0xFF9E9E9E),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        elevation: 2,
        shadowColor: primaryRed.withAlpha(80),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withAlpha(15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      margin: const EdgeInsets.all(0),
    );
  }

  static AppBarTheme _buildAppBarTheme() {
    return const AppBarTheme(
      backgroundColor: primaryRed,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
    );
  }

  // ─── Gradient helpers ───
  static const LinearGradient redGradient = LinearGradient(
    colors: [primaryRed, darkRed, deepRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redGradientLight = LinearGradient(
    colors: [primaryRed, darkRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Status color helpers ───
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return amber;
      case 'picked up':
      case 'accepted':
        return blue;
      case 'in transit':
      case 'in_transit':
        return const Color(0xFF0F9D58);
      case 'out for delivery':
        return green;
      case 'delivered':
        return const Color(0xFF188038);
      case 'cancelled':
        return _errorColor;
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
