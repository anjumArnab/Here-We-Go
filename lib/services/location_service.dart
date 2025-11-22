import 'dart:async';
import 'dart:developer' as developer;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/user_location.dart';

class LocationService {
  // Singleton instance
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Socket reference
  IO.Socket? _socket;

  // Location state
  String? _currentRoomId;
  String? _currentUserId;
  final Map<String, UserLocation> _userLocations = {};

  // Stream controllers
  final StreamController<UserLocation> _locationUpdateController =
      StreamController<UserLocation>.broadcast();
  final StreamController<Map<String, UserLocation>> _allLocationsController =
      StreamController<Map<String, UserLocation>>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // Getters for streams
  Stream<UserLocation> get locationUpdateStream =>
      _locationUpdateController.stream;
  Stream<Map<String, UserLocation>> get allLocationsStream =>
      _allLocationsController.stream;
  Stream<String> get errorStream => _errorController.stream;

  // Getters for state
  String? get currentRoomId => _currentRoomId;
  String? get currentUserId => _currentUserId;
  Map<String, UserLocation> get userLocations =>
      Map.unmodifiable(_userLocations);

  // Initialize with socket
  void initialize({
    required IO.Socket socket,
    required String roomId,
    required String userId,
  }) {
    _socket = socket;
    _currentRoomId = roomId;
    _currentUserId = userId;
    _userLocations.clear();
    _setupLocationListeners();
    developer.log(
      'LocationService initialized for room: $roomId, user: $userId',
    );
  }

  // Set up location related event listeners
  void _setupLocationListeners() {
    if (_socket == null) return;

    _socket!.on('location-update', (data) {
      developer.log('Location update received: ${data['userId']}');
      _handleLocationUpdate(data);
    });

    _socket!.on('existing-locations', (data) {
      developer.log('Existing locations received');
      _handleExistingLocations(data);
    });

    _socket!.on('all-locations', (data) {
      developer.log('All locations received');
      _handleAllLocations(data);
    });

    _socket!.on('location-shared', (data) {
      developer.log('Location shared successfully');
    });

    _socket!.on('user-left', (data) {
      developer.log('User left, removing location: ${data['userId']}');
      _handleUserLeft(data);
    });
  }

  // Handle location update from another user
  void _handleLocationUpdate(Map<String, dynamic> data) {
    final location = UserLocation.fromJson(data);
    _userLocations[location.userId] = location;
    _locationUpdateController.add(location);
    _allLocationsController.add(Map.from(_userLocations));
  }

  // Handle existing locations when joining room
  void _handleExistingLocations(Map<String, dynamic> data) {
    data.forEach((userId, locationData) {
      final location = UserLocation.fromJson({
        'userId': userId,
        ...locationData,
      });
      _userLocations[userId] = location;
    });
    _allLocationsController.add(Map.from(_userLocations));
  }

  // Handle all locations response
  void _handleAllLocations(Map<String, dynamic> data) {
    _userLocations.clear();
    data.forEach((userId, locationData) {
      final location = UserLocation.fromJson({
        'userId': userId,
        ...locationData,
      });
      _userLocations[userId] = location;
    });
    _allLocationsController.add(Map.from(_userLocations));
  }

  // Handle user left event
  void _handleUserLeft(Map<String, dynamic> data) {
    String userId = data['userId'];
    _userLocations.remove(userId);
    _allLocationsController.add(Map.from(_userLocations));
  }

  // Share current location with room
  Future<bool> shareLocation({
    required double latitude,
    required double longitude,
  }) async {
    if (_socket == null) {
      _errorController.add('Not connected to server');
      return false;
    }

    if (_currentRoomId == null || _currentUserId == null) {
      _errorController.add('Room or user ID not set');
      return false;
    }

    try {
      developer.log('Sharing location: $latitude, $longitude');

      _socket!.emit('share-location', {
        'roomId': _currentRoomId,
        'userId': _currentUserId,
        'latitude': latitude,
        'longitude': longitude,
      });

      // Update local location
      final myLocation = UserLocation(
        userId: _currentUserId!,
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now().toIso8601String(),
      );
      _userLocations[_currentUserId!] = myLocation;
      _allLocationsController.add(Map.from(_userLocations));

      return true;
    } catch (e) {
      developer.log('Error sharing location: $e');
      _errorController.add('Failed to share location: $e');
      return false;
    }
  }

  // Request all current locations in room
  Future<void> requestAllLocations() async {
    if (_socket == null || _currentRoomId == null) {
      _errorController.add('Not connected to server or room');
      return;
    }

    try {
      developer.log('Requesting all locations');
      _socket!.emit('get-all-locations', {'roomId': _currentRoomId});
    } catch (e) {
      developer.log('Error requesting locations: $e');
      _errorController.add('Failed to get locations: $e');
    }
  }

  // Get specific user location
  UserLocation? getUserLocation(String userId) {
    return _userLocations[userId];
  }

  // Get current user's location
  UserLocation? getMyLocation() {
    if (_currentUserId == null) return null;
    return _userLocations[_currentUserId!];
  }

  // Clear all stored locations
  void clearLocations() {
    _userLocations.clear();
    _allLocationsController.add({});
  }

  // Reset service
  void reset() {
    _userLocations.clear();
    _currentRoomId = null;
    _currentUserId = null;
    _socket = null;
  }

  // Dispose all resources
  Future<void> dispose() async {
    developer.log('Disposing LocationService');
    reset();
    await _locationUpdateController.close();
    await _allLocationsController.close();
    await _errorController.close();
  }
}
