import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../services/user_location_handler.dart';
import '../models/location_result.dart';
import '../models/user_location.dart';
import '../models/map_marker_data.dart';

class UserLocationProvider extends ChangeNotifier {
  final UserLocationHandler _userLocationHandler = UserLocationHandler();

  // State
  bool _isLoadingLocation = false;
  bool _locationPermissionGranted = false;
  String? _locationError;

  // Continuous tracking state
  StreamSubscription<LatLng>? _trackingSubscription;
  bool _isTracking = false;

  // Getters
  LatLng? get currentLocation => _userLocationHandler.currentLocation;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get locationPermissionGranted => _locationPermissionGranted;
  String? get locationError => _locationError;
  bool get isTracking => _isTracking;

  Future<LocationResult> getCurrentLocation() async {
    _isLoadingLocation = true;
    _locationError = null;
    notifyListeners();

    final result = await _userLocationHandler.getCurrentLocation();

    _isLoadingLocation = false;
    _locationPermissionGranted = result.isSuccess;

    if (!result.isSuccess) {
      _locationError = result.error;
    }

    notifyListeners();
    return result;
  }

  LocationResult setDefaultLocation() {
    final result = _userLocationHandler.setDefaultLocation();
    _locationPermissionGranted = false;
    notifyListeners();
    return result;
  }

  /// Start continuous location tracking
  Stream<LatLng>? startContinuousTracking({
    Duration interval = const Duration(seconds: 5),
    double distanceFilter = 10.0,
    Function(LatLng)? onLocationUpdate,
  }) {
    if (!_locationPermissionGranted) {
      _locationError = 'Location permission not granted';
      notifyListeners();
      return null;
    }

    // Stop any existing tracking
    stopContinuousTracking();

    _isTracking = true;
    notifyListeners();

    // Start tracking from handler
    final stream = _userLocationHandler.startContinuousTracking(
      interval: interval,
      distanceFilter: distanceFilter,
    );

    // Subscribe to updates
    _trackingSubscription = stream.listen(
      (LatLng location) {
        // Notify listeners about location change
        notifyListeners();

        // Call optional callback
        if (onLocationUpdate != null) {
          onLocationUpdate(location);
        }
      },
      onError: (error) {
        _locationError = 'Location tracking error: $error';
        _isTracking = false;
        notifyListeners();
      },
      onDone: () {
        _isTracking = false;
        notifyListeners();
      },
    );

    return stream;
  }

  /// Stop continuous location tracking
  void stopContinuousTracking() {
    _trackingSubscription?.cancel();
    _trackingSubscription = null;

    _userLocationHandler.stopContinuousTracking();

    _isTracking = false;
    notifyListeners();
  }

  /// Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    return await _userLocationHandler.hasLocationPermission();
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await _userLocationHandler.isLocationServiceEnabled();
  }

  /// Refresh location permission status
  Future<void> refreshPermissionStatus() async {
    _locationPermissionGranted = await hasLocationPermission();
    notifyListeners();
  }

  List<MapMarkerData> generateUserMarkerData({
    required Map<String, UserLocation> userLocations,
    required String? currentUserId,
  }) {
    return _userLocationHandler.generateUserMarkerData(
      userLocations: userLocations,
      currentUserId: currentUserId,
      hasLocationPermission: _locationPermissionGranted,
    );
  }

  LatLng getFocusLocationForUser(UserLocation userLocation) {
    return _userLocationHandler.getFocusLocationForUser(userLocation);
  }

  LatLng? getFocusLocationForCurrent() {
    return _userLocationHandler.getFocusLocationForCurrent();
  }

  String formatTimestamp(String timestamp) {
    return _userLocationHandler.formatTimestamp(timestamp);
  }

  void clearLocationError() {
    _locationError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopContinuousTracking();
    _userLocationHandler.dispose();
    super.dispose();
  }
}
