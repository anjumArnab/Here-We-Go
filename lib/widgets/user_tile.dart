import 'package:flutter/material.dart';
import 'package:herewego/models/connected_user.dart';

class UserTile extends StatelessWidget {
  final ConnectedUser user;

  const UserTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: user.avatarColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (user.isCurrentUser) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(You)',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Location: ${_getLocationStatusText(user.locationStatus)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Status indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getStatusColor(user.locationStatus),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  // helper methods (moved inside class)
  String _getLocationStatusText(LocationStatus status) {
    switch (status) {
      case LocationStatus.ready:
        return 'Ready';
      case LocationStatus.sharing:
        return 'Sharing';
      case LocationStatus.waiting:
        return 'Waiting';
    }
  }

  Color _getStatusColor(LocationStatus status) {
    switch (status) {
      case LocationStatus.ready:
      case LocationStatus.sharing:
        return const Color(0xFF2ECC71);
      case LocationStatus.waiting:
        return const Color(0xFFF39C12);
    }
  }
}
