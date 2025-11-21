// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:herewego/models/map_marker_data.dart';
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
              onPageStarted: (String url) {
                debugPrint('Map page started loading');
              },
              onPageFinished: (String url) {
                debugPrint('Map page loaded successfully');
                setState(() {
                  _isLoading = false;
                });
                // Wait a bit for Leaflet to fully initialize
                Future.delayed(const Duration(milliseconds: 500), () {
                  _isMapReady = true;
                  _initializeMap();
                });
              },
              onWebResourceError: (WebResourceError error) {
                debugPrint('Map loading error: ${error.description}');
              },
            ),
          )
          ..loadHtmlString(_generateMapHtml());

    // Expose controller to parent widget
    widget.controller?._setWebViewController(_webViewController);
  }

  void _handleMessageFromJS(String message) {
    debugPrint('Message from WebView: $message');

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
              debugPrint('Calling onMarkerTap with index: $markerIndex');
              widget.onMarkerTap!(markerIndex);
            }
          }
          break;
        case 'mapReady':
          debugPrint('Map is ready');
          break;
        default:
          debugPrint('Unknown message type: $type');
      }
    } catch (e) {
      debugPrint('Error parsing message from JS: $e');
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

    debugPrint('Initializing map with center: ${widget.initialCenter}');

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

    debugPrint('Updating ${widget.markers.length} markers');

    // Clear existing markers
    _webViewController.runJavaScript('clearMarkers();');

    // Add new markers
    for (int i = 0; i < widget.markers.length; i++) {
      final marker = widget.markers[i];
      final lat = marker.point.latitude;
      final lng = marker.point.longitude;
      final color = marker.colorHex;
      final type = marker.typeString;

      _webViewController.runJavaScript('''
      addMarker($lat, $lng, '$color', '$type', 'marker_$i');
    ''');
    }
  }

  void _updatePolylines() {
    if (!_isMapReady) return;

    debugPrint('Updating ${widget.polylines.length} polylines');

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

  String _generateMapHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Map</title>
  
  <!-- Leaflet CSS -->
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" 
    integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" 
    crossorigin=""/>
  
  <!-- Leaflet JS -->
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
    integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo="
    crossorigin=""></script>
  
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body, html {
      height: 100%;
      width: 100%;
      overflow: hidden;
    }
    
    #map {
      height: 100%;
      width: 100%;
      background: #f0f0f0;
    }
    
    /* Custom marker styles */
    .custom-marker {
      display: flex;
      align-items: center;
      justify-content: center;
    }
    
    .marker-current {
      width: 28px;
      height: 28px;
      background: #3b82f6;
      border: 3px solid white;
      border-radius: 50%;
      box-shadow: 0 2px 8px rgba(0,0,0,0.3);
    }
    
    .marker-user {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      border: 3px solid white;
      box-shadow: 0 2px 8px rgba(0,0,0,0.3);
      font-size: 20px;
    }
    
    /* Remove Leaflet attribution */
    .leaflet-control-attribution {
      display: none;
    }
  </style>
