// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_result.dart';
import '../models/user_location.dart';
import '../models/map_marker_data.dart';

class UserLocationHandler {
  // Default location (Dhaka, Bangladesh)
  static const LatLng defaultLocation = LatLng(23.8103, 90.4125);

  // Color scheme for different user markers
  final List<Color> _markerColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.cyan,
    Colors.pink,
    Colors.indigo,
    Colors.teal,
    Colors.amber,
  ];

  // Current location state
  LatLng? _currentLocation;
  bool _isLoadingLocation = false;

  // Continuous tracking state
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamController<LatLng>? _locationStreamController;

  // Getters
  LatLng? get currentLocation => _currentLocation;
  bool get isLoadingLocation => _isLoadingLocation;
  List<Color> get markerColors => List.from(_markerColors);
  bool get isTracking => _positionStreamSubscription != null;

  /// Get current user location with proper error handling
  Future<LocationResult> getCurrentLocation() async {
    _isLoadingLocation = true;

    try {
      // Check the current location permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Show the system permission dialog to request location access
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          _currentLocation = defaultLocation;
          _isLoadingLocation = false;
          return LocationResult.error(
            'Location permission denied. Please grant permission in settings.',
            defaultLocation,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _currentLocation = defaultLocation;
        _isLoadingLocation = false;
        return LocationResult.error(
          'Location permission permanently denied. Please enable in device settings.',
          defaultLocation,
        );
      }

      // Check if location services are enabled on the device
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Try to open location settings
        bool opened = await Geolocator.openLocationSettings();

        if (opened) {
          // Wait for user to potentially enable GPS
          await Future.delayed(Duration(seconds: 2));

          // Check again after user returns
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
        }

        if (!serviceEnabled) {
          _currentLocation = defaultLocation;
          _isLoadingLocation = false;
          return LocationResult.error(
            'GPS is disabled. Please enable Location Services in your device settings.',
            defaultLocation,
          );
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );

      _currentLocation = LatLng(position.latitude, position.longitude);
      _isLoadingLocation = false;
      return LocationResult.success(_currentLocation!);
    } catch (e) {
      _currentLocation = defaultLocation;
      _isLoadingLocation = false;
      return LocationResult.error(
        'Error getting location: ${e.toString()}. Using default location.',
        defaultLocation,
      );
    }
  }

  /// Returns a stream that emits location updates
  Stream<LatLng> startContinuousTracking({
    Duration interval = const Duration(seconds: 5),
    int distanceFilter = 5, // meters
  }) {
    // Stop any existing tracking
    stopContinuousTracking();

    // Create location stream controller
    _locationStreamController = StreamController<LatLng>.broadcast();

    // Configure location settings for navigation
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter,
    );

    // Start listening to position stream
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _currentLocation = LatLng(position.latitude, position.longitude);

        // Emit location update
        if (!_locationStreamController!.isClosed) {
          _locationStreamController!.add(_currentLocation!);
        }
      },
      onError: (error) {
        if (!_locationStreamController!.isClosed) {
          _locationStreamController!.addError(error);
        }
      },
    );

    return _locationStreamController!.stream;
  }

  /// Stop continuous location tracking
  void stopContinuousTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    _locationStreamController?.close();
    _locationStreamController = null;
  }

  /// Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Set default location when location access fails
  LocationResult setDefaultLocation() {
    _currentLocation = defaultLocation;
    _isLoadingLocation = false;
    return LocationResult.success(defaultLocation);
  }

  /// Create marker data for current user location
  MapMarkerData? createCurrentLocationMarkerData({bool hasPermission = true}) {
    if (_currentLocation == null) return null;

    return MapMarkerData(
      point: _currentLocation!,
      color: hasPermission ? Colors.blue : Colors.grey,
      type: MarkerType.currentLocation,
      hasPermission: hasPermission,
    );
  }

  /// Generate marker data for all user locations
  List<MapMarkerData> generateUserMarkerData({
    required Map<String, UserLocation> userLocations,
    required String? currentUserId,
    bool hasLocationPermission = true,
  }) {
    List<MapMarkerData> markers = [];

    // Add current location marker if available
    final currentMarker = createCurrentLocationMarkerData(
      hasPermission: hasLocationPermission,
    );
    if (currentMarker != null) {
      markers.add(currentMarker);
    }

    // Add markers for all other users
    int colorIndex = 0;
    for (var entry in userLocations.entries) {
      String userId = entry.key;
      UserLocation userLocation = entry.value;

      // Skip if this is the current user
      if (userId == currentUserId) {
        colorIndex++;
        continue;
      }

      // Create marker data for this user
      markers.add(
        MapMarkerData(
          point: LatLng(userLocation.latitude, userLocation.longitude),
          color: _markerColors[colorIndex % _markerColors.length],
          type: MarkerType.user,
          userId: userId,
        ),
      );

      colorIndex++;
    }

    return markers;
  }

  /// Get coordinates to focus on a specific user
  LatLng getFocusLocationForUser(UserLocation userLocation) {
    return LatLng(userLocation.latitude, userLocation.longitude);
  }

  /// Get coordinates to focus on current location
  LatLng? getFocusLocationForCurrent() {
    return _currentLocation;
  }

  /// Format timestamp for display
  String formatTimestamp(String timestamp) {
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      DateTime now = DateTime.now();
      Duration difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return "Just now";
      } else if (difference.inMinutes < 60) {
        return "${difference.inMinutes}m ago";
      } else if (difference.inHours < 24) {
        return "${difference.inHours}h ago";
      } else {
        return "${difference.inDays}d ago";
      }
    } catch (e) {
      return "Unknown";
    }
  }

  /// Dispose of resources
  void dispose() {
    stopContinuousTracking();
    _currentLocation = null;
    _isLoadingLocation = false;
  }
}
