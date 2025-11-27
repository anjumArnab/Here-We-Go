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

  // Navigation Colors
  static const Color navigationBlue = Color(0xFF2196F3);
  static const Color navigationActiveGreen = Color(0xFF4CAF50);
  static const Color reroutingOrange = Color(0xFFFF9800);
  static const Color arrivedGreen = Color(0xFF66BB6A);

  // Grays
  static const Color gray100 = Color(0xFFF7F8FA);
  static const Color gray200 = Color(0xFFE8EAED);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray600 = Color(0xFF6B7280);
  static const Color gray700 = Color(0xFF4B5563);

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
  static const double radiusXSmall = 4.0;
  static const double radiusSmall = 6.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;

  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;

  // Position
  static const double position = 16.0;
}
