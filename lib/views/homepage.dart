import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../widgets/app_snack_bar.dart';
import '../app_theme.dart';
import '../models/route_data.dart';
import '../views/map_webview.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import '../services/user_location_handler.dart';
import '../models/user_location.dart';
import '../models/connection_status.dart';
import '../widgets/interactive_pane.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final MapWebViewController _mapController = MapWebViewController();
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  bool isLoadingUserLocations = true;
  bool isLoadingRoutes = false;
  bool _locationPermissionGranted = false;

  // Store marker index to user mapping for click handling
  Map<int, MapEntry<String, UserLocation>> _markerIndexMap = {};

  // Services
  final LocationService _locationService = LocationService();
  final RouteService _routeService = RouteService();
  final UserLocationHandler _userLocationHandler = UserLocationHandler();

  // InteractivePane state
  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  bool _isConnecting = false;
  bool _isExpanded = true;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Connection and user data
  bool _isConnected = false;
  String? _currentUserId;
  Map<String, UserLocation> _userLocations = {};
  List<String> _roomUsers = [];

  // Route display settings
  bool _showRoutes = false;
  List<RouteData> _currentRoutes = [];

  // Stream subscriptions
  StreamSubscription<ConnectionStatus>? _connectionSubscription;
  StreamSubscription<Map<String, UserLocation>>? _allLocationsSubscription;
  StreamSubscription<UserLocation>? _locationUpdateSubscription;
  StreamSubscription<List<String>>? _roomUsersSubscription;
  StreamSubscription<String>? _errorSubscription;

  @override
  void initState() {
    super.initState();
    _setupLocationServiceListeners();
    _checkConnectionStatus();
    _getCurrentLocation();
  }

  void _setupLocationServiceListeners() {
    _connectionSubscription = _locationService.connectionStream.listen((
      status,
    ) {
      if (mounted) {
        setState(() {
          _isConnected = status.isConnected;
          _currentUserId = status.userId;
          _roomUsers = status.roomUsers;
        });

        if (!status.isConnected) {
          AppSnackBar.showError(context, 'Disconnected from server');
        }
      }
    });

    _allLocationsSubscription = _locationService.allLocationsStream.listen((
      locations,
    ) {
      if (mounted) {
        setState(() {
          _userLocations = locations;
          isLoadingUserLocations = false;
        });
        _updateUserMarkers();

        if (_showRoutes && _userLocationHandler.currentLocation != null) {
          _updateRoutes();
        }
      }
    });

    _locationUpdateSubscription = _locationService.locationUpdateStream.listen((
      location,
    ) {
      if (mounted) {
        AppSnackBar.showLocationUpdate(context, location.userId);
      }
    });

    _roomUsersSubscription = _locationService.roomUsersStream.listen((users) {
      if (mounted) {
        setState(() => _roomUsers = users);
      }
    });

    _errorSubscription = _locationService.errorStream.listen((error) {
      if (mounted) {
        AppSnackBar.showError(context, error);
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
      _locationService.requestAllLocations();
    }
  }

  Future<void> _getCurrentLocation() async {
    final result = await _userLocationHandler.getCurrentLocation();

    if (mounted) {
      setState(() => _locationPermissionGranted = result.isSuccess);

      if (!result.isSuccess && result.error != null) {
        AppSnackBar.showError(context, result.error!);
      }

      if (_userLocationHandler.currentLocation != null) {
        _mapController.move(_userLocationHandler.currentLocation!, 15.0);
      }

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

      // Create index map for marker clicks
      Map<int, MapEntry<String, UserLocation>> indexMap = {};
      int markerIndex = 0;

      // First marker is current user
      if (_locationPermissionGranted) {
        markerIndex++;
      }

      // Add mappings for other user markers
      _userLocations.forEach((userId, userLocation) {
        indexMap[markerIndex] = MapEntry(userId, userLocation);
        markerIndex++;
      });

      setState(() {
        _markers = markers;
        _markerIndexMap = indexMap;
      });

      if (_userLocations.length > 1) {
        _showAllLocations();
      }
    } catch (e) {
      debugPrint('Error updating user markers: $e');
      AppSnackBar.showError(context, 'Error updating markers: $e');
    }
  }

  Future<void> _updateRoutes() async {
    if (!_showRoutes ||
        _userLocationHandler.currentLocation == null ||
        _userLocations.isEmpty) {
      setState(() {
        _polylines.clear();
        _currentRoutes.clear();
      });
      return;
    }

    setState(() => isLoadingRoutes = true);

    try {
      final routes = await _routeService.generateRoutes(
        currentLocation: _userLocationHandler.currentLocation!,
        userLocations: _userLocations,
        currentUserId: _currentUserId,
      );

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
      setState(() => isLoadingRoutes = false);
      AppSnackBar.showError(context, 'Error loading routes: $e');
    }
  }

  void _showUserInfo(String userId, UserLocation userLocation) {
    if (_userLocationHandler.currentLocation == null) {
      _showUserBasicInfo(userId, userLocation);
      return;
    }

    final routeInfo = _routeService.getRouteInfo(
      userId: userId,
      userLocation: userLocation,
      currentLocation: _userLocationHandler.currentLocation!,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            title: Row(
              children: [
                Icon(Icons.person, color: AppTheme.infoBlue),
                SizedBox(width: AppTheme.spacingSmall),
                Text(
                  'User: $userId',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                  Divider(color: AppTheme.gray200),
                  _buildInfoRow('Travel Mode', routeInfo.travelMode),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: AppTheme.textGray),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _focusOnUser(userLocation);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: AppTheme.cardWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
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
            backgroundColor: AppTheme.cardWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            title: Row(
              children: [
                Icon(Icons.person, color: AppTheme.infoBlue),
                SizedBox(width: AppTheme.spacingSmall),
                Text(
                  'User: $userId',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                  _userLocationHandler.formatTimestamp(userLocation.timestamp),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: AppTheme.textGray),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _focusOnUser(userLocation);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: AppTheme.cardWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: const Text('Focus on Map'),
              ),
            ],
          ),
    );
  }

  void _toggleRoutes() {
    setState(() => _showRoutes = !_showRoutes);

    if (_showRoutes) {
      _updateRoutes();
    } else {
      setState(() {
        _polylines.clear();
        _currentRoutes.clear();
      });
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: AppTheme.textGray)),
          ),
        ],
      ),
    );
  }

  void _focusOnUser(UserLocation userLocation) {
    final focusLocation = _userLocationHandler.getFocusLocationForUser(
      userLocation,
    );
    _mapController.move(focusLocation, 16.0);
  }

  void _showAllLocations() {
    _mapController.fitBoundsWithPadding(50.0);
  }

  void _refreshData() async {
    await _getCurrentLocation();

    if (_isConnected) {
      _locationService.requestAllLocations();
    }

    setState(() => isLoadingUserLocations = false);
  }

  // Handle marker clicks from WebView
  void _handleMarkerClick(int markerIndex) {
    debugPrint('Handling marker click for index: $markerIndex');

    final markerData = _markerIndexMap[markerIndex];
    if (markerData != null) {
      final userId = markerData.key;
      final userLocation = markerData.value;
      debugPrint(
        'Found marker data: $userId at ${userLocation.latitude}, ${userLocation.longitude}',
      );
      _showUserInfo(userId, userLocation);
    } else {
      debugPrint('No marker data found for index: $markerIndex');
      // Check if it's the current user marker (index 0)
      if (markerIndex == 0 && _locationPermissionGranted) {
        AppSnackBar.showInfo(context, 'Your Current Location');
      }
    }
  }

  // InteractivePane handlers
  Future<void> _handleConnect() async {
    if (_serverUrlController.text.isEmpty ||
        _roomIdController.text.isEmpty ||
        _userIdController.text.isEmpty) {
      AppSnackBar.showWarning(context, 'Please fill all fields');
      return;
    }

    setState(() => _isConnecting = true);

    final success = await _locationService.connectToServer(
      serverUrl: _serverUrlController.text.trim(),
      roomId: _roomIdController.text.trim(),
      userId: _userIdController.text.trim(),
    );

    setState(() => _isConnecting = false);

    if (success) {
      AppSnackBar.showSuccess(context, 'Connected successfully!');
    }
  }

  Future<void> _handleDisconnect() async {
    await _locationService.disconnect();
  }

  Future<void> _handleSendLocation() async {
    if (_userLocationHandler.currentLocation != null) {
      final success = await _locationService.shareLocation(
        latitude: _userLocationHandler.currentLocation!.latitude,
        longitude: _userLocationHandler.currentLocation!.longitude,
      );

      if (success) {
        final sharedCount = _userLocations.length;
        AppSnackBar.showLocationSent(
          context,
          _userLocationHandler.currentLocation!.latitude,
          _userLocationHandler.currentLocation!.longitude,
          sharedCount,
        );
      }
    }
  }

  void _handleRouteModeChanged(String mode) {
    setState(() {
      _routeService.setRouteMode(mode);
      if (_showRoutes) {
        _updateRoutes();
      }
    });
  }

  // Handle route filter changes
  void _handleRouteFilterChanged() {
    setState(() {
      if (_showRoutes) {
        _updateRoutes();
      }
    });
  }

  // Handle page changes in InteractivePane
  void _handlePageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _allLocationsSubscription?.cancel();
    _locationUpdateSubscription?.cancel();
    _roomUsersSubscription?.cancel();
    _errorSubscription?.cancel();

    _serverUrlController.dispose();
    _roomIdController.dispose();
    _userIdController.dispose();

    _pageController.dispose();

    _routeService.dispose();
    _userLocationHandler.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Here We Go',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: AppTheme.spacingSmall),
            decoration: BoxDecoration(
              color: _showRoutes ? AppTheme.primaryGreen : AppTheme.cardWhite,
              shape: BoxShape.circle,
              boxShadow: [AppTheme.lightShadow],
            ),
            child: IconButton(
              onPressed: _userLocations.isNotEmpty ? _toggleRoutes : null,
              icon: Icon(
                _showRoutes ? Icons.route : Icons.route_outlined,
                color: _showRoutes ? AppTheme.cardWhite : AppTheme.textDark,
              ),
              tooltip: _showRoutes ? 'Hide Routes' : 'Show Routes',
            ),
          ),
        ],
      ),
      body:
          _userLocationHandler.isLoadingLocation ||
                  _userLocationHandler.currentLocation == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: AppTheme.spacingLarge - 4),
                    Text(
                      'Loading map...',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
              : Stack(
                children: [
                  MapWebView(
                    controller: _mapController,
                    initialCenter: _userLocationHandler.currentLocation!,
                    initialZoom: 15.0,
                    minZoom: 3.0,
                    maxZoom: 18.0,
                    markers: _markers,
                    polylines: _polylines,
                    onMarkerTap: (int markerIndex) {
                      debugPrint(
                        'MapWebView onMarkerTap called with index: $markerIndex',
                      );
                      _handleMarkerClick(markerIndex);
                    },
                  ),
                  InteractivePane(
                    locationService: _locationService,
                    routeService: _routeService,
                    currentLocation: _userLocationHandler.currentLocation,
                    onSendLocation: _handleSendLocation,
                    serverUrlController: _serverUrlController,
                    roomIdController: _roomIdController,
                    userIdController: _userIdController,
                    isConnecting: _isConnecting,
                    onConnect: _handleConnect,
                    onDisconnect: _handleDisconnect,
                    isExpanded: _isExpanded,
                    onToggleExpand:
                        () => setState(() => _isExpanded = !_isExpanded),
                    onRouteModeChanged: _handleRouteModeChanged,
                    onRouteFilterChanged: _handleRouteFilterChanged,
                    pageController: _pageController,
                    currentPage: _currentPage,
                    onPageChanged: _handlePageChanged,
                  ),

                  // Routes loading indicator
                  if (isLoadingRoutes)
                    Positioned(
                      top: AppTheme.spacingMedium,
                      left: AppTheme.spacingMedium,
                      child: Container(
                        padding: EdgeInsets.all(AppTheme.spacingSmall + 4),
                        decoration: BoxDecoration(
                          color: AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                          boxShadow: [AppTheme.lightShadow],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.infoBlue,
                              ),
                            ),
                            SizedBox(width: AppTheme.spacingSmall),
                            Text(
                              'Loading Routes...',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.infoBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_userLocations.isNotEmpty)
            FloatingActionButton(
              mini: true,
              shape: const CircleBorder(),
              onPressed: _showAllLocations,
              backgroundColor: AppTheme.primaryNavy,
              child: Icon(
                Icons.zoom_out_map,
                color: AppTheme.cardWhite,
                size: 20,
              ),
            ),
          SizedBox(height: AppTheme.spacingSmall + 2),
          FloatingActionButton(
            mini: true,
            shape: const CircleBorder(),
            onPressed: _refreshData,
            backgroundColor: AppTheme.infoBlue,
            child: Icon(Icons.refresh, color: AppTheme.cardWhite, size: 20),
          ),
          SizedBox(height: AppTheme.spacingSmall + 2),
          FloatingActionButton(
            shape: const CircleBorder(),
            onPressed: _getCurrentLocation,
            backgroundColor: AppTheme.primaryGreen,
            child: Icon(Icons.my_location, color: AppTheme.cardWhite),
          ),
        ],
      ),
    );
  }
}
