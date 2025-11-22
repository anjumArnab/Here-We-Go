class ChatMessage {
  final String messageId;
  final String userId;
  final String message;
  final String timestamp;

  ChatMessage({
    required this.messageId,
    required this.userId,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId'] ?? '',
      userId: json['userId'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'userId': userId,
      'message': message,
      'timestamp': timestamp,
    };
  }

  @override
  String toString() {
    return 'ChatMessage(id: $messageId, user: $userId, message: $message)';
  }
}