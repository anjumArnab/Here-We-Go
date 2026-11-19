import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../models/map_marker_data.dart';
import '../providers/chat_provider.dart';
import '../providers/connection_provider.dart';
import '../features/navigation/providers/navigation_provider.dart';
import '../shared/widgets/app_snack_bar.dart';
import '../features/navigation/widgets/navigation_metrics_panel.dart';
import '../core/theme/app_theme.dart';
import 'map_webview.dart';
import '../providers/location_provider.dart';
import '../features/routing/providers/route_provider.dart';
import '../providers/user_location_provider.dart';
import '../models/user_location.dart';
import '../widgets/home/chat_action_button.dart';
import '../widgets/home/info_row.dart';
import '../widgets/home/map_loading_view.dart';
import '../widgets/home/map_quick_actions.dart';
import '../widgets/home/route_toggle_button.dart';
import '../widgets/home/routes_loading_indicator.dart';
import '../widgets/home/user_info_dialog.dart';
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
    _setupNavigationListener();
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

  // Setup navigation state listener
  void _setupNavigationListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigationProvider = context.read<NavigationProvider>();
      final locationProvider = context.read<LocationProvider>();

      navigationProvider.addListener(() {
        if (!mounted) return;

        // Update routes when navigation state changes
        if (navigationProvider.isNavigating || navigationProvider.isRerouting) {
          _updateNavigationRoute();
        } else if (navigationProvider.isIdle) {
          // Navigation stopped, restore regular routes if enabled
          if (_showRoutes) {
            _updateRoutes();
          } else {
            setState(() {
              _polylines.clear();
            });
          }
        }

        // Show arrival notification
        if (navigationProvider.hasArrived) {
          AppSnackBar.showSuccess(context, 'You have arrived at destination!');
          navigationProvider.resetArrivalFlag();
        }

        // Show rerouting notification
        if (navigationProvider.isRerouting) {
          AppSnackBar.showInfo(context, 'Recalculating route...');
        }
      });

      // Listen to location updates for destination user
      locationProvider.addListener(() {
        if (!mounted) return;

        final navigationProvider = context.read<NavigationProvider>();
        if (!navigationProvider.isActive) return;

        // Check if destination user location updated
        final destinationUserId = navigationProvider.destinationUserId;
        if (destinationUserId != null) {
          final updatedLocation = locationProvider.getUserLocation(
            destinationUserId,
          );
          if (updatedLocation != null) {
            final currentDestination = navigationProvider.destination;

            // Check if destination moved more than 20 meters
            if (currentDestination != null) {
              final oldLat = currentDestination.latitude;
              final oldLng = currentDestination.longitude;
              final newLat = updatedLocation.latitude;
              final newLng = updatedLocation.longitude;

              final latDiff = (newLat - oldLat).abs();
              final lngDiff = (newLng - oldLng).abs();
              final moved =
                  (latDiff > 0.0002 || lngDiff > 0.0002); // around 20 meters

              if (moved) {
                navigationProvider.updateDestination(updatedLocation);
              }
            }
          }
        }
      });
    });
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
      final roomId = _roomIdController.text.trim();
      final userId = _userIdController.text.trim();

      locationProvider.initialize(roomId: roomId, userId: userId);
      chatProvider.initialize(roomId: roomId, userId: userId);
      AppSnackBar.showSuccess(context, 'Connected successfully!');
    }
  }

  Future<void> _handleDisconnect() async {
    final connectionProvider = context.read<ConnectionProvider>();
    final locationProvider = context.read<LocationProvider>();
    final chatProvider = context.read<ChatProvider>();
    final navigationProvider = context.read<NavigationProvider>();

    // Stop navigation if active
    if (navigationProvider.isActive) {
      await navigationProvider.stopNavigation();
    }

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

      // First marker is current user if location permission is granted
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

      // Only zoom on initial load
      if (!_hasInitializedMap && locationProvider.userLocations.length > 1) {
        _hasInitializedMap = true;
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            _showAllLocations();
          }
        });
      }
    } catch (e) {
      AppSnackBar.showError(context, 'Error updating markers: $e');
    }
  }

  // Update navigation route
  Future<void> _updateNavigationRoute() async {
    final navigationProvider = context.read<NavigationProvider>();

    if (!navigationProvider.isActive) {
      setState(() {
        _polylines.clear();
      });
      return;
    }

    final navRoute = navigationProvider.currentRoute;
    if (navRoute == null || navRoute.isEmpty) return;

    setState(() {
      _polylines = [
        Polyline(
          points: navRoute,
          color: AppTheme.navigationBlue,
          strokeWidth: 6.0,
        ),
      ];
    });
  }

  Future<void> _updateRoutes() async {
    final userLocationProvider = context.read<UserLocationProvider>();
    final locationProvider = context.read<LocationProvider>();
    final routeProvider = context.read<RouteProvider>();
    final connectionProvider = context.read<ConnectionProvider>();
    final navigationProvider = context.read<NavigationProvider>();

    // If navigating, do not show regular routes
    if (navigationProvider.isActive) {
      return;
    }

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
    final navigationProvider = context.read<NavigationProvider>();

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
          (context) => UserInfoDialog(
            userId: userId,
            details: [
              InfoRow(
                label: 'Location',
                value:
                    '${userLocation.latitude.toStringAsFixed(6)}, ${userLocation.longitude.toStringAsFixed(6)}',
              ),
              InfoRow(label: 'Last Updated', value: routeInfo.lastUpdated),
              InfoRow(
                label: 'Direct Distance',
                value: routeInfo.directDistance,
              ),
              if (_showRoutes) ...[
                Divider(color: AppTheme.gray200),
                InfoRow(label: 'Travel Mode', value: routeInfo.travelMode),
              ],
            ],
            onNavigate:
                navigationProvider.isActive
                    ? null
                    : () => _startNavigation(userId, userLocation),
          ),
    );
  }

  // Start navigation to selected user
  Future<void> _startNavigation(String userId, UserLocation destination) async {
    final userLocationProvider = context.read<UserLocationProvider>();
    final navigationProvider = context.read<NavigationProvider>();

    if (userLocationProvider.currentLocation == null) {
      AppSnackBar.showError(context, 'Current location not available');
      return;
    }

    // Check location permission
    if (!userLocationProvider.locationPermissionGranted) {
      AppSnackBar.showError(
        context,
        'Location permission required for navigation',
      );
      return;
    }

    final success = await navigationProvider.startNavigation(
      destination: destination,
      currentLocation: userLocationProvider.currentLocation!,
      destinationUserId: userId,
    );

    if (mounted) {
      if (success) {
        userLocationProvider.startContinuousTracking(
          onLocationUpdate: (location) {
            // Update markers on each location update
            _updateUserMarkers();
            // Move camera to current location during navigation
            _mapController.move(location, 16.0, offsetY: 150);
          },
        );

        // Hide routes toggle if enabled
        if (_showRoutes) {
          setState(() {
            _showRoutes = false;
          });
        }

        // Update navigation route
        _updateNavigationRoute();

        AppSnackBar.showSuccess(context, 'Navigation started to $userId');
      } else {
        AppSnackBar.showError(context, 'Failed to start navigation');
      }
    }
  }

  // Stop navigation
  Future<void> _stopNavigation() async {
    final navigationProvider = context.read<NavigationProvider>();
    final userLocationProvider = context.read<UserLocationProvider>();

    await navigationProvider.stopNavigation();
    userLocationProvider.stopContinuousTracking();

    setState(() {
      _polylines.clear();
    });

    if (mounted) {
      AppSnackBar.showInfo(context, 'Navigation stopped');
    }
  }

  void _showUserBasicInfo(String userId, UserLocation userLocation) {
    final userLocationProvider = context.read<UserLocationProvider>();

    showDialog(
      context: context,
      builder:
          (context) => UserInfoDialog(
            userId: userId,
            details: [
              InfoRow(
                label: 'Location',
                value:
                    '${userLocation.latitude.toStringAsFixed(6)}, ${userLocation.longitude.toStringAsFixed(6)}',
              ),
              InfoRow(
                label: 'Last Updated',
                value: userLocationProvider.formatTimestamp(
                  userLocation.timestamp,
                ),
              ),
            ],
          ),
    );
  }

  void _toggleRoutes() {
    final navigationProvider = context.read<NavigationProvider>();

    // Stop route toggle during navigation
    if (navigationProvider.isActive) {
      AppSnackBar.showWarning(context, 'Routes disabled during navigation');
      return;
    }

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
    final markerData = _markerIndexMap[markerIndex];
    if (markerData != null) {
      final userId = markerData.key;
      final userLocation = markerData.value;
      _showUserInfo(userId, userLocation);
    } else {
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
          const ChatActionButton(),
          RouteToggleButton(showRoutes: _showRoutes, onToggle: _toggleRoutes),
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
            return const MapLoadingView();
          }

          return SafeArea(
            child: Stack(
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
                    _handleMarkerClick(markerIndex);
                  },
                ),

                // Navigation metrics panel
                Consumer<NavigationProvider>(
                  builder: (context, navigationProvider, _) {
                    if (!navigationProvider.isActive) return SizedBox.shrink();

                    return Positioned(
                      top: AppTheme.position,
                      left: AppTheme.position,
                      right: AppTheme.position,
                      child: NavigationMetricsPanel(
                        metrics: navigationProvider.metrics,
                        isRerouting: navigationProvider.isRerouting,
                        destinationUserId: navigationProvider.destinationUserId,
                        onRouteModeChanged: _handleRouteModeChanged,
                        onStop: _stopNavigation,
                        onRecenter: () {
                          if (userLocationProvider.currentLocation != null) {
                            _mapController.move(
                              userLocationProvider.currentLocation!,
                              16.0,
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: InteractivePane(
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
                    pageController: _pageController,
                    currentPage: _currentPage,
                    onPageChanged: _handlePageChanged,
                  ),
                ),
                const RoutesLoadingIndicator(),

                MapQuickActions(
                  onShowAll: _showAllLocations,
                  onRefresh: _refreshData,
                  onMyLocation: _getCurrentLocation,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
