// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:herewego/app_theme.dart';

class AppSnackBar {
  /// Show a generic SnackBar with theme styling
  static void showSnackBar(
    BuildContext context, {
    required Widget content,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        duration: duration,
        action: action,
        backgroundColor: backgroundColor ?? AppTheme.primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        margin: const EdgeInsets.all(AppTheme.spacingMedium),
        elevation: 4,
      ),
    );
  }

  /// Success message
  static void showSuccess(BuildContext context, String message) {
    showSnackBar(
      context,
      backgroundColor: AppTheme.successGreen,
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Error message
  static void showError(BuildContext context, String message) {
    showSnackBar(
      context,
      backgroundColor: AppTheme.errorRed,
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      duration: const Duration(seconds: 4),
    );
  }

  /// Info message
  static void showInfo(BuildContext context, String message) {
    showSnackBar(
      context,
      backgroundColor: AppTheme.infoBlue,
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Warning message
  static void showWarning(BuildContext context, String message) {
    showSnackBar(
      context,
      backgroundColor: AppTheme.warningOrange,
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Location sent success
  static void showLocationSent(
    BuildContext context,
    double lat,
    double lng,
    int sharedCount,
  ) {
    showSnackBar(
      context,
      backgroundColor: AppTheme.successGreen,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location sent successfully!',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXSmall),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Text(
                'Shared with $sharedCount other user${sharedCount == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
      duration: const Duration(seconds: 4),
    );
  }

  /// Location update notification
  static void showLocationUpdate(BuildContext context, String userId) {
    showSnackBar(
      context,
      backgroundColor: AppTheme.infoBlue,
      content: Text(
        '$userId updated their location',
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      duration: const Duration(seconds: 2),
    );
  }
}
