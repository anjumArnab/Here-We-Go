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
}
