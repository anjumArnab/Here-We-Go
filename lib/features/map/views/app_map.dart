import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data/map_marker_data.dart';
import '../widgets/map_markers.dart';

/// Lets parent widgets drive an [AppMap] (move the camera, fit all points).
class AppMapController {
  final MapController _controller = MapController();
  bool _isReady = false;
  List<LatLng> Function() _visiblePoints = () => const [];

  /// Center the map on [center] at [zoom]. A positive [offsetY] shifts the
  /// target down on screen by that many pixels (e.g. to clear a bottom panel).
  Future<void> move(LatLng center, double zoom, {double offsetY = 0}) async {
    if (!_isReady) return;

    var target = center;
    if (offsetY != 0) {
      final camera = _controller.camera;
      final projected = camera.projectAtZoom(center, zoom);
      target = camera.unprojectAtZoom(projected.translate(0, -offsetY), zoom);
    }
    _controller.move(target, zoom);
  }

  /// Zoom to show every marker and polyline, with [padding] pixels around.
  Future<void> fitBoundsWithPadding(double padding) async {
    if (!_isReady) return;

    final points = _visiblePoints();
    if (points.isEmpty) return;
    if (points.length == 1) {
      _controller.move(points.first, _controller.camera.zoom);
      return;
    }

    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: EdgeInsets.all(padding),
      ),
    );
  }

  void _attach(List<LatLng> Function() visiblePoints) {
    _isReady = true;
    _visiblePoints = visiblePoints;
  }

  void _detach() {
    _isReady = false;
    _visiblePoints = () => const [];
  }
}

/// OpenStreetMap map with user markers and route polylines.
class AppMap extends StatefulWidget {
  static const String tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String userAgentPackageName = 'com.example.herewego';

  final LatLng initialCenter;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final List<MapMarkerData> markers;
  final List<Polyline> polylines;
  final AppMapController? controller;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongPress;
  final void Function(int markerIndex)? onMarkerTap;

  const AppMap({
    super.key,
    required this.initialCenter,
    this.initialZoom = 15.0,
    this.minZoom = 3.0,
    this.maxZoom = 18.0,
    this.markers = const [],
    this.polylines = const [],
    this.controller,
    this.onTap,
    this.onLongPress,
    this.onMarkerTap,
  });

  @override
  State<AppMap> createState() => _AppMapState();
}

class _AppMapState extends State<AppMap> {
  @override
  void didUpdateWidget(AppMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    super.dispose();
  }

  List<LatLng> _visiblePoints() => [
    for (final m in widget.markers) m.point,
    for (final p in widget.polylines) ...p.points,
  ];

  Marker _buildMarker(int index, MapMarkerData data) {
    final Widget child;
    final double width;
    final double height;
    final Alignment alignment;

    switch (data.type) {
      case MarkerType.currentLocation:
        child = CurrentLocationDot(color: data.color);
        width = height = CurrentLocationDot.size;
        alignment = Alignment.center;
      case MarkerType.user:
        child = UserPin(color: data.color, label: data.userId ?? 'User');
        width = UserPin.width;
        height = UserPin.height;
        alignment = Alignment.topCenter; // pin tip sits on the coordinate
    }

    return Marker(
      point: data.point,
      width: width,
      height: height,
      alignment: alignment,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onMarkerTap?.call(index),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: widget.controller?._controller,
      options: MapOptions(
        initialCenter: widget.initialCenter,
        initialZoom: widget.initialZoom,
        minZoom: widget.minZoom,
        maxZoom: widget.maxZoom,
        onMapReady: () => widget.controller?._attach(_visiblePoints),
        onTap: (_, point) => widget.onTap?.call(point),
        onLongPress: (_, point) => widget.onLongPress?.call(point),
      ),
      children: [
        TileLayer(
          urlTemplate: AppMap.tileUrl,
          userAgentPackageName: AppMap.userAgentPackageName,
          minZoom: widget.minZoom,
          maxZoom: widget.maxZoom,
        ),
        PolylineLayer(
          polylines: [
            for (final p in widget.polylines)
              Polyline(
                points: p.points,
                color: p.color.withValues(alpha: 0.7),
                strokeWidth: p.strokeWidth,
                pattern: p.pattern,
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            for (var i = 0; i < widget.markers.length; i++)
              _buildMarker(i, widget.markers[i]),
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }
}
