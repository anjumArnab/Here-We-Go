import 'package:flutter/material.dart';

class AppSnackBars {
  /// Show a generic SnackBar
  static void showSnackBar(
    BuildContext context, {
    required Widget content,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: content, duration: duration, action: action),
    );
  }

  /// Success message
  static void showSuccess(BuildContext context, String message) {
    showSnackBar(
      context,
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }

  /// Error message
  static void showError(BuildContext context, String message) {
    showSnackBar(
      context,
      content: Row(
        children: [
          const Icon(Icons.error, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      duration: const Duration(seconds: 4),
    );
  }

  /// Location received notification
  static void showLocationReceived(
    BuildContext context,
    String userId,
    double lat,
    double lng,
    VoidCallback onViewMap,
  ) {
    showSnackBar(
      context,
      content: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New location from $userId',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      action: SnackBarAction(
        label: 'View Map',
        textColor: Colors.white,
        onPressed: onViewMap,
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Location sent successfully!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Shared with $sharedCount other users',
            style: const TextStyle(fontSize: 12),
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
      content: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$userId updated their location',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 2),
    );
  }
}
