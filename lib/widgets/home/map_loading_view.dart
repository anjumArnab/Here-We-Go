import 'package:flutter/material.dart';
import '../../app_theme.dart';

/// Full-screen placeholder shown while the current location is unknown.
class MapLoadingView extends StatelessWidget {
  const MapLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.primaryGreen,
            strokeWidth: 3,
          ),
          SizedBox(height: AppTheme.spacingLarge - 4),
          Text(
            'Loading map...',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
