class Room {
  final String id;
  final String name;
  final DateTime createdAt;
  final Map<String, dynamic> settings;
  final bool isActive;

  Room({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.settings,
    this.isActive = true,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unnamed Room',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
      isActive: json['isActive'] ?? true,
    );
  }
}
