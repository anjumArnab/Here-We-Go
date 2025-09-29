import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_result.dart';
import '../models/user_location.dart';

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

  // Getters
  LatLng? get currentLocation => _currentLocation;
  bool get isLoadingLocation => _isLoadingLocation;
  List<Color> get markerColors => List.from(_markerColors);

  /// Get current user location with proper error handling
  Future<LocationResult> getCurrentLocation() async {
    _isLoadingLocation = true;

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        _currentLocation = defaultLocation;
        _isLoadingLocation = false;
        return LocationResult.error(
          'Location services are disabled. Using default location.',
          defaultLocation,
        );
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          _currentLocation = defaultLocation;
          _isLoadingLocation = false;
          return LocationResult.error(
            'Location permission denied. Using default location.',
            defaultLocation,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        _currentLocation = defaultLocation;
        _isLoadingLocation = false;
        return LocationResult.error(
          'Location permission permanently denied. Using default location.',
          defaultLocation,
        );
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );

      _currentLocation = LatLng(position.latitude, position.longitude);
      _isLoadingLocation = false;

      debugPrint(
        'Current location obtained: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}',
      );

      return LocationResult.success(_currentLocation!);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      _currentLocation = defaultLocation;
      _isLoadingLocation = false;
      return LocationResult.error(
        'Error getting location: ${e.toString()}. Using default location.',
        defaultLocation,
      );
    }
  }

  /// Set default location when location access fails
  LocationResult setDefaultLocation() {
    _currentLocation = defaultLocation;
    _isLoadingLocation = false;
    return LocationResult.success(defaultLocation);
  }

  /// Create marker for current user location
  Widget createCurrentLocationMarker({bool hasPermission = true}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: (hasPermission ? Colors.blue : Colors.grey).withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: hasPermission ? Colors.blue : Colors.grey,
          width: 3,
        ),
      ),
      child: Icon(
        hasPermission ? Icons.my_location : Icons.location_on,
        color: hasPermission ? Colors.blue : Colors.grey,
        size: 28,
      ),
    );
  }

  /// Generate markers for all user locations
  List<Marker> generateUserMarkers({
    required Map<String, UserLocation> userLocations,
    required String? currentUserId,
    bool hasLocationPermission = true,
    Function(String userId, UserLocation userLocation)? onMarkerTap,
  }) {
    List<Marker> markers = [];

    // Add current location marker if available
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () {
              if (onMarkerTap != null && currentUserId != null) {
                UserLocation currentUserLocation = UserLocation(
                  userId: currentUserId,
                  latitude: _currentLocation!.latitude,
                  longitude: _currentLocation!.longitude,
                  timestamp: DateTime.now().toIso8601String(),
                );
                onMarkerTap(currentUserId, currentUserLocation);
              }
            },
            child: createCurrentLocationMarker(
              hasPermission: hasLocationPermission,
            ),
          ),
        ),
      );
    }

    // Add markers for all other users
    int colorIndex = 0;
    for (var entry in userLocations.entries) {
      String userId = entry.key;
      UserLocation userLocation = entry.value;

      // Skip if this is the current user (already have current_location marker)
      if (userId == currentUserId) {
        colorIndex++;
        continue;
      }

      // Create marker for this user
      markers.add(
        Marker(
          point: LatLng(userLocation.latitude, userLocation.longitude),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => onMarkerTap?.call(userId, userLocation),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _markerColors[colorIndex % _markerColors.length]
                    .withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _markerColors[colorIndex % _markerColors.length],
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.person_pin_circle,
                color: _markerColors[colorIndex % _markerColors.length],
                size: 28,
              ),
            ),
          ),
        ),
      );

      colorIndex++;
    }

    return markers;
  }

  /// Calculate bounds to show all locations on the map
  LatLngBounds? calculateBoundsForAllLocations({
    required Map<String, UserLocation> userLocations,
  }) {
    // Collect all locations
    List<LatLng> allLocations = [];

    // Add current location
    if (_currentLocation != null) {
      allLocations.add(_currentLocation!);
    }

    // Add user locations
    for (var userLocation in userLocations.values) {
      allLocations.add(LatLng(userLocation.latitude, userLocation.longitude));
    }

    if (allLocations.length < 2) {
      return null; // Not enough points for bounds
    }

    // Calculate bounds
    double minLat = allLocations
        .map((loc) => loc.latitude)
        .reduce((a, b) => a < b ? a : b);
    double maxLat = allLocations
        .map((loc) => loc.latitude)
        .reduce((a, b) => a > b ? a : b);
    double minLng = allLocations
        .map((loc) => loc.longitude)
        .reduce((a, b) => a < b ? a : b);
    double maxLng = allLocations
        .map((loc) => loc.longitude)
        .reduce((a, b) => a > b ? a : b);

    // Add padding
    double latPadding = (maxLat - minLat) * 0.1;
    double lngPadding = (maxLng - minLng) * 0.1;

    // Ensure minimum padding
    latPadding = latPadding < 0.005 ? 0.005 : latPadding;
    lngPadding = lngPadding < 0.005 ? 0.005 : lngPadding;

    return LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding),
      LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
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

  /// Check if location permission is available
  Future<bool> isLocationPermissionGranted() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Create user info widget for marker popup
  Widget createUserInfoWidget(String userId, UserLocation userLocation) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userId,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Lat: ${userLocation.latitude.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Lng: ${userLocation.longitude.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Updated: ${formatTimestamp(userLocation.timestamp)}',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// Dispose of resources
  void dispose() {
    _currentLocation = null;
    _isLoadingLocation = false;
  }
}
