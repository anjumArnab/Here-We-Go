import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum MarkerType { currentLocation, user }

class MapMarkerData {
  final LatLng point;
  final Color color;
  final MarkerType type;
  final String? userId;
  final bool hasPermission;

  MapMarkerData({
    required this.point,
    required this.color,
    required this.type,
    this.userId,
    this.hasPermission = true,
  });

  /// Convert color to hex string for JavaScript
  String get colorHex {
    return '#${color.value.toRadixString(16).substring(2).padLeft(6, '0')}';
  }

  /// Get marker type as string for JavaScript
  String get typeString {
    switch (type) {
      case MarkerType.currentLocation:
        return 'current';
      case MarkerType.user:
        return 'user';
    }
  }
}
