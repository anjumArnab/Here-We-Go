import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../models/map_marker_data.dart';
import '../providers/chat_provider.dart';
import '../providers/connection_provider.dart';
import '../views/chat_page.dart';
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
  List<MapMarkerData> _markers = [];
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

  // Prevents zoom reset on updates
  bool _hasInitializedMap = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final connectionProvider = context.read<ConnectionProvider>();

    // Get current location
    await _getCurrentLocation();

    // Check if already connected
    if (connectionProvider.isConnected) {
      context.read<LocationProvider>().requestAllLocations();
    }
  }

  Future<void> _handleConnect() async {
    final connectionProvider = context.read<ConnectionProvider>();
    final locationProvider = context.read<LocationProvider>();
    final chatProvider = context.read<ChatProvider>();

    if (_serverUrlController.text.isEmpty ||
        _roomIdController.text.isEmpty ||
        _userIdController.text.isEmpty) {
      AppSnackBar.showWarning(context, 'Please fill all fields');
      return;
    }

    final success = await connectionProvider.connectToServer(
      serverUrl: _serverUrlController.text.trim(),
      roomId: _roomIdController.text.trim(),
      userId: _userIdController.text.trim(),
    );

    if (mounted && success) {
      // Get socket from ConnectionProvider
      final socket = connectionProvider.socket;
      if (socket != null) {
        // Initialize LocationProvider
        locationProvider.initialize(
          socket: socket,
          roomId: _roomIdController.text.trim(),
          userId: _userIdController.text.trim(),
        );

        // Initialize ChatProvider
        chatProvider.initialize(
          socket: socket,
          roomId: _roomIdController.text.trim(),
          userId: _userIdController.text.trim(),
        );
      }
      AppSnackBar.showSuccess(context, 'Connected successfully!');
    }
  }

  Future<void> _handleDisconnect() async {
    final connectionProvider = context.read<ConnectionProvider>();
    final locationProvider = context.read<LocationProvider>();
    final chatProvider = context.read<ChatProvider>();

    await connectionProvider.disconnect();
    locationProvider.reset();
    chatProvider.reset();

    setState(() {
      _hasInitializedMap = false;
    });
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
    final connectionProvider = context.read<ConnectionProvider>();

    try {
      final markers = userLocationProvider.generateUserMarkerData(
        userLocations: locationProvider.userLocations,
        currentUserId: connectionProvider.currentUserId,
      );

      // Create index map for marker clicks
      Map<int, MapEntry<String, UserLocation>> indexMap = {};
      int markerIndex = 0;

      // First marker is current user (if location permission granted)
      if (userLocationProvider.locationPermissionGranted) {
        markerIndex++;
      }

      // Add mappings for other user markers
      locationProvider.userLocations.forEach((userId, userLocation) {
        if (userId != connectionProvider.currentUserId) {
          indexMap[markerIndex] = MapEntry(userId, userLocation);
          markerIndex++;
        }
      });

      setState(() {
        _markers = markers;
        _markerIndexMap = indexMap;
      });

      // Auto zoom: Only on initial load with multiple users
      if (!_hasInitializedMap && locationProvider.userLocations.length > 1) {
        _hasInitializedMap = true;
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            _showAllLocations();
          }
        });
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
    final connectionProvider = context.read<ConnectionProvider>();

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
      currentUserId: connectionProvider.currentUserId,
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
                  'Friend: $userId',
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
    final connectionProvider = context.read<ConnectionProvider>();
    final locationProvider = context.read<LocationProvider>();

    await _getCurrentLocation();

    if (connectionProvider.isConnected) {
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
          // Chat button with badge
          Consumer2<ConnectionProvider, ChatProvider>(
            builder: (context, connectionProvider, chatProvider, _) {
              return Container(
                margin: EdgeInsets.only(right: AppTheme.spacingSmall),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  shape: BoxShape.circle,
                  boxShadow: [AppTheme.lightShadow],
                ),
                child: Badge(
                  isLabelVisible: chatProvider.unreadCount > 0,
                  label: Text('${chatProvider.unreadCount}'),
                  child: IconButton(
                    onPressed:
                        connectionProvider.isConnected
                            ? () {
                              chatProvider.clearUnreadCount();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ChatPage(),
                                ),
                              );
                            }
                            : null,
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      color:
                          connectionProvider.isConnected
                              ? AppTheme.textDark
                              : AppTheme.gray300,
                    ),
                    tooltip: 'Chat',
                  ),
                ),
              );
            },
          ),
          // Route toggle button
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
      body: Consumer3<
        UserLocationProvider,
        LocationProvider,
        ConnectionProvider
      >(
        builder: (
          context,
          userLocationProvider,
          locationProvider,
          connectionProvider,
          _,
        ) {
          // Show errors if any
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (connectionProvider.lastError != null) {
              AppSnackBar.showError(context, connectionProvider.lastError!);
              connectionProvider.clearLastError();
            }

            if (locationProvider.lastError != null) {
              AppSnackBar.showError(context, locationProvider.lastError!);
              locationProvider.clearLastError();
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
              : Consumer<ConnectionProvider>(
                builder: (context, connectionProvider, _) {
                  final locationProvider = context.read<LocationProvider>();
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (locationProvider.userLocations.isNotEmpty)
                        FloatingActionButton(
                          mini: true,
                          shape: const CircleBorder(),
                          onPressed: () {
                            _hasInitializedMap = true;
                            _showAllLocations();
                          },
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
