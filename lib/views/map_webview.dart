// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/map_marker_data.dart';
import 'map_assets.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapWebView extends StatefulWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final List<MapMarkerData> markers;
  final List<Polyline> polylines;
  final MapWebViewController? controller;
  final Function(LatLng)? onTap;
  final Function(LatLng)? onLongPress;
  final Function(int markerIndex)? onMarkerTap;

  const MapWebView({
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
  State<MapWebView> createState() => _MapWebViewState();
}

class _MapWebViewState extends State<MapWebView> {
  late final WebViewController _webViewController;
  bool _isMapReady = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..addJavaScriptChannel(
            'FlutterChannel',
            onMessageReceived: (JavaScriptMessage message) {
              _handleMessageFromJS(message.message);
            },
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {},
              onPageFinished: (String url) {
                setState(() {
                  _isLoading = false;
                });
                // Wait a bit for Leaflet to fully initialize
                Future.delayed(const Duration(milliseconds: 500), () {
                  _isMapReady = true;
                  _initializeMap();
                });
              },
              onWebResourceError: (WebResourceError error) {},
            ),
          );

    _buildMapHtml().then(_webViewController.loadHtmlString);

    // Expose controller to parent widget
    widget.controller?._setWebViewController(_webViewController);
  }

  void _handleMessageFromJS(String message) {
    try {
      final data = jsonDecode(message);
      final String type = data['type'];

      switch (type) {
        case 'mapClick':
          if (widget.onTap != null) {
            final lat = data['lat'] as double;
            final lng = data['lng'] as double;
            widget.onTap!(LatLng(lat, lng));
          }
          break;
        case 'mapLongPress':
          if (widget.onLongPress != null) {
            final lat = data['lat'] as double;
            final lng = data['lng'] as double;
            widget.onLongPress!(LatLng(lat, lng));
          }
          break;
        case 'markerClick':
          // Handle marker clicks
          if (widget.onMarkerTap != null) {
            final markerId = data['markerId'] as String;
            // Extract marker index from markerId
            final indexStr = markerId.replaceAll('marker_', '');
            final markerIndex = int.tryParse(indexStr);
            if (markerIndex != null) {
              widget.onMarkerTap!(markerIndex);
            }
          }
          break;
        case 'mapReady':
          break;
        default:
      }
    } catch (e) {
      //
    }
  }

  @override
  void didUpdateWidget(MapWebView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isMapReady) {
      // Update markers if changed
      if (!_areMarkersEqual(oldWidget.markers, widget.markers)) {
        _updateMarkers();
      }

      // Update polylines if changed
      if (!_arePolylinesEqual(oldWidget.polylines, widget.polylines)) {
        _updatePolylines();
      }
    }
  }

  bool _areMarkersEqual(List<MapMarkerData> old, List<MapMarkerData> current) {
    if (old.length != current.length) return false;
    for (int i = 0; i < old.length; i++) {
      if (old[i].point != current[i].point) return false;
      if (old[i].color != current[i].color) return false;
      if (old[i].type != current[i].type) return false;
    }
    return true;
  }

  bool _arePolylinesEqual(List<Polyline> old, List<Polyline> current) {
    if (old.length != current.length) return false;
    for (int i = 0; i < old.length; i++) {
      if (old[i].points.length != current[i].points.length) return false;
    }
    return true;
  }

  void _initializeMap() {
    if (!_isMapReady) return;

    // Set initial view
    _webViewController.runJavaScript('''
      if (map) {
        map.setView([${widget.initialCenter.latitude}, ${widget.initialCenter.longitude}], ${widget.initialZoom});
      }
    ''');

    // Add initial markers and polylines
    Future.delayed(const Duration(milliseconds: 200), () {
      _updateMarkers();
      _updatePolylines();
    });
  }

  void _updateMarkers() {
    if (!_isMapReady) return;

    // Clear existing markers
    _webViewController.runJavaScript('clearMarkers();');

    // Add new markers
    for (int i = 0; i < widget.markers.length; i++) {
      final marker = widget.markers[i];
      final lat = marker.point.latitude;
      final lng = marker.point.longitude;
      final color = marker.colorHex;
      final type = marker.typeString;
      final userId = marker.userId ?? 'You';

      final escapedUserId = userId.replaceAll("'", "\\'");

      _webViewController.runJavaScript('''
      addMarker($lat, $lng, '$color', '$type', 'marker_$i', '$escapedUserId');
    ''');
    }
  }

  void _updatePolylines() {
    if (!_isMapReady) return;

    // Clear existing polylines
    _webViewController.runJavaScript('clearPolylines();');

    // Add new polylines
    for (int i = 0; i < widget.polylines.length; i++) {
      final polyline = widget.polylines[i];
      final points =
          polyline.points.map((p) => [p.latitude, p.longitude]).toList();
      final pointsJson = jsonEncode(points);
      final color = _colorToHex(polyline.color);
      final weight = polyline.strokeWidth;

      _webViewController.runJavaScript('''
        addPolyline($pointsJson, '$color', $weight, 'polyline_$i');
      ''');
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).padLeft(6, '0')}';
  }

  Future<String> _buildMapHtml() async {
    final config = jsonEncode({
      'lat': widget.initialCenter.latitude,
      'lng': widget.initialCenter.longitude,
      'zoom': widget.initialZoom,
      'minZoom': widget.minZoom,
      'maxZoom': widget.maxZoom,
    });
    return MapAssets.buildHtml(config: config);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        if (_isLoading)
          Container(
            color: Colors.white,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class MapWebViewController {
  WebViewController? _webViewController;

  void _setWebViewController(WebViewController controller) {
    _webViewController = controller;
  }

  /// Move map to specific location with optional zoom level and offset
  Future<void> move(LatLng center, double zoom, {double offsetY = 0}) async {
    if (_webViewController == null) {
      return;
    }

    try {
      await _webViewController!.runJavaScript('''
      moveMap(${center.latitude}, ${center.longitude}, $zoom, $offsetY);
    ''');
    } catch (e) {
      debugPrint('Error moving map: $e');
    }
  }

  /// Fit map bounds to show all markers and polylines
  Future<void> fitBounds() async {
    if (_webViewController == null) {
      return;
    }

    try {
      await _webViewController!.runJavaScript('fitBounds();');
    } catch (e) {
      //
    }
  }

  /// Fit map bounds with custom padding
  Future<void> fitBoundsWithPadding(double padding) async {
    if (_webViewController == null) {
      return;
    }

    try {
      await _webViewController!.runJavaScript(
        'fitBoundsWithPadding($padding);',
      );
    } catch (e) {
      //
    }
  }

  /// Set map zoom level
  Future<void> setZoom(double zoom) async {
    if (_webViewController == null) {
      return;
    }

    try {
      await _webViewController!.runJavaScript('setZoom($zoom);');
    } catch (e) {
      //
    }
  }

  /// Get current map center
  Future<LatLng?> getCenter() async {
    if (_webViewController == null) {
      return null;
    }

    try {
      await _webViewController!.runJavaScript('getCenter();');
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get current map zoom level
  Future<double?> getZoom() async {
    if (_webViewController == null) {
      return null;
    }

    try {
      await _webViewController!.runJavaScript('getZoom();');
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Execute custom JavaScript code
  Future<void> runJavaScript(String code) async {
    if (_webViewController == null) {
      return;
    }

    try {
      await _webViewController!.runJavaScript(code);
    } catch (e) {
      //
    }
  }
}