</head>
<body>
  <div id="map"></div>
  
  <script>
    // Initialize map
    var map = L.map('map', {
      zoomControl: true,
      attributionControl: false,
      minZoom: ${widget.minZoom},
      maxZoom: ${widget.maxZoom}
    }).setView([${widget.initialCenter.latitude}, ${widget.initialCenter.longitude}], ${widget.initialZoom});

    // Add OpenStreetMap tile layer
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: ${widget.maxZoom},
      minZoom: ${widget.minZoom}
    }).addTo(map);

    // Storage for markers and polylines
    var markers = {};
    var polylines = {};
    
    // Notify Flutter when map is ready
    setTimeout(function() {
      FlutterChannel.postMessage(JSON.stringify({
        type: 'mapReady'
      }));
    }, 100);

    // Map click event
    map.on('click', function(e) {
      FlutterChannel.postMessage(JSON.stringify({
        type: 'mapClick',
        lat: e.latlng.lat,
        lng: e.latlng.lng
      }));
    });

    // Map long press event (contextmenu)
    map.on('contextmenu', function(e) {
      FlutterChannel.postMessage(JSON.stringify({
        type: 'mapLongPress',
        lat: e.latlng.lat,
        lng: e.latlng.lng
      }));
    });

    // Clear all markers
    function clearMarkers() {
      Object.values(markers).forEach(marker => {
        map.removeLayer(marker);
      });
      markers = {};
    }

    // Add marker
    function addMarker(lat, lng, color, type, id) {
      try {
        var markerOptions = {
          radius: 10,
          fillColor: color,
          color: '#fff',
          weight: 2,
          opacity: 1,
          fillOpacity: 0.8
        };
        
        var marker;
        
        if (type === 'current') {
          // Current location marker - use circle marker
          marker = L.circleMarker([lat, lng], {
            radius: 8,
            fillColor: color,
            color: '#fff',
            weight: 3,
            opacity: 1,
            fillOpacity: 1
          });
        } else if (type === 'user') {
          // User location marker - larger circle with border
          marker = L.circleMarker([lat, lng], {
            radius: 12,
            fillColor: color,
            color: color,
            weight: 3,
            opacity: 0.6,
            fillOpacity: 0.8
          });
        } else {
          // Default marker
          marker = L.circleMarker([lat, lng], markerOptions);
        }
        
        marker.addTo(map);
        markers[id] = marker;
        
        // Add click event
        marker.on('click', function(e) {
          console.log('Marker clicked:', id);
          FlutterChannel.postMessage(JSON.stringify({
            type: 'markerClick',
            markerId: id,
            lat: lat,
            lng: lng
          }));
          L.DomEvent.stopPropagation(e);
        });
        
      } catch (error) {
        console.error('Error adding marker:', error);
      }
    }

    // Clear all polylines
    function clearPolylines() {
      Object.values(polylines).forEach(polyline => {
        map.removeLayer(polyline);
      });
      polylines = {};
    }

    // Add polyline
    function addPolyline(points, color, weight, id) {
      try {
        var polyline = L.polyline(points, {
          color: color,
          weight: weight,
          opacity: 0.7,
          lineJoin: 'round',
          lineCap: 'round'
        }).addTo(map);
        
        polylines[id] = polyline;
      } catch (error) {
        console.error('Error adding polyline:', error);
      }
    }

    // Move map to location
    function moveMap(lat, lng, zoom) {
      try {
        map.setView([lat, lng], zoom, {
          animate: true,
          duration: 0.5
        });
      } catch (error) {
        console.error('Error moving map:', error);
      }
    }

    // Fit bounds to show all markers and polylines
    function fitBounds() {
      try {
        var allLayers = Object.values(markers).concat(Object.values(polylines));
        
        if (allLayers.length > 0) {
          var group = L.featureGroup(allLayers);
          map.fitBounds(group.getBounds().pad(0.1), {
            animate: true,
            duration: 0.5
          });
        }
      } catch (error) {
        console.error('Error fitting bounds:', error);
      }
    }

    // Fit bounds with custom padding
    function fitBoundsWithPadding(padding) {
      try {
        var allLayers = Object.values(markers).concat(Object.values(polylines));
        
        if (allLayers.length > 0) {
          var group = L.featureGroup(allLayers);
          map.fitBounds(group.getBounds(), {
            padding: [padding, padding],
            animate: true,
            duration: 0.5
          });
        }
      } catch (error) {
        console.error('Error fitting bounds with padding:', error);
      }
    }

    // Get current map center
    function getCenter() {
      var center = map.getCenter();
      FlutterChannel.postMessage(JSON.stringify({
        type: 'centerResponse',
        lat: center.lat,
        lng: center.lng
      }));
    }

    // Get current map zoom
    function getZoom() {
      var zoom = map.getZoom();
      FlutterChannel.postMessage(JSON.stringify({
        type: 'zoomResponse',
        zoom: zoom
      }));
    }

    // Set map zoom
    function setZoom(zoom) {
      try {
        map.setZoom(zoom, {
          animate: true
        });
      } catch (error) {
        console.error('Error setting zoom:', error);
      }
    }

    console.log('Map script initialized');
  </script>
</body>
</html>
    ''';
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
    debugPrint('Disposing MapWebView');
    super.dispose();
  }
}

class MapWebViewController {
  WebViewController? _webViewController;

  void _setWebViewController(WebViewController controller) {
    _webViewController = controller;
  }

  /// Move map to specific location with optional zoom level
  Future<void> move(LatLng center, double zoom) async {
    if (_webViewController == null) {
      debugPrint('WebViewController not initialized');
      return;
    }

    try {
      await _webViewController!.runJavaScript('''
        moveMap(${center.latitude}, ${center.longitude}, $zoom);
      ''');
    } catch (e) {
      debugPrint('Error moving map: $e');
    }
  }

  /// Fit map bounds to show all markers and polylines
  Future<void> fitBounds() async {
    if (_webViewController == null) {
      debugPrint('WebViewController not initialized');
      return;
    }

    try {
      await _webViewController!.runJavaScript('fitBounds();');
    } catch (e) {
      debugPrint('Error fitting bounds: $e');
    }
  }

  /// Fit map bounds with custom padding
  Future<void> fitBoundsWithPadding(double padding) async {
    if (_webViewController == null) {
      debugPrint('WebViewController not initialized');
      return;
    }

    try {
      await _webViewController!.runJavaScript(
        'fitBoundsWithPadding($padding);',
      );
    } catch (e) {
      debugPrint('Error fitting bounds with padding: $e');
    }
  }

  /// Set map zoom level
  Future<void> setZoom(double zoom) async {
    if (_webViewController == null) {
      debugPrint('WebViewController not initialized');
      return;
    }

    try {
      await _webViewController!.runJavaScript('setZoom($zoom);');
    } catch (e) {
      debugPrint('Error setting zoom: $e');
    }
  }

  /// Get current map center
  Future<LatLng?> getCenter() async {
    if (_webViewController == null) {
      debugPrint('WebViewController not initialized');
      return null;
    }

    try {
      await _webViewController!.runJavaScript('getCenter();');
      return null;
    } catch (e) {
      debugPrint('Error getting center: $e');
      return null;
    }
  }

  /// Get current map zoom level
  Future<double?> getZoom() async {
    if (_webViewController == null) {
      debugPrint('WebViewController not initialized');
      return null;
    }

    try {
      await _webViewController!.runJavaScript('getZoom();');
      return null;
    } catch (e) {
      debugPrint('Error getting zoom: $e');
      return null;
    }
  }

  /// Execute custom JavaScript code
  Future<void> runJavaScript(String code) async {
    if (_webViewController == null) {
      debugPrint('WebViewController not initialized');
      return;
    }

    try {
      await _webViewController!.runJavaScript(code);
    } catch (e) {
      debugPrint('Error running JavaScript: $e');
    }
  }
}
