import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/location_service.dart';
import '../models/user_location.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  // Stream subscriptions
  StreamSubscription<Map<String, UserLocation>>? _allLocationsSubscription;
  StreamSubscription<UserLocation>? _locationUpdateSubscription;
  StreamSubscription<String>? _errorSubscription;

  // State
  Map<String, UserLocation> _userLocations = {};
  String? _lastError;
  UserLocation? _lastLocationUpdate;
  bool _isInitialized = false;

  // Getters
  Map<String, UserLocation> get userLocations => Map.unmodifiable(_userLocations);
  String? get lastError => _lastError;
  UserLocation? get lastLocationUpdate => _lastLocationUpdate;
  bool get isInitialized => _isInitialized;

  LocationProvider() {
    _setupListeners();
  }

  void _setupListeners() {
    _allLocationsSubscription = _locationService.allLocationsStream.listen((locations) {
      _userLocations = locations;
      notifyListeners();
    });

    _locationUpdateSubscription = _locationService.locationUpdateStream.listen((location) {
      _lastLocationUpdate = location;
      notifyListeners();
    });

    _errorSubscription = _locationService.errorStream.listen((error) {
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
    _locationService.initialize(
      socket: socket,
      roomId: roomId,
      userId: userId,
    );
    _isInitialized = true;
    _userLocations = _locationService.userLocations;
    notifyListeners();
  }

  // Share location
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

  // Request all locations
  Future<void> requestAllLocations() async {
    await _locationService.requestAllLocations();
  }

  // Get specific user location
  UserLocation? getUserLocation(String userId) {
    return _locationService.getUserLocation(userId);
  }

  // Get current user's location
  UserLocation? getMyLocation() {
    return _locationService.getMyLocation();
  }

  // Clear locations
  void clearLocations() {
    _locationService.clearLocations();
    _userLocations = {};
    notifyListeners();
  }

  // Reset provider
  void reset() {
    _locationService.reset();
    _userLocations = {};
    _isInitialized = false;
    _lastError = null;
    _lastLocationUpdate = null;
    notifyListeners();
  }

  // Clear error
  void clearLastError() {
    _lastError = null;
    notifyListeners();
  }

  // Clear last location update
  void clearLastLocationUpdate() {
    _lastLocationUpdate = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _allLocationsSubscription?.cancel();
    _locationUpdateSubscription?.cancel();
    _errorSubscription?.cancel();
    _locationService.dispose();
    super.dispose();
  }
}