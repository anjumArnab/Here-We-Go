import 'package:flutter/material.dart';
import 'package:herewego/models/user_location.dart';
import 'package:latlong2/latlong.dart';

class RouteData {
  final String userId;
  final UserLocation userLocation;
  final List<LatLng> points;
  final Color color;
  final double strokeWidth;
  final bool isDotted;

  RouteData({
    required this.userId,
    required this.userLocation,
    required this.points,
    required this.color,
    this.strokeWidth = 4.0,
    this.isDotted = false,
  });
}