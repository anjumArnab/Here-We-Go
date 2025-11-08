// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryNavy = Color(0xFF1E2A3A);
  static const Color primaryGreen = Color(0xFF00D9A3);
  static const Color accentRed = Color(0xFFFF3B5C);
  
  // Supporting Colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color cardWhite = Color(0xFFFFFFFF); 
  static const Color textDark = Color(0xFF2C3E50);
  static const Color textGray = Color(0xFF7A8A9E);
  
  // Functional Colors
  static const Color successGreen = Color(0xFF00D9A3);
  static const Color errorRed = Color(0xFFFF3B5C);
  static const Color warningOrange = Color(0xFFFF8C42);
  static const Color infoBlue = Color(0xFF4A90E2);
  
  // Grays
  static const Color gray100 = Color(0xFFF7F8FA);
  static const Color gray200 = Color(0xFFE8EAED);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray600 = Color(0xFF6B7280);
  static const Color gray700 = Color(0xFF4B5563);
  static const Color gray800 = Color(0xFF374151);
  
  // Shadow
  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );
  
  static BoxShadow lightShadow = BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 4,
    offset: const Offset(0, 2),
  );
  
  // Border Radius
  static const double radiusSmall = 6.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 20.0;
  
  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  
  // ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryGreen,
        secondary: primaryNavy,
        error: errorRed,
        surface: cardWhite,
        onPrimary: cardWhite,
        onSecondary: cardWhite,
        onError: cardWhite,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: cardWhite,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: cardWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: primaryGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      iconTheme: IconThemeData(color: textDark),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          color: textDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: textGray,
        ),
        bodySmall: TextStyle(
          fontSize: 11,
          color: textGray,
        ),
      ),
    );
  }
}