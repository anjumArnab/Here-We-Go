import 'package:flutter/material.dart';
import '../../app_theme.dart';

/// Dialog describing a friend on the map. Shows a Navigate button only when
/// [onNavigate] is provided.
class UserInfoDialog extends StatelessWidget {
  final String userId;
  final List<Widget> details;
  final VoidCallback? onNavigate;

  const UserInfoDialog({
    super.key,
    required this.userId,
    required this.details,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      title: Row(
        children: [
          Icon(Icons.person, color: AppTheme.infoBlue),
          SizedBox(width: AppTheme.spacingSmall),
          Text(
            'Friend: $userId',
            style: TextStyle(
              color: AppTheme.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: details,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppTheme.textGray),
          child: const Text('Close'),
        ),
        if (onNavigate != null)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onNavigate!();
            },
            icon: const Icon(Icons.navigation, size: 18),
            label: const Text('Navigate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.navigationBlue,
              foregroundColor: AppTheme.cardWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          ),
      ],
    );
  }
}
