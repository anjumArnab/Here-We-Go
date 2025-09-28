import 'package:herewego/models/user_location.dart';

class User {
  final String socketId;
  final String name;
  final String locationStatus;
  final DateTime joinedAt;
  final DateTime lastSeen;
  final bool isOnline;
  final bool isCurrentUser;
  final UserLocation? location;

  User({
    required this.socketId,
    required this.name,
    required this.locationStatus,
    required this.joinedAt,
    required this.lastSeen,
    required this.isOnline,
    this.isCurrentUser = false,
    this.location,
  });

  factory User.fromJson(
    Map<String, dynamic> json, {
    bool isCurrentUser = false,
  }) {
    return User(
      socketId: json['socketId'] ?? '',
      name: json['name'] ?? 'Unknown',
      locationStatus: json['locationStatus'] ?? 'ready',
      joinedAt: DateTime.tryParse(json['joinedAt'] ?? '') ?? DateTime.now(),
      lastSeen: DateTime.tryParse(json['lastSeen'] ?? '') ?? DateTime.now(),
      isOnline: json['isOnline'] ?? true,
      isCurrentUser: isCurrentUser,
    );
  }

  User copyWith({
    String? socketId,
    String? name,
    String? locationStatus,
    DateTime? joinedAt,
    DateTime? lastSeen,
    bool? isOnline,
    bool? isCurrentUser,
    UserLocation? location,
  }) {
    return User(
      socketId: socketId ?? this.socketId,
      name: name ?? this.name,
      locationStatus: locationStatus ?? this.locationStatus,
      joinedAt: joinedAt ?? this.joinedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      location: location ?? this.location,
    );
  }
}
