// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/app_snack_bar.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import '../services/user_location_handler.dart';
import '../models/user_location.dart';
import '../models/connection_status.dart';

class MockMapView extends StatefulWidget {
  const MockMapView({super.key});

  @override
  State<MockMapView> createState() => _MockMapViewState();
}

class _MockMapViewState extends State<MockMapView> {
  // Map and UI state
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  bool isLoadingUserLocations = true;
  bool isLoadingRoutes = false;
  bool _locationPermissionGranted = false;

  // Services
  final LocationService _locationService = LocationService();
  final RouteService _routeService = RouteService();
  final UserLocationHandler _userLocationHandler = UserLocationHandler();

  // Connection and user data
  bool _isConnected = false;
  String? _currentUserId;
  Map<String, UserLocation> _userLocations = {};
  List<String> _roomUsers = [];

  // Route display settings
  bool _showRoutes = false;
  List<RouteData> _currentRoutes = [];

  // Mock mode toggle
  bool _useMockData = true;
  LatLng? _mockCurrentLocation;

  // Stream subscriptions
  StreamSubscription<ConnectionStatus>? _connectionSubscription;
  StreamSubscription<Map<String, UserLocation>>? _allLocationsSubscription;
  StreamSubscription<UserLocation>? _locationUpdateSubscription;
  StreamSubscription<List<String>>? _roomUsersSubscription;
  StreamSubscription<String>? _errorSubscription;

  @override
  void initState() {
    super.initState();

    if (_useMockData) {
      _loadMockData();
    } else {
      _setupLocationServiceListeners();
      _checkConnectionStatus();
      _getCurrentLocation();
    }
  }

  void _loadMockData() {
    // Mock current user location (Mirpur 10)
    _mockCurrentLocation = LatLng(23.8069, 90.3686);
    _currentUserId = 'You';

    // Mock friend locations
    _userLocations = {
      'Moshiur': UserLocation(
        userId: 'Friend_Banani',
        latitude: 23.7937,
        longitude: 90.4066,
        timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      ),
      'Tushar': UserLocation(
        userId: 'Friend_Uttara',
        latitude: 23.8759,
        longitude: 90.3795,
        timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      ),
      'Fazly': UserLocation(
        userId: 'Friend_Dhanmondi',
        latitude: 23.7461,
        longitude: 90.3742,
        timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      ),
    };

    setState(() {
      _locationPermissionGranted = true;
      _isConnected = true;
      isLoadingUserLocations = false;
    });

    _updateUserMarkersForMock();

    // Auto-show all locations
    Future.delayed(Duration(milliseconds: 500), () {
      _showAllLocations();
    });
  }

  void _updateUserMarkersForMock() {
    List<Marker> markers = [];

    // Add current user marker
    if (_mockCurrentLocation != null) {
      markers.add(
        Marker(
          point: _mockCurrentLocation!,
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Your Location (Mirpur 10)'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Icon(Icons.location_on, color: Colors.blue, size: 40),
          ),
        ),
      );
    }

