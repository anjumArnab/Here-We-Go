import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_info.dart';
import '../models/user_location.dart';
import '../models/route_data.dart';

class RouteService {
  // OSRM API base URL
  static const String osrmBaseUrl = "http://router.project-osrm.org/route/v1";

  // Route display settings
  String _routeMode = 'driving'; // driving, walking, cycling
  List<String> _selectedUsers = []; // Empty means show routes to all users

  // Color scheme for routes
  final List<Color> _polylineColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.cyan,
    Colors.pink,
    Colors.indigo,
  ];

  // Cache for route geometries to avoid repeated API calls
  final Map<String, List<LatLng>> _routeCache = {};

  // Getters
  String get routeMode => _routeMode;
  List<String> get selectedUsers => List.from(_selectedUsers);
  List<Color> get polylineColors => List.from(_polylineColors);

  // Setters
  void setRouteMode(String mode) {
    _routeMode = mode;
    _routeCache.clear(); // Clear cache when mode changes
  }

  void setSelectedUsers(List<String> users) {
    _selectedUsers = List.from(users);
  }

  void addSelectedUser(String userId) {
    if (!_selectedUsers.contains(userId)) {
      _selectedUsers.add(userId);
    }
  }

  void removeSelectedUser(String userId) {
    _selectedUsers.remove(userId);
  }

  void clearSelectedUsers() {
    _selectedUsers.clear();
  }

  /// Get route points between two locations using OSRM API
  Future<List<LatLng>> getRoutePoints(LatLng origin, LatLng destination) async {
    // Create cache key
    String cacheKey =
        "${origin.latitude},${origin.longitude}|${destination.latitude},${destination.longitude}|$_routeMode";

    // Check cache first
    if (_routeCache.containsKey(cacheKey)) {
      return _routeCache[cacheKey]!;
    }

    List<LatLng> routeCoordinates = [];

    try {
      // Construct OSRM URL
      String profile = _getOSRMProfile();
      String coordinates =
          "${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}";
      String url =
          "$osrmBaseUrl/$profile/$coordinates?overview=full&geometries=geojson";

      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          var geometry = data['routes'][0]['geometry'];

          if (geometry != null && geometry['coordinates'] != null) {
            List<dynamic> coordinates = geometry['coordinates'];

            routeCoordinates =
                coordinates.map<LatLng>((coord) {
                  return LatLng(
                    coord[1].toDouble(),
                    coord[0].toDouble(),
                  ); // OSRM returns [lng, lat]
                }).toList();
          }
        } else {
          // Fallback to direct line
          routeCoordinates = [origin, destination];
        }
      } else {
        // Fallback to direct line
        routeCoordinates = [origin, destination];
      }
    } catch (e) {

      // Fallback to direct line
      routeCoordinates = [origin, destination];
    }

    // Cache the result
    if (routeCoordinates.isNotEmpty) {
      _routeCache[cacheKey] = routeCoordinates;
    }

    return routeCoordinates;
  }

  /// Generate routes data for flutter_map Polyline widgets
  Future<List<RouteData>> generateRoutes({
    required LatLng currentLocation,
    required Map<String, UserLocation> userLocations,
    required String? currentUserId,
  }) async {
    List<RouteData> routes = [];
    int colorIndex = 0;

    try {
      // Determine target users for routes
      List<String> targetUsers =
          _selectedUsers.isEmpty
              ? userLocations.keys
                  .where((userId) => userId != currentUserId)
                  .toList()
              : _selectedUsers;

      for (String userId in targetUsers) {
        UserLocation? userLocation = userLocations[userId];
        if (userLocation == null || userId == currentUserId) continue;

        LatLng destination = LatLng(
          userLocation.latitude,
          userLocation.longitude,
        );

        List<LatLng> routeCoordinates = await getRoutePoints(
          currentLocation,
          destination,
        );

        if (routeCoordinates.isNotEmpty) {
          routes.add(
            RouteData(
              userId: userId,
              userLocation: userLocation,
              points: routeCoordinates,
              color: _polylineColors[colorIndex % _polylineColors.length],
              strokeWidth: 4.0,
              isDotted: _routeMode == 'walking',
            ),
          );
        }

        colorIndex++;
      }
    } catch (e) {
      rethrow;
    }

    return routes;
  }

  /// Calculate direct distance between two points
  double calculateDistance(LatLng from, LatLng to) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, from, to);
  }

  /// Calculate distance from point to route polyline in meters
  double distanceToRoute(LatLng point, List<LatLng> route) {
    if (route.length < 2) return double.infinity;

    double minDistance = double.infinity;

    for (int i = 0; i < route.length - 1; i++) {
      double distance = _distanceToLineSegment(point, route[i], route[i + 1]);
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  /// Calculate distance from point to line segment in meters
  double _distanceToLineSegment(
    LatLng point,
    LatLng lineStart,
    LatLng lineEnd,
  ) {
    const Distance distCalc = Distance();

    // Calculate distances
    double lineLength = distCalc.as(LengthUnit.Meter, lineStart, lineEnd);
    double distToStart = distCalc.as(LengthUnit.Meter, point, lineStart);

    // If line segment has zero length
    if (lineLength == 0) return distToStart;

    // Calculate projection factor
    double dx = lineEnd.longitude - lineStart.longitude;
    double dy = lineEnd.latitude - lineStart.latitude;
    double px = point.longitude - lineStart.longitude;
    double py = point.latitude - lineStart.latitude;

    double t = (px * dx + py * dy) / (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0);

    // Calculate projection point
    LatLng projection = LatLng(
      lineStart.latitude + t * dy,
      lineStart.longitude + t * dx,
    );

    return distCalc.as(LengthUnit.Meter, point, projection);
  }

  /// Calculate total route distance in kilometers
  double calculateRouteDistance(List<LatLng> route) {
    if (route.length < 2) return 0.0;

    const Distance distCalc = Distance();
    double totalDistance = 0.0;

    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += distCalc.as(LengthUnit.Meter, route[i], route[i + 1]);
    }

    return totalDistance / 1000.0;
  }

  /// Get route information for display
  RouteInfo getRouteInfo({
    required String userId,
    required UserLocation userLocation,
    required LatLng currentLocation,
  }) {
    double distance = calculateDistance(
      currentLocation,
      LatLng(userLocation.latitude, userLocation.longitude),
    );

    return RouteInfo(
      userId: userId,
      userLocation: userLocation,
      travelMode: _routeMode.toUpperCase(),
      directDistance: '${distance.toStringAsFixed(2)} km',
      destination:
          '${userLocation.latitude.toStringAsFixed(6)}, ${userLocation.longitude.toStringAsFixed(6)}',
      lastUpdated: _formatTimestamp(userLocation.timestamp),
    );
  }

  /// Format timestamp for display
  String _formatTimestamp(String timestamp) {
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

  /// Get OSRM profile based on route mode
  String _getOSRMProfile() {
    switch (_routeMode) {
      case 'walking':
        return 'foot';
      case 'cycling':
        return 'bicycle';
      case 'driving':
      default:
        return 'driving';
    }
  }

  /// Clear route cache
  void clearCache() {
    _routeCache.clear();
  }

  /// Dispose of resources
  void dispose() {
    _selectedUsers.clear();
    _routeCache.clear();
  }
}
