import 'package:flutter/material.dart';

class AppTheme {
  // Official Kaida Brand Colors
  static const Color primaryColor = Color(0xFF7351FF); // Kaida Purple
  static const Color accentColor = Color(0xFF00E5FF);
  
  // Legacy Constants
  static const Color secondaryColor = Color(0xFF1E1E2D);
  static const Color backgroundColor = Colors.white; 
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  
  // Onboarding Constants
  static const Color textMainMode = Color(0xFF1A1A1A);
  static const Color textDarkMode = Color(0xFFF0F0F0);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      // Natively applies the offline Lato font to the entire app
      fontFamily: 'Lato',
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Lato'),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textMainMode,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Lato'),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      // Natively applies the offline Lato font to the entire app
      fontFamily: 'Lato',
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: darkSurfaceColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Lato'),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textDarkMode,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Lato'),
        ),
      ),
    );
  }
}
