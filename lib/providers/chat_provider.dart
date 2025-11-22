import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/chat_service.dart';
import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  // Stream subscriptions
  StreamSubscription<ChatMessage>? _newMessageSubscription;
  StreamSubscription<List<ChatMessage>>? _allMessagesSubscription;
  StreamSubscription<int>? _unreadCountSubscription;
  StreamSubscription<String>? _errorSubscription;

  // State
  List<ChatMessage> _messages = [];
  int _unreadCount = 0;
  String? _lastError;
  bool _isInitialized = false;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  int get unreadCount => _unreadCount;
  String? get lastError => _lastError;
  bool get isInitialized => _isInitialized;
  String? get currentUserId => _chatService.currentUserId;

  ChatProvider() {
    _setupListeners();
  }

  void _setupListeners() {
    _newMessageSubscription = _chatService.newMessageStream.listen((message) {
      _messages = _chatService.messages;
      notifyListeners();
    });

    _allMessagesSubscription = _chatService.allMessagesStream.listen((messages) {
      _messages = messages;
      notifyListeners();
    });

    _unreadCountSubscription = _chatService.unreadCountStream.listen((count) {
      _unreadCount = count;
      notifyListeners();
    });

    _errorSubscription = _chatService.errorStream.listen((error) {
      _lastError = error;
      notifyListeners();
    });
  }

  // Initialize with socket from ConnectionProvider
  void initialize({
    required IO.Socket socket,
    required String roomId,
    required String userId,
  }) {
    _chatService.initialize(
      socket: socket,
      roomId: roomId,
      userId: userId,
    );
    _isInitialized = true;
    _messages = _chatService.messages;
    _unreadCount = _chatService.unreadCount;
    notifyListeners();
  }

  // Send message
  Future<bool> sendMessage(String message) async {
    final success = await _chatService.sendMessage(message);
    return success;
  }

  // Request chat history
  Future<void> requestChatHistory() async {
    await _chatService.requestChatHistory();
  }

  // Clear unread count
  void clearUnreadCount() {
    _chatService.clearUnreadCount();
    _unreadCount = 0;
    notifyListeners();
  }

  // Clear messages
  void clearMessages() {
    _chatService.clearMessages();
    _messages = [];
    notifyListeners();
  }

  // Reset provider
  void reset() {
    _chatService.reset();
    _messages = [];
    _unreadCount = 0;
    _isInitialized = false;
    _lastError = null;
    notifyListeners();
  }

  // Clear error
  void clearLastError() {
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _newMessageSubscription?.cancel();
    _allMessagesSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    _errorSubscription?.cancel();
    _chatService.dispose();
    super.dispose();
  }
}