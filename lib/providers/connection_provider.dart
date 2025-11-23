import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/connection_status.dart';
import '../services/connection_service.dart';

class ConnectionProvider extends ChangeNotifier {
  final ConnectionService _connectionService = ConnectionService();

  // Stream subscriptions
  StreamSubscription<ConnectionStatus>? _connectionSubscription;
  StreamSubscription<List<String>>? _roomUsersSubscription;
  StreamSubscription<String>? _errorSubscription;

  // State
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentUserId;
  String? _currentRoomId;
  List<String> _roomUsers = [];
  String? _lastError;
  String? _lastConnectionMessage;

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get currentUserId => _currentUserId;
  String? get currentRoomId => _currentRoomId;
  List<String> get roomUsers => List.unmodifiable(_roomUsers);
  String? get lastError => _lastError;
  String? get serverUrl => _connectionService.serverUrl;
  String? get connectionStatusMessage => _lastConnectionMessage;
  IO.Socket? get socket => _connectionService.socket;

  ConnectionProvider() {
    _setupListeners();
    _checkInitialState();
  }

  void _setupListeners() {
    _connectionSubscription = _connectionService.connectionStream.listen((status) {
      _isConnected = status.isConnected;
      _currentUserId = status.userId;
      _currentRoomId = status.roomId;
      _roomUsers = status.roomUsers;
      _lastConnectionMessage = status.message;
      notifyListeners();
    });

    _roomUsersSubscription = _connectionService.roomUsersStream.listen((users) {
      _roomUsers = users;
      notifyListeners();
    });

    _errorSubscription = _connectionService.errorStream.listen((error) {
      _lastError = error;
      notifyListeners();
    });
  }

  void _checkInitialState() {
    _isConnected = _connectionService.isConnected;
    _currentUserId = _connectionService.currentUserId;
    _currentRoomId = _connectionService.currentRoomId;
    _roomUsers = _connectionService.roomUsers;
  }

  Future<bool> connectToServer({
    required String serverUrl,
    required String roomId,
    required String userId,
  }) async {
    _isConnecting = true;
    _lastError = null;
    notifyListeners();

    final success = await _connectionService.connectToServer(
      serverUrl: serverUrl,
      roomId: roomId,
      userId: userId,
    );

    _isConnecting = false;
    notifyListeners();

    return success;
  }

  Future<void> leaveRoom() async {
    await _connectionService.leaveRoom();
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _connectionService.disconnect();
    notifyListeners();
  }

  void clearLastError() {
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _roomUsersSubscription?.cancel();
    _errorSubscription?.cancel();
    _connectionService.dispose();
    super.dispose();
  }
}