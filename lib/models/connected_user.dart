import 'package:flutter/material.dart';
import 'package:herewego/models/user_location.dart';

enum LocationStatus { ready, sharing, waiting }

class ConnectedUser {
  final String socketId;
  final String name;
  final bool isCurrentUser;
  final LocationStatus locationStatus;
  final String initials;
  final Color avatarColor;
  final DateTime? joinedAt;
  final DateTime? lastSeen;
  final UserLocation? location;

  ConnectedUser({
    this.socketId = '',
    required this.name,
    this.isCurrentUser = false,
    required this.locationStatus,
    required this.initials,
    required this.avatarColor,
    this.joinedAt,
    this.lastSeen,
    this.location,
  });

  // Convert from LocationService User to ConnectedUser
  factory ConnectedUser.fromLocationServiceUser(
    dynamic user, {
    Color? avatarColor,
  }) {
    // Generate initials from name
    String initials = _generateInitials(user.name ?? 'Unknown');

    // Map location status string to enum
    LocationStatus status = _mapLocationStatus(user.locationStatus ?? 'ready');

    // Generate avatar color if not provided
    Color userAvatarColor =
        avatarColor ?? _generateAvatarColor(user.name ?? '');

    return ConnectedUser(
      socketId: user.socketId ?? '',
      name: user.name ?? 'Unknown',
      isCurrentUser: user.isCurrentUser ?? false,
      locationStatus: status,
      initials: initials,
      avatarColor: userAvatarColor,
      joinedAt: user.joinedAt,
      lastSeen: user.lastSeen,
      location: user.location,
    );
  }

  // Helper method to generate initials
  static String _generateInitials(String name) {
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return 'U';

    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    } else {
      return '${nameParts[0].substring(0, 1)}${nameParts[1].substring(0, 1)}'
          .toUpperCase();
    }
  }

  // Helper method to map string status to enum
  static LocationStatus _mapLocationStatus(String status) {
    switch (status.toLowerCase()) {
      case 'sharing':
        return LocationStatus.sharing;
      case 'waiting':
        return LocationStatus.waiting;
      case 'ready':
      default:
        return LocationStatus.ready;
    }
  }

  // Helper method to generate avatar color based on name
  static Color _generateAvatarColor(String name) {
    const List<Color> colors = [
      Color(0xFF4A90E2),
      Color(0xFFFF9500),
      Color(0xFFE74C3C),
      Color(0xFF2ECC71),
      Color(0xFF9B59B6),
      Color(0xFFF39C12),
      Color(0xFF1ABC9C),
      Color(0xFFE67E22),
    ];

    // Simple hash based on name to get consistent colors
    int hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  ConnectedUser copyWith({
    String? socketId,
    String? name,
    bool? isCurrentUser,
    LocationStatus? locationStatus,
    String? initials,
    Color? avatarColor,
    DateTime? joinedAt,
    DateTime? lastSeen,
    UserLocation? location,
  }) {
    return ConnectedUser(
      socketId: socketId ?? this.socketId,
      name: name ?? this.name,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      locationStatus: locationStatus ?? this.locationStatus,
      initials: initials ?? this.initials,
      avatarColor: avatarColor ?? this.avatarColor,
      joinedAt: joinedAt ?? this.joinedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      location: location ?? this.location,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectedUser &&
          runtimeType == other.runtimeType &&
          socketId == other.socketId;

  @override
  int get hashCode => socketId.hashCode;
}
