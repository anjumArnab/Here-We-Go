import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/location_service.dart';
import '../models/connection_status.dart';
import '../models/user_location.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  // Stream subscriptions
  StreamSubscription<ConnectionStatus>? _connectionSubscription;
  StreamSubscription<Map<String, UserLocation>>? _allLocationsSubscription;
  StreamSubscription<UserLocation>? _locationUpdateSubscription;
  StreamSubscription<List<String>>? _roomUsersSubscription;
  StreamSubscription<String>? _errorSubscription;

  // State
  bool _isConnected = false;
  String? _currentUserId;
  String? _currentRoomId;
  Map<String, UserLocation> _userLocations = {};
  List<String> _roomUsers = [];
  String? _lastError;
  UserLocation? _lastLocationUpdate;
  bool _isConnecting = false;
  String? _lastConnectionMessage;

  // Getters
  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;
  String? get currentRoomId => _currentRoomId;
  Map<String, UserLocation> get userLocations =>
      Map.unmodifiable(_userLocations);
  List<String> get roomUsers => List.unmodifiable(_roomUsers);
  String? get lastError => _lastError;
  UserLocation? get lastLocationUpdate => _lastLocationUpdate;
  bool get isConnecting => _isConnecting;
  String? get serverUrl => _locationService.serverUrl;
  String? get connectionStatusMessage => _lastConnectionMessage;

  LocationProvider() {
    _setupListeners();
    _checkInitialState();
  }

  void _setupListeners() {
    _connectionSubscription = _locationService.connectionStream.listen((
      status,
    ) {
      _isConnected = status.isConnected;
      _currentUserId = status.userId;
      _currentRoomId = status.roomId;
      _roomUsers = status.roomUsers;
      _lastConnectionMessage = status.message;
      notifyListeners();
    });

    _allLocationsSubscription = _locationService.allLocationsStream.listen((
      locations,
    ) {
      _userLocations = locations;
      notifyListeners();
    });

    _locationUpdateSubscription = _locationService.locationUpdateStream.listen((
      location,
    ) {
      _lastLocationUpdate = location;
      notifyListeners();
    });

    _roomUsersSubscription = _locationService.roomUsersStream.listen((users) {
      _roomUsers = users;
      notifyListeners();
    });

    _errorSubscription = _locationService.errorStream.listen((error) {
      _lastError = error;
      notifyListeners();
    });
  }

  void _checkInitialState() {
    _isConnected = _locationService.isConnected;
    _currentUserId = _locationService.currentUserId;
    _currentRoomId = _locationService.currentRoomId;
    _roomUsers = _locationService.roomUsers;
    _userLocations = _locationService.userLocations;
  }

  Future<bool> connectToServer({
    required String serverUrl,
    required String roomId,
    required String userId,
  }) async {
    _isConnecting = true;
    _lastError = null;
    notifyListeners();

    final success = await _locationService.connectToServer(
      serverUrl: serverUrl,
      roomId: roomId,
      userId: userId,
    );

    _isConnecting = false;
    notifyListeners();

    return success;
  }

  Future<bool> shareLocation({
    required double latitude,
    required double longitude,
  }) async {
    final success = await _locationService.shareLocation(
      latitude: latitude,
      longitude: longitude,
    );
    return success;
  }

  Future<void> requestAllLocations() async {
    await _locationService.requestAllLocations();
  }

  Future<void> leaveRoom() async {
    await _locationService.leaveRoom();
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _locationService.disconnect();
    notifyListeners();
  }

  UserLocation? getUserLocation(String userId) {
    return _locationService.getUserLocation(userId);
  }

  UserLocation? getMyLocation() {
    return _locationService.getMyLocation();
  }

  void clearLocations() {
    _locationService.clearLocations();
    notifyListeners();
  }

  void clearLastError() {
    _lastError = null;
    notifyListeners();
  }

  void clearLastLocationUpdate() {
    _lastLocationUpdate = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _allLocationsSubscription?.cancel();
    _locationUpdateSubscription?.cancel();
    _roomUsersSubscription?.cancel();
    _errorSubscription?.cancel();
    _locationService.dispose();
    super.dispose();
  }
}
