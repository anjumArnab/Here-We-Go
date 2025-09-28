// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isLoading = true;
  String? _errorMessage;
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestLocationAndSetupMap();
  }

  Future<void> _requestLocationAndSetupMap() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage =
              'Location services are disabled. Please enable location services.';
          _isLoading = false;
        });
        _setDefaultLocation();
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage =
                'Location permission denied. Showing default location.';
            _isLoading = false;
          });
          _setDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              'Location permission permanently denied. Please enable in settings.';
          _isLoading = false;
        });
        _setDefaultLocation();
        return;
      }

      // Permission granted, get current location
      _locationPermissionGranted = true;
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
        _errorMessage = null;
      });

      // Center map on user location with smooth animation
      _mapController.move(_currentLocation!, 15.0);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get location: ${e.toString()}';
        _isLoading = false;
      });
      _setDefaultLocation();
    }
  }

  void _setDefaultLocation() {
    // Set a default location (London, UK) when location access fails
    setState(() {
      _currentLocation = const LatLng(51.5074, -0.1278);
      _isLoading = false;
    });
  }

  Future<void> _retryLocationRequest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _requestLocationAndSetupMap();
  }

  void _centerOnUserLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Stack(
        children: [
          // Map Widget
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? const LatLng(51.5074, -0.1278),
              initialZoom: _currentLocation != null ? 15.0 : 5.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // OpenStreetMap Tile Layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
                maxZoom: 18,
                subdomains: const ['a', 'b', 'c'],
              ),
              // Marker Layer
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              _locationPermissionGranted
                                  ? Colors.blue.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                _locationPermissionGranted
                                    ? Colors.blue
                                    : Colors.grey,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          _locationPermissionGranted
                              ? Icons.my_location
                              : Icons.location_on,
                          color:
                              _locationPermissionGranted
                                  ? Colors.blue
                                  : Colors.grey,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Loading Indicator
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Getting your location...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Error Message
          if (_errorMessage != null && !_isLoading)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.orange.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Location Notice',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                              });
                            },
                          ),
                        ],
                      ),
                      Text(_errorMessage!),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _retryLocationRequest,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton:
          _currentLocation != null
              ? FloatingActionButton(
                shape: CircleBorder(),
                backgroundColor:
                    _locationPermissionGranted ? Colors.blue : Colors.grey,
                onPressed: _centerOnUserLocation,
                tooltip: 'Center on my location',
                child: Icon(
                  _locationPermissionGranted
                      ? Icons.my_location
                      : Icons.location_on,
                ),
              )
              : null,
    );
  }
}
