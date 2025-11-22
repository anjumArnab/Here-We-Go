import 'dart:async';
import 'dart:developer' as developer;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/chat_message.dart';

class ChatService {
  // Singleton instance
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // Socket reference
  IO.Socket? _socket;

  // Chat state
  String? _currentRoomId;
  String? _currentUserId;
  final List<ChatMessage> _messages = [];
  int _unreadCount = 0;

  // Stream controllers
  final StreamController<ChatMessage> _newMessageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<List<ChatMessage>> _allMessagesController =
      StreamController<List<ChatMessage>>.broadcast();
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // Getters for streams
  Stream<ChatMessage> get newMessageStream => _newMessageController.stream;
  Stream<List<ChatMessage>> get allMessagesStream =>
      _allMessagesController.stream;
  Stream<int> get unreadCountStream => _unreadCountController.stream;
  Stream<String> get errorStream => _errorController.stream;

  // Getters for state
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String? get currentRoomId => _currentRoomId;
  String? get currentUserId => _currentUserId;
  int get unreadCount => _unreadCount;

  // Initialize with socket
  void initialize({
    required IO.Socket socket,
    required String roomId,
    required String userId,
  }) {
    _socket = socket;
    _currentRoomId = roomId;
    _currentUserId = userId;
    _messages.clear();
    _unreadCount = 0;
    _setupChatListeners();
    developer.log('ChatService initialized for room: $roomId, user: $userId');
  }

  // Set up chat event listeners
  void _setupChatListeners() {
    if (_socket == null) return;

    _socket!.on('new-message', (data) {
      developer.log('New message received: $data');
      _handleNewMessage(data);
    });

    _socket!.on('chat-history', (data) {
      developer.log('Chat history received');
      _handleChatHistory(data);
    });
  }

  // Handle incoming new message
  void _handleNewMessage(Map<String, dynamic> data) {
    final message = ChatMessage.fromJson(data);
    _messages.add(message);
    _newMessageController.add(message);
    _allMessagesController.add(List.from(_messages));

    // Increment unread count for messages from others
    if (message.userId != _currentUserId) {
      _unreadCount++;
      _unreadCountController.add(_unreadCount);
    }
  }

  // Handle chat history
  void _handleChatHistory(Map<String, dynamic> data) {
    final List<dynamic> messageList = data['messages'] ?? [];
    _messages.clear();
    for (var msgData in messageList) {
      final message = ChatMessage.fromJson(Map<String, dynamic>.from(msgData));
      _messages.add(message);
    }
    _allMessagesController.add(List.from(_messages));
  }

  // Send a message
  Future<bool> sendMessage(String message) async {
    if (_socket == null) {
      _errorController.add('Not connected to server');
      return false;
    }

    if (_currentRoomId == null || _currentUserId == null) {
      _errorController.add('Room or user ID not set');
      return false;
    }

    if (message.trim().isEmpty) {
      _errorController.add('Message cannot be empty');
      return false;
    }

    try {
      developer.log('Sending message: $message');
      _socket!.emit('send-message', {
        'roomId': _currentRoomId,
        'userId': _currentUserId,
        'message': message.trim(),
      });
      return true;
    } catch (e) {
      developer.log('Error sending message: $e');
      _errorController.add('Failed to send message: $e');
      return false;
    }
  }

  // Request chat history
  Future<void> requestChatHistory() async {
    if (_socket == null || _currentRoomId == null) {
      _errorController.add('Not connected to server or room');
      return;
    }

    try {
      developer.log('Requesting chat history');
      _socket!.emit('get-chat-history', {'roomId': _currentRoomId});
    } catch (e) {
      developer.log('Error requesting chat history: $e');
      _errorController.add('Failed to get chat history: $e');
    }
  }

  // Clear unread count
  void clearUnreadCount() {
    _unreadCount = 0;
    _unreadCountController.add(_unreadCount);
  }

  // Clear messages
  void clearMessages() {
    _messages.clear();
    _allMessagesController.add([]);
  }

  // Reset service
  void reset() {
    _messages.clear();
    _unreadCount = 0;
    _currentRoomId = null;
    _currentUserId = null;
    _socket = null;
  }

  // Dispose resources
  Future<void> dispose() async {
    developer.log('Disposing ChatService');
    reset();
    await _newMessageController.close();
    await _allMessagesController.close();
    await _unreadCountController.close();
    await _errorController.close();
  }
}
