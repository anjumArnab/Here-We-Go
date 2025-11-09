import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../widgets/app_snack_bar.dart';
import '../app_theme.dart';
import '../views/map_webview.dart';
import '../providers/location_provider.dart';
import '../providers/route_provider.dart';
import '../providers/user_location_provider.dart';
import '../models/user_location.dart';
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

  // Store marker index to user mapping for click handling
  Map<int, MapEntry<String, UserLocation>> _markerIndexMap = {};

  // InteractivePane state
  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  bool _isExpanded = true;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Route display settings
  bool _showRoutes = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final locationProvider = context.read<LocationProvider>();

    // Get current location
    await _getCurrentLocation();

    // Check if already connected
    if (locationProvider.isConnected) {
      locationProvider.requestAllLocations();
    }
  }

  Future<void> _getCurrentLocation() async {
    final userLocationProvider = context.read<UserLocationProvider>();
    final result = await userLocationProvider.getCurrentLocation();

    if (mounted) {
      if (!result.isSuccess && result.error != null) {
        AppSnackBar.showError(context, result.error!);
      }

      if (userLocationProvider.currentLocation != null) {
        _mapController.move(userLocationProvider.currentLocation!, 15.0);
      }

      _updateUserMarkers();
    }
  }

  void _updateUserMarkers() {
    final userLocationProvider = context.read<UserLocationProvider>();
    final locationProvider = context.read<LocationProvider>();

    try {
      final markers = userLocationProvider.generateUserMarkers(
        userLocations: locationProvider.userLocations,
        currentUserId: locationProvider.currentUserId,
        onMarkerTap: _showUserInfo,
      );

      // Create index map for marker clicks
      Map<int, MapEntry<String, UserLocation>> indexMap = {};
      int markerIndex = 0;

      // First marker is current user
      if (userLocationProvider.locationPermissionGranted) {
        markerIndex++;
      }

      // Add mappings for other user markers
      locationProvider.userLocations.forEach((userId, userLocation) {
        if (userId != locationProvider.currentUserId) {
          indexMap[markerIndex] = MapEntry(userId, userLocation);
          markerIndex++;
        }
      });

      setState(() {
        _markers = markers;
        _markerIndexMap = indexMap;
      });

      if (locationProvider.userLocations.length > 1) {
        _showAllLocations();
      }
    } catch (e) {
      debugPrint('Error updating user markers: $e');
      AppSnackBar.showError(context, 'Error updating markers: $e');
    }
  }

  Future<void> _updateRoutes() async {
    final userLocationProvider = context.read<UserLocationProvider>();
    final locationProvider = context.read<LocationProvider>();
    final routeProvider = context.read<RouteProvider>();

    if (!_showRoutes ||
        userLocationProvider.currentLocation == null ||
        locationProvider.userLocations.isEmpty) {
      setState(() {
        _polylines.clear();
      });
      routeProvider.clearRoutes();
      return;
    }

    await routeProvider.generateRoutes(
      currentLocation: userLocationProvider.currentLocation!,
      userLocations: locationProvider.userLocations,
      currentUserId: locationProvider.currentUserId,
    );

    if (mounted) {
      final polylines =
          routeProvider.currentRoutes.map((route) {
            return Polyline(
              points: route.points,
              color: route.color,
              strokeWidth: route.strokeWidth,
            );
          }).toList();

      setState(() {
        _polylines = polylines;
      });
    }
  }

  void _showUserInfo(String userId, UserLocation userLocation) {
    final userLocationProvider = context.read<UserLocationProvider>();
    final routeProvider = context.read<RouteProvider>();

    if (userLocationProvider.currentLocation == null) {
      _showUserBasicInfo(userId, userLocation);
      return;
    }

    final routeInfo = routeProvider.getRouteInfo(
      userId: userId,
      userLocation: userLocation,
      currentLocation: userLocationProvider.currentLocation!,
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
    final userLocationProvider = context.read<UserLocationProvider>();

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
                  userLocationProvider.formatTimestamp(userLocation.timestamp),
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
      });
      context.read<RouteProvider>().clearRoutes();
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
    final userLocationProvider = context.read<UserLocationProvider>();
    final focusLocation = userLocationProvider.getFocusLocationForUser(
      userLocation,
    );
    _mapController.move(focusLocation, 16.0);
  }

  void _showAllLocations() {
    _mapController.fitBoundsWithPadding(50.0);
  }

  void _refreshData() async {
    final locationProvider = context.read<LocationProvider>();

    await _getCurrentLocation();

    if (locationProvider.isConnected) {
      locationProvider.requestAllLocations();
    }
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
      final userLocationProvider = context.read<UserLocationProvider>();
      // Check if it's the current user marker (index 0)
      if (markerIndex == 0 && userLocationProvider.locationPermissionGranted) {
        AppSnackBar.showInfo(context, 'Your Current Location');
      }
    }
  }

  // InteractivePane handlers
  Future<void> _handleConnect() async {
    final locationProvider = context.read<LocationProvider>();

    if (_serverUrlController.text.isEmpty ||
        _roomIdController.text.isEmpty ||
        _userIdController.text.isEmpty) {
      AppSnackBar.showWarning(context, 'Please fill all fields');
      return;
    }

    final success = await locationProvider.connectToServer(
      serverUrl: _serverUrlController.text.trim(),
      roomId: _roomIdController.text.trim(),
      userId: _userIdController.text.trim(),
    );

    if (mounted) {
      if (success) {
        AppSnackBar.showSuccess(context, 'Connected successfully!');
      }
    }
  }

  Future<void> _handleDisconnect() async {
    final locationProvider = context.read<LocationProvider>();
    await locationProvider.disconnect();
  }

  Future<void> _handleSendLocation() async {
    final userLocationProvider = context.read<UserLocationProvider>();
    final locationProvider = context.read<LocationProvider>();

    if (userLocationProvider.currentLocation != null) {
      final success = await locationProvider.shareLocation(
        latitude: userLocationProvider.currentLocation!.latitude,
        longitude: userLocationProvider.currentLocation!.longitude,
      );

      if (mounted && success) {
        final sharedCount = locationProvider.userLocations.length;
        AppSnackBar.showLocationSent(
          context,
          userLocationProvider.currentLocation!.latitude,
          userLocationProvider.currentLocation!.longitude,
          sharedCount,
        );
      }
    }
  }

  void _handleRouteModeChanged(String mode) {
    final routeProvider = context.read<RouteProvider>();
    routeProvider.setRouteMode(mode);
    if (_showRoutes) {
      _updateRoutes();
    }
  }

  // Handle route filter changes
  void _handleRouteFilterChanged() {
    if (_showRoutes) {
      _updateRoutes();
    }
  }

  // Handle page changes in InteractivePane
  void _handlePageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _roomIdController.dispose();
    _userIdController.dispose();
    _pageController.dispose();
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
          Consumer<LocationProvider>(
            builder: (context, locationProvider, _) {
              final hasUsers = locationProvider.userLocations.isNotEmpty;
              return Container(
                margin: EdgeInsets.only(right: AppTheme.spacingSmall),
                decoration: BoxDecoration(
                  color:
                      _showRoutes ? AppTheme.primaryGreen : AppTheme.cardWhite,
                  shape: BoxShape.circle,
                  boxShadow: [AppTheme.lightShadow],
                ),
                child: IconButton(
                  onPressed: hasUsers ? _toggleRoutes : null,
                  icon: Icon(
                    _showRoutes ? Icons.route : Icons.route_outlined,
                    color: _showRoutes ? AppTheme.cardWhite : AppTheme.textDark,
                  ),
                  tooltip: _showRoutes ? 'Hide Routes' : 'Show Routes',
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer2<UserLocationProvider, LocationProvider>(
        builder: (context, userLocationProvider, locationProvider, _) {
          // Show errors if any
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (locationProvider.lastError != null) {
              AppSnackBar.showError(context, locationProvider.lastError!);
              locationProvider.clearLastError();
            }

            if (locationProvider.lastLocationUpdate != null) {
              AppSnackBar.showLocationUpdate(
                context,
                locationProvider.lastLocationUpdate!.userId,
              );
              locationProvider.clearLastLocationUpdate();
            }
          });

          // Update markers when data changes
          if (!userLocationProvider.isLoadingLocation) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateUserMarkers();
            });
          }

          if (userLocationProvider.isLoadingLocation ||
              userLocationProvider.currentLocation == null) {
            return Center(
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
            );
          }

          return Stack(
            children: [
              MapWebView(
                controller: _mapController,
                initialCenter: userLocationProvider.currentLocation!,
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
                currentLocation: userLocationProvider.currentLocation,
                onSendLocation: _handleSendLocation,
                serverUrlController: _serverUrlController,
                roomIdController: _roomIdController,
                userIdController: _userIdController,
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
              Consumer<RouteProvider>(
                builder: (context, routeProvider, _) {
                  if (!routeProvider.isLoadingRoutes) return SizedBox.shrink();

                  return Positioned(
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
                  );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton:
          _isExpanded
              ? null
              : Consumer<LocationProvider>(
                builder: (context, locationProvider, _) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (locationProvider.userLocations.isNotEmpty)
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
                        child: Icon(
                          Icons.refresh,
                          color: AppTheme.cardWhite,
                          size: 20,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingSmall + 2),
                      FloatingActionButton(
                        shape: const CircleBorder(),
                        onPressed: _getCurrentLocation,
                        backgroundColor: AppTheme.primaryGreen,
                        child: Icon(
                          Icons.my_location,
                          color: AppTheme.cardWhite,
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }
}
