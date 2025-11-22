import 'dart:async';
import 'dart:developer' as developer;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/connection_status.dart';

class ConnectionService {
  // Singleton instance
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  // Socket.io client
  IO.Socket? _socket;

  // Connection state
  bool _isConnected = false;
  String? _serverUrl;
  String? _currentRoomId;
  String? _currentUserId;
  List<String> _roomUsers = [];

  // Stream controllers
  final StreamController<ConnectionStatus> _connectionController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<List<String>> _roomUsersController =
      StreamController<List<String>>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // Getters for streams
  Stream<ConnectionStatus> get connectionStream => _connectionController.stream;
  Stream<List<String>> get roomUsersStream => _roomUsersController.stream;
  Stream<String> get errorStream => _errorController.stream;

  // Getters for state
  bool get isConnected => _isConnected;
  String? get serverUrl => _serverUrl;
  String? get currentRoomId => _currentRoomId;
  String? get currentUserId => _currentUserId;
  List<String> get roomUsers => List.unmodifiable(_roomUsers);
  IO.Socket? get socket => _socket;

  // Connect to server and join room
  Future<bool> connectToServer({
    required String serverUrl,
    required String roomId,
    required String userId,
  }) async {
    try {
      developer.log('Attempting to connect to server: $serverUrl');

      // Clean up existing connection
      await disconnect();

      _serverUrl = serverUrl;
      _currentRoomId = roomId;
      _currentUserId = userId;

      // Configure socket options
      _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .setTimeout(10000)
            .build(),
      );

      // Set up event listeners
      _setupConnectionListeners();

      // Wait for connection
      final Completer<bool> connectionCompleter = Completer<bool>();
      Timer connectionTimeout = Timer(Duration(seconds: 15), () {
        if (!connectionCompleter.isCompleted) {
          connectionCompleter.complete(false);
        }
      });

      _socket!.onConnect((_) {
        developer.log('Connected to server, joining room...');
        _socket!.emit('join-room', {'roomId': roomId, 'userId': userId});
      });

      _socket!.on('joined-room', (data) {
        connectionTimeout.cancel();
        if (!connectionCompleter.isCompleted) {
          developer.log('Successfully joined room: ${data['roomId']}');
          _handleRoomJoined(data);
          connectionCompleter.complete(true);
        }
      });

      _socket!.onConnectError((error) {
        developer.log('Connection error: $error');
        connectionTimeout.cancel();
        if (!connectionCompleter.isCompleted) {
          _handleConnectionError('Connection failed: $error');
          connectionCompleter.complete(false);
        }
      });

      _socket!.connect();
      return await connectionCompleter.future;
    } catch (e) {
      developer.log('Connection exception: $e');
      _handleConnectionError('Connection failed: $e');
      return false;
    }
  }

  // Set up connection-related event listeners
  void _setupConnectionListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      developer.log('Socket connected');
    });

    _socket!.onDisconnect((reason) {
      developer.log('Socket disconnected: $reason');
      _isConnected = false;
      _connectionController.add(
        ConnectionStatus(isConnected: false, message: 'Disconnected: $reason'),
      );
    });

    _socket!.on('user-joined', (data) {
      developer.log('User joined: ${data['userId']}');
      _handleUserJoined(data);
    });

    _socket!.on('user-left', (data) {
      developer.log('User left: ${data['userId']}');
      _handleUserLeft(data);
    });

    _socket!.on('error', (data) {
      developer.log('Server error: ${data['message']}');
      _errorController.add(data['message'] ?? 'Unknown server error');
    });
  }

  // Handle successful room join
  void _handleRoomJoined(Map<String, dynamic> data) {
    _isConnected = true;
    _currentRoomId = data['roomId'];
    _currentUserId = data['userId'];
    _roomUsers = List<String>.from(data['usersInRoom'] ?? []);

    _connectionController.add(
      ConnectionStatus(
        isConnected: true,
        roomId: _currentRoomId,
        userId: _currentUserId,
        message: data['message'],
        roomUsers: _roomUsers,
      ),
    );

    _roomUsersController.add(_roomUsers);
  }

  // Handle user joined event
  void _handleUserJoined(Map<String, dynamic> data) {
    _roomUsers = List<String>.from(data['usersInRoom'] ?? []);
    _roomUsersController.add(_roomUsers);

    _connectionController.add(
      ConnectionStatus(
        isConnected: true,
        roomId: _currentRoomId,
        userId: _currentUserId,
        message: data['message'],
        roomUsers: _roomUsers,
      ),
    );
  }

  // Handle user left event
  void _handleUserLeft(Map<String, dynamic> data) {
    _roomUsers = List<String>.from(data['usersInRoom'] ?? []);
    _roomUsersController.add(_roomUsers);

    _connectionController.add(
      ConnectionStatus(
        isConnected: true,
        roomId: _currentRoomId,
        userId: _currentUserId,
        message: data['message'],
        roomUsers: _roomUsers,
      ),
    );
  }

  // Handle connection errors
  void _handleConnectionError(String error) {
    _isConnected = false;
    _connectionController.add(
      ConnectionStatus(isConnected: false, message: error),
    );
    _errorController.add(error);
  }

  // Leave current room
  Future<void> leaveRoom() async {
    if (_socket != null && _isConnected) {
      developer.log('Leaving room');
      _socket!.emit('leave-room');
    }

    _isConnected = false;
    _currentRoomId = null;
    _currentUserId = null;
    _roomUsers.clear();

    _connectionController.add(
      ConnectionStatus(isConnected: false, message: 'Left room'),
    );
  }

  // Disconnect from server
  Future<void> disconnect() async {
    if (_socket != null) {
      developer.log('Disconnecting from server');

      await leaveRoom();

      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    _serverUrl = null;
    _isConnected = false;
  }

  // Check server health
  Future<bool> checkServerHealth() async {
    if (_serverUrl == null) return false;
    return _isConnected;
  }

  // Dispose all resources
  Future<void> dispose() async {
    developer.log('Disposing ConnectionService');

    await disconnect();

    await _connectionController.close();
    await _roomUsersController.close();
    await _errorController.close();
  }
}