    // Add other user markers
    _userLocations.forEach((userId, userLocation) {
      markers.add(
        Marker(
          point: LatLng(userLocation.latitude, userLocation.longitude),
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () => _showUserInfo(userId, userLocation),
            child: Column(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 40),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    userId.replaceAll('Friend_', ''),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });

    setState(() {
      _markers = markers;
    });
  }

  void _setupLocationServiceListeners() {
    // Listen to connection status changes
    _connectionSubscription = _locationService.connectionStream.listen((
      connectionStatus,
    ) {
      if (mounted) {
        setState(() {
          _isConnected = connectionStatus.isConnected;
          _currentUserId = connectionStatus.userId;
          _roomUsers = connectionStatus.roomUsers;
        });

        if (!connectionStatus.isConnected) {
          AppSnackBars.showError(context, 'Disconnected from server');
        }
      }
    });

    // Listen to all locations updates
    _allLocationsSubscription = _locationService.allLocationsStream.listen((
      locations,
    ) {
      if (mounted) {
        setState(() {
          _userLocations = locations;
          isLoadingUserLocations = false;
        });
        _updateUserMarkers();

        // Update routes if they're currently shown
        if (_showRoutes && _getCurrentLocationForRoutes() != null) {
          _updateRoutes();
        }
      }
    });

    // Listen to individual location updates
    _locationUpdateSubscription = _locationService.locationUpdateStream.listen((
      location,
    ) {
      if (mounted) {
        AppSnackBars.showLocationReceived(
          context,
          location.userId,
          location.latitude,
          location.longitude,
          () {
            Navigator.of(context).pop();
            _focusOnUser(location);
          },
        );
      }
    });

    // Listen to room users changes
    _roomUsersSubscription = _locationService.roomUsersStream.listen((users) {
      if (mounted) {
        setState(() {
          _roomUsers = users;
        });
      }
    });

    // Listen to error messages
    _errorSubscription = _locationService.errorStream.listen((error) {
      if (mounted) {
        AppSnackBars.showError(context, error);
      }
    });
  }

  void _checkConnectionStatus() {
    setState(() {
      _isConnected = _locationService.isConnected;
      _currentUserId = _locationService.currentUserId;
      _roomUsers = _locationService.roomUsers;
      _userLocations = _locationService.userLocations;
    });

    if (_isConnected) {
      // Request all current locations
      _locationService.requestAllLocations();
    }
  }

  LatLng? _getCurrentLocationForRoutes() {
    if (_useMockData) {
      return _mockCurrentLocation;
    }
    return _userLocationHandler.currentLocation;
  }

  Future<void> _getCurrentLocation() async {
    final result = await _userLocationHandler.getCurrentLocation();

    if (mounted) {
      setState(() {
        _locationPermissionGranted = result.isSuccess;
      });

      if (!result.isSuccess && result.error != null) {
        AppSnackBars.showError(context, result.error!);
      }

      // Move camera to current location
      if (_userLocationHandler.currentLocation != null) {
        _mapController.move(_userLocationHandler.currentLocation!, 15.0);
      }

      // Update user markers
      _updateUserMarkers();
    }
  }

  void _updateUserMarkers() {
    try {
      final markers = _userLocationHandler.generateUserMarkers(
        userLocations: _userLocations,
        currentUserId: _currentUserId,
        hasLocationPermission: _locationPermissionGranted,
        onMarkerTap: _showUserInfo,
      );

      setState(() {
        _markers = markers;
      });

      // Show all locations on map if there are multiple users
      if (_userLocations.length > 1) {
        _showAllLocations();
      }
    } catch (e) {
      debugPrint('Error updating user markers: $e');

      AppSnackBars.showError(context, 'Error updating markers: $e');
    }
  }

  Future<void> _updateRoutes() async {
    final currentLocation = _getCurrentLocationForRoutes();

    if (!_showRoutes || currentLocation == null || _userLocations.isEmpty) {
      setState(() {
        _polylines.clear();
        _currentRoutes.clear();
      });
      return;
    }

    setState(() {
      isLoadingRoutes = true;
    });

    try {
      final routes = await _routeService.generateRoutes(
        currentLocation: currentLocation,
        userLocations: _userLocations,
        currentUserId: _currentUserId,
      );

      // Convert routes to polylines
      final polylines =
          routes.map((route) {
            return Polyline(
              points: route.points,
              color: route.color,
              strokeWidth: route.strokeWidth,
            );
          }).toList();

      setState(() {
        _polylines = polylines;
        _currentRoutes = routes;
        isLoadingRoutes = false;
      });
    } catch (e) {
      debugPrint('Error updating routes: $e');
      setState(() {
        isLoadingRoutes = false;
      });

      AppSnackBars.showError(context, 'Error loading routes: $e');
    }
  }

  void _showUserInfo(String userId, UserLocation userLocation) {
    final currentLocation = _getCurrentLocationForRoutes();

    if (currentLocation == null) {
      // Just show basic user info
      _showUserBasicInfo(userId, userLocation);
      return;
    }

    final routeInfo = _routeService.getRouteInfo(
      userId: userId,
      userLocation: userLocation,
      currentLocation: currentLocation,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.person, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text('User: $userId'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'Location',
                  '${userLocation.latitude.toStringAsFixed(6)}, ${userLocation.longitude.toStringAsFixed(6)}',
                ),
                _buildInfoRow('Last Updated', routeInfo.lastUpdated),
                _buildInfoRow('Direct Distance', routeInfo.directDistance),
                if (_showRoutes) ...[
                  const Divider(),
                  _buildInfoRow('Travel Mode', routeInfo.travelMode),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _focusOnUser(userLocation);
                },
                child: const Text('Focus on Map'),
              ),
            ],
          ),
    );
  }

  void _showUserBasicInfo(String userId, UserLocation userLocation) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.person, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text('User: $userId'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'Location',
                  '${userLocation.latitude.toStringAsFixed(6)}, ${userLocation.longitude.toStringAsFixed(6)}',
                ),
                _buildInfoRow(
                  'Last Updated',
                  _useMockData
                      ? DateTime.now().toString().substring(11, 19)
                      : _userLocationHandler.formatTimestamp(
                        userLocation.timestamp,
                      ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _focusOnUser(userLocation);
                },
                child: const Text('Focus on Map'),
              ),
            ],
          ),
    );
  }

  void _toggleRoutes() {
    setState(() {
      _showRoutes = !_showRoutes;
    });

    if (_showRoutes) {
      _updateRoutes();
    } else {
      setState(() {
        _polylines.clear();
        _currentRoutes.clear();
      });
    }
  }

  void _showRoutesSettings() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Route Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Travel Mode:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...['driving', 'walking', 'cycling'].map(
                  (mode) => RadioListTile<String>(
                    title: Text(mode.toUpperCase()),
                    value: mode,
                    groupValue: _routeService.routeMode,
                    onChanged: (value) {
                      setState(() {
                        _routeService.setRouteMode(value!);
                      });
                      if (_showRoutes) {
                        _updateRoutes();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Show Routes To:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('All Users'),
                  value: _routeService.selectedUsers.isEmpty,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _routeService.clearSelectedUsers();
                      } else {
                        _routeService.setSelectedUsers(
                          _userLocations.keys
                              .where((userId) => userId != _currentUserId)
                              .toList(),
                        );
                      }
                    });
                    if (_showRoutes) {
                      _updateRoutes();
                    }
                  },
                ),
                ..._userLocations.keys
                    .where((userId) => userId != _currentUserId)
                    .map(
                      (userId) => CheckboxListTile(
                        title: Text(userId),
                        value:
                            _routeService.selectedUsers.isEmpty ||
                            _routeService.selectedUsers.contains(userId),
                        onChanged:
                            _routeService.selectedUsers.isEmpty
                                ? null
                                : (value) {
                                  setState(() {
                                    if (value == true) {
                                      _routeService.addSelectedUser(userId);
                                    } else {
                                      _routeService.removeSelectedUser(userId);
                                    }
                                  });
                                  if (_showRoutes) {
                                    _updateRoutes();
                                  }
                                },
                      ),
                    ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }

  void _focusOnUser(UserLocation userLocation) {
    if (_useMockData) {
      _mapController.move(
        LatLng(userLocation.latitude, userLocation.longitude),
        16.0,
      );
    } else {
      final focusLocation = _userLocationHandler.getFocusLocationForUser(
        userLocation,
      );
      _mapController.move(focusLocation, 16.0);
    }
  }

  void _showAllLocations() {
    if (_useMockData && _mockCurrentLocation != null) {
      // Calculate bounds for mock data
      double minLat = _mockCurrentLocation!.latitude;
      double maxLat = _mockCurrentLocation!.latitude;
      double minLng = _mockCurrentLocation!.longitude;
      double maxLng = _mockCurrentLocation!.longitude;

      for (var location in _userLocations.values) {
        if (location.latitude < minLat) minLat = location.latitude;
        if (location.latitude > maxLat) maxLat = location.latitude;
        if (location.longitude < minLng) minLng = location.longitude;
        if (location.longitude > maxLng) maxLng = location.longitude;
      }

      final bounds = LatLngBounds(
        LatLng(minLat, minLng),
        LatLng(maxLat, maxLng),
      );

      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    } else {
      final bounds = _userLocationHandler.calculateBoundsForAllLocations(
        userLocations: _userLocations,
      );

      if (bounds != null) {
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
        );
      } else if (_userLocationHandler.currentLocation != null) {
        _mapController.move(_userLocationHandler.currentLocation!, 15.0);
      }
    }
  }

  void _refreshData() async {
    if (_useMockData) {
      _loadMockData();
      return;
    }

    // Refresh current location
    await _getCurrentLocation();

    // Request fresh user locations from server
    if (_isConnected) {
      _locationService.requestAllLocations();
    }

    setState(() {
      isLoadingUserLocations = false;
    });
  }

  @override
  void dispose() {
    // Cancel stream subscriptions
    _connectionSubscription?.cancel();
    _allLocationsSubscription?.cancel();
    _locationUpdateSubscription?.cancel();
    _roomUsersSubscription?.cancel();
    _errorSubscription?.cancel();

    // Dispose services
    _routeService.dispose();
    _userLocationHandler.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = _getCurrentLocationForRoutes();

    return Scaffold(
      appBar: AppBar(
        title: Text('Map View'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          // Routes toggle button
          IconButton(
            onPressed: _userLocations.isNotEmpty ? _toggleRoutes : null,
            icon: Icon(_showRoutes ? Icons.route : Icons.route_outlined),
            tooltip: _showRoutes ? 'Hide Routes' : 'Show Routes',
          ),
          // Routes settings
          if (_showRoutes)
            IconButton(
              onPressed: _showRoutesSettings,
              icon: const Icon(Icons.settings),
              tooltip: 'Route Settings',
            ),
        ],
      ),
      body:
          currentLocation == null && !_useMockData
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.blue.shade600,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Loading map...',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!_isConnected) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Not connected to server',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              )
              : Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter:
                          currentLocation ?? LatLng(23.8069, 90.3686),
                      initialZoom: 15.0,
                      minZoom: 3.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      // OpenStreetMap Tile Layer
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                        maxZoom: 18,
                      ),
                      // Polyline Layer for routes
                      if (_polylines.isNotEmpty)
                        PolylineLayer(polylines: _polylines),
                      // Marker Layer
                      if (_markers.isNotEmpty) MarkerLayer(markers: _markers),
                    ],
                  ),

                  // User count overlay
                  if (_isConnected && _userLocations.isNotEmpty)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_userLocations.length + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Routes loading indicator
                  if (isLoadingRoutes)
                    Positioned(
                      top: _useMockData ? 60 : 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Loading Routes...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Route info overlay
                  if (_showRoutes && _polylines.isNotEmpty)
                    Positioned(
                      bottom: 100,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.route,
                                  size: 16,
                                  color: Colors.blue.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_polylines.length} Routes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _routeService.routeMode.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Show all locations button
          if (_userLocations.isNotEmpty)
            FloatingActionButton(
              heroTag: "show_all_locations",
              mini: true,
              shape: const CircleBorder(),
              onPressed: _showAllLocations,
              backgroundColor: Colors.purple.shade600,
              tooltip: 'Show All Locations',
              child: const Icon(
                Icons.zoom_out_map,
                color: Colors.white,
                size: 20,
              ),
            ),
          const SizedBox(height: 10),
          // Refresh data button
          FloatingActionButton(
            heroTag: "refresh_data",
            mini: true,
            shape: const CircleBorder(),
            onPressed: _refreshData,
            backgroundColor: Colors.blue.shade600,
            tooltip: 'Refresh Data',
            child: const Icon(Icons.refresh, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          // Refresh current location button
          FloatingActionButton(
            heroTag: "refresh_current_location",
            shape: const CircleBorder(),
            onPressed: _useMockData ? _loadMockData : _getCurrentLocation,
            backgroundColor: Colors.green.shade600,
            tooltip: 'Refresh My Location',
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
