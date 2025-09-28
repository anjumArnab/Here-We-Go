import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/user_location.dart';
import '../models/room.dart';
import '../models/user.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

enum LocationSharingStatus { stopped, starting, sharing, stopping }

class LocationService extends ChangeNotifier {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Socket.IO
  IO.Socket? _socket;

  // State variables
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  LocationSharingStatus _locationSharingStatus = LocationSharingStatus.stopped;
  String? _serverUrl;
  String? _currentRoomId;
  String? _currentUserName;
  Room? _currentRoom;
  List<User> _users = [];
  final Map<String, UserLocation> _userLocations = {};

  // Location tracking
  StreamSubscription<Position>? _locationSubscription;
  UserLocation? _currentLocation;
  Timer? _heartbeatTimer;
  Timer? _locationUpdateTimer;

  // Error handling
  String? _lastError;

  // Getters
  ConnectionStatus get connectionStatus => _connectionStatus;
  LocationSharingStatus get locationSharingStatus => _locationSharingStatus;
  String? get serverUrl => _serverUrl;
  String? get currentRoomId => _currentRoomId;
  String? get currentUserName => _currentUserName;
  Room? get currentRoom => _currentRoom;
  List<User> get users => List.unmodifiable(_users);
  Map<String, UserLocation> get userLocations =>
      Map.unmodifiable(_userLocations);
  UserLocation? get currentLocation => _currentLocation;
  String? get lastError => _lastError;
  bool get isConnected => _connectionStatus == ConnectionStatus.connected;
  bool get isSharing => _locationSharingStatus == LocationSharingStatus.sharing;

  // Public Methods

  /// Initialize connection to server
  Future<bool> connect(String serverUrl) async {
    try {
      _setConnectionStatus(ConnectionStatus.connecting);
      _clearError();

      _serverUrl = serverUrl.trim();
      if (!_serverUrl!.startsWith('http')) {
        _serverUrl = 'https://$_serverUrl';
      }

      // Disconnect existing socket
      await disconnect();

      // Create new socket connection
      _socket = IO.io(
        _serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(3)
            .setReconnectionDelay(1000)
            .setTimeout(5000)
            .build(),
      );

      // Set up event listeners
      _setupSocketListeners();

      // Wait for connection
      await _waitForConnection();

      return _connectionStatus == ConnectionStatus.connected;
    } catch (e) {
      _setError('Failed to connect: ${e.toString()}');
      _setConnectionStatus(ConnectionStatus.error);
      return false;
    }
  }

  /// Create a new room
  Future<bool> createRoom({
    required String roomName,
    required String creatorName,
    String? customRoomId,
    Map<String, dynamic>? settings,
  }) async {
    if (!isConnected) {
      _setError('Not connected to server');
      return false;
    }

    try {
      _clearError();

      final completer = Completer<bool>();

      _socket!.emitWithAck(
        'create_room',
        {
          if (customRoomId != null) 'roomId': customRoomId,
          'roomName': roomName,
          'creatorName': creatorName,
          'settings': settings ?? {},
        },
        ack: (data) {
          if (data['success'] == true) {
            _currentRoom = Room.fromJson(data['room']);
            _currentRoomId = _currentRoom!.id;
            _currentUserName = creatorName;
            completer.complete(true);
          } else {
            _setError(data['message'] ?? 'Failed to create room');
            completer.complete(false);
          }
        },
      );

      return await completer.future;
    } catch (e) {
      _setError('Error creating room: ${e.toString()}');
      return false;
    }
  }

  /// Join an existing room
  Future<bool> joinRoom({
    required String roomId,
    required String userName,
  }) async {
    if (!isConnected) {
      _setError('Not connected to server');
      return false;
    }

    try {
      _clearError();

      final completer = Completer<bool>();

      _socket!.emitWithAck(
        'join_room',
        {'roomId': roomId, 'name': userName},
        ack: (data) {
          if (data['success'] == true) {
            _currentRoom = Room.fromJson(data['room']);
            _currentRoomId = roomId;
            _currentUserName = userName;
            _updateUsers(data['users'] ?? []);
            completer.complete(true);
          } else {
            _setError(data['message'] ?? 'Failed to join room');
            completer.complete(false);
          }
        },
      );

      return await completer.future;
    } catch (e) {
      _setError('Error joining room: ${e.toString()}');
      return false;
    }
  }

