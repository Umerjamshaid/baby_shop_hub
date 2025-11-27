import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Define the professional color palette
  static const Color _primaryColor = Color(0xFF4DB6AC); // Soft Teal
  static const Color _secondaryColor = Color(0xFFFFA07A); // Warm Coral
  static const Color _accentColor = Color(0xFFFFD180); // Soft Gold
  static const Color _backgroundColor = Color(0xFFF5F5F5); // Light Gray
  static const Color _textColor = Color(0xFF333333); // Dark Gray
  static const Color _whiteColor = Colors.white;

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: _backgroundColor,
    cardColor: _whiteColor,
    dividerColor: Colors.grey[300],
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      secondary: _secondaryColor,
      tertiary: _accentColor,
      surface: _whiteColor,
      onPrimary: _whiteColor,
      onSecondary: _textColor,
    ),
    textTheme: _buildTextTheme(_textColor),
    appBarTheme: _buildAppBarTheme(_whiteColor, _textColor),
    elevatedButtonTheme: _buildElevatedButtonTheme(_primaryColor, _whiteColor),
    cardTheme: _buildCardTheme(),
    inputDecorationTheme: _buildInputDecorationTheme(),
    floatingActionButtonTheme: _buildFloatingActionButtonTheme(_primaryColor, _whiteColor),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    dividerColor: Colors.grey[800],
    colorScheme: const ColorScheme.dark(
      primary: _primaryColor,
      secondary: _secondaryColor,
      tertiary: _accentColor,
      surface: Color(0xFF1E1E1E),
      onPrimary: _textColor,
      onSecondary: _whiteColor,
    ),
    textTheme: _buildTextTheme(_whiteColor),
    appBarTheme: _buildAppBarTheme(const Color(0xFF1E1E1E), _whiteColor),
    elevatedButtonTheme: _buildElevatedButtonTheme(_primaryColor, _textColor),
    cardTheme: _buildCardTheme(),
    inputDecorationTheme: _buildInputDecorationTheme(isDark: true),
    floatingActionButtonTheme: _buildFloatingActionButtonTheme(_primaryColor, _textColor),
  );

  // Helper methods to build theme components

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: GoogleFonts.lato(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
      displayMedium: GoogleFonts.lato(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
      displaySmall: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
      headlineMedium: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
      headlineSmall: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
      titleLarge: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
      bodyLarge: GoogleFonts.openSans(fontSize: 16, color: textColor),
      bodyMedium: GoogleFonts.openSans(fontSize: 14, color: textColor),
    );
  }

  static AppBarTheme _buildAppBarTheme(Color backgroundColor, Color textColor) {
    return AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: 0,
      iconTheme: IconThemeData(color: textColor),
      titleTextStyle: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
      centerTitle: true,
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(Color primaryColor, Color onPrimaryColor) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        textStyle: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 5,
        shadowColor: primaryColor.withOpacity(0.4),
      ),
    );
  }

  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme({bool isDark = false}) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      labelStyle: GoogleFonts.lato(color: isDark ? Colors.white70 : _textColor, fontSize: 14),
      hintStyle: GoogleFonts.lato(color: isDark ? Colors.white54 : Colors.grey, fontSize: 14),
    );
  }

  static FloatingActionButtonThemeData _buildFloatingActionButtonTheme(Color backgroundColor, Color foregroundColor) {
    return FloatingActionButtonThemeData(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    );
  }
}