  /// Start sharing location
  Future<bool> startLocationSharing({
    bool highAccuracy = true,
    int updateInterval = 5000, // milliseconds
  }) async {
    if (!isConnected || _currentRoomId == null) {
      _setError('Not connected to a room');
      return false;
    }

    try {
      _setLocationSharingStatus(LocationSharingStatus.starting);
      _clearError();

      // Check and request location permissions
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        _setError('Location permission denied');
        _setLocationSharingStatus(LocationSharingStatus.stopped);
        return false;
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('Location services are disabled');
        _setLocationSharingStatus(LocationSharingStatus.stopped);
        return false;
      }

      // Configure location settings
      late LocationSettings locationSettings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy:
              highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
          distanceFilter: 5,
          intervalDuration: Duration(milliseconds: updateInterval),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText:
                "HereWeGo is sharing your location with your group",
            notificationTitle: "Location Sharing Active",
            enableWakeLock: true,
          ),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        locationSettings = AppleSettings(
          accuracy:
              highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
          distanceFilter: 5,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
        );
      } else {
        locationSettings = LocationSettings(
          accuracy:
              highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
          distanceFilter: 5,
        );
      }

      // Start listening to location updates
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _handleLocationUpdate(position);
        },
        onError: (error) {
          _setError('Location tracking error: ${error.toString()}');
          _setLocationSharingStatus(LocationSharingStatus.stopped);
        },
      );

      _setLocationSharingStatus(LocationSharingStatus.sharing);
      return true;
    } catch (e) {
      _setError('Failed to start location sharing: ${e.toString()}');
      _setLocationSharingStatus(LocationSharingStatus.stopped);
      return false;
    }
  }

  /// Stop sharing location
  Future<void> stopLocationSharing() async {
    try {
      _setLocationSharingStatus(LocationSharingStatus.stopping);

      // Cancel location subscription
      await _locationSubscription?.cancel();
      _locationSubscription = null;

      // Notify server
      if (isConnected && _currentRoomId != null) {
        _socket!.emit('stop_sharing_location', {'roomId': _currentRoomId});
      }

      _setLocationSharingStatus(LocationSharingStatus.stopped);
    } catch (e) {
      _setError('Error stopping location sharing: ${e.toString()}');
      _setLocationSharingStatus(LocationSharingStatus.stopped);
    }
  }

  /// Get current room users
  Future<void> refreshRoomUsers() async {
    if (!isConnected || _currentRoomId == null) return;

    try {
      _socket!.emitWithAck(
        'get_room_users',
        {'roomId': _currentRoomId},
        ack: (data) {
          if (data['success'] == true) {
            _updateUsers(data['users'] ?? []);
            _updateLocations(data['locations'] ?? []);
          }
        },
      );
    } catch (e) {
      _setError('Error refreshing users: ${e.toString()}');
    }
  }

  /// Leave current room
  Future<void> leaveRoom() async {
    try {
      // Stop location sharing first
      await stopLocationSharing();

      // Notify server
      if (isConnected && _currentRoomId != null) {
        _socket!.emit('leave_room', {'roomId': _currentRoomId});
      }

      // Clear room data
      _currentRoom = null;
      _currentRoomId = null;
      _currentUserName = null;
      _users.clear();
      _userLocations.clear();
      _currentLocation = null;

      notifyListeners();
    } catch (e) {
      _setError('Error leaving room: ${e.toString()}');
    }
  }

  /// Disconnect from server
  Future<void> disconnect() async {
    try {
      // Stop location sharing
      await stopLocationSharing();

      // Cancel timers
      _heartbeatTimer?.cancel();
      _locationUpdateTimer?.cancel();

      // Disconnect socket
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;

      // Reset state
      _setConnectionStatus(ConnectionStatus.disconnected);
      _currentRoom = null;
      _currentRoomId = null;
      _currentUserName = null;
      _users.clear();
      _userLocations.clear();
      _currentLocation = null;
      _serverUrl = null;

      notifyListeners();
    } catch (e) {
      debugPrint('Error during disconnect: ${e.toString()}');
    }
  }

  // Private Methods

  void _setupSocketListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      debugPrint('Socket connected');
      _setConnectionStatus(ConnectionStatus.connected);
      _startHeartbeat();
    });

    _socket!.onDisconnect((_) {
      debugPrint('Socket disconnected');
      _setConnectionStatus(ConnectionStatus.disconnected);
      _heartbeatTimer?.cancel();
    });

    _socket!.onConnectError((error) {
      debugPrint('Socket connection error: $error');
      _setError('Connection error: ${error.toString()}');
      _setConnectionStatus(ConnectionStatus.error);
    });

    _socket!.on('room_updated', (data) {
      _updateUsers(data['users'] ?? []);
      if (data['roomInfo'] != null) {
        _currentRoom = Room.fromJson(data['roomInfo']);
      }
      notifyListeners();
    });

    _socket!.on('user_joined', (data) {
      if (data['users'] != null) {
        _updateUsers(data['users']);
      }
      notifyListeners();
    });

    _socket!.on('user_left', (data) {
      final socketId = data['socketId'];
      if (socketId != null) {
        _users.removeWhere((user) => user.socketId == socketId);
        _userLocations.remove(socketId);
      }
      if (data['users'] != null) {
        _updateUsers(data['users']);
      }
      notifyListeners();
    });

    _socket!.on('location_update', (data) {
      final socketId = data['socketId'];
      final locationData = data['location'];

      if (socketId != null && locationData != null) {
        final location = UserLocation.fromJson(locationData);
        _userLocations[socketId] = location;

        // Update user status
        final userIndex = _users.indexWhere((u) => u.socketId == socketId);
        if (userIndex != -1) {
          _users[userIndex] = _users[userIndex].copyWith(
            locationStatus: 'sharing',
            location: location,
          );
        }
        notifyListeners();
      }
    });

    _socket!.on('user_stopped_sharing', (data) {
      final socketId = data['socketId'];
      if (socketId != null) {
        _userLocations.remove(socketId);

        // Update user status
        final userIndex = _users.indexWhere((u) => u.socketId == socketId);
        if (userIndex != -1) {
          _users[userIndex] = _users[userIndex].copyWith(
            locationStatus: 'ready',
            location: null,
          );
        }
        notifyListeners();
      }
    });

    _socket!.on('room_expired', (data) {
      _setError('Room has expired: ${data['message'] ?? 'Unknown reason'}');
      leaveRoom();
    });

    _socket!.on('error', (data) {
      _setError('Server error: ${data['message'] ?? 'Unknown error'}');
    });
  }

  Future<void> _waitForConnection() async {
    final completer = Completer<void>();
    late Timer timeoutTimer;

    void checkConnection() {
      if (_connectionStatus == ConnectionStatus.connected) {
        timeoutTimer.cancel();
        completer.complete();
      } else if (_connectionStatus == ConnectionStatus.error) {
        timeoutTimer.cancel();
        completer.complete();
      }
    }

    // Check every 100ms for connection status
    timeoutTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
      checkConnection();
    });

    // Timeout after 10 seconds
    Timer(Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        timeoutTimer.cancel();
        _setError('Connection timeout');
        _setConnectionStatus(ConnectionStatus.error);
        completer.complete();
      }
    });

    return completer.future;
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (isConnected) {
        _socket!.emit('ping', (response) {
          // Heartbeat successful
        });
      }
    });
  }

  Future<bool> _checkLocationPermission() async {
    PermissionStatus permission = await Permission.location.status;

    if (permission.isDenied) {
      permission = await Permission.location.request();
    }

    if (permission.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return permission.isGranted;
  }

  void _handleLocationUpdate(Position position) {
    if (!isConnected || _currentRoomId == null) return;

    _currentLocation = UserLocation.fromPosition(position);

    // Send location to server
    _socket!.emit('share_location', {
      'roomId': _currentRoomId,
      'location': _currentLocation!.toJson(),
    });

    notifyListeners();
  }

  void _updateUsers(List<dynamic> usersData) {
    _users =
        usersData.map((userData) {
          final isCurrentUser = userData['name'] == _currentUserName;
          return User.fromJson(userData, isCurrentUser: isCurrentUser);
        }).toList();

    notifyListeners();
  }

  void _updateLocations(List<dynamic> locationsData) {
    _userLocations.clear();
    for (final locationData in locationsData) {
      final socketId = locationData['socketId'];
      final location = locationData['location'];
      if (socketId != null && location != null) {
        _userLocations[socketId] = UserLocation.fromJson(location);
      }
    }
    notifyListeners();
  }

  void _setConnectionStatus(ConnectionStatus status) {
    _connectionStatus = status;
    notifyListeners();
  }

  void _setLocationSharingStatus(LocationSharingStatus status) {
    _locationSharingStatus = status;
    notifyListeners();
  }

  void _setError(String error) {
    _lastError = error;
    debugPrint('LocationService Error: $error');
    notifyListeners();
  }

  void _clearError() {
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
