import 'dart:async';
import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/navigation_state.dart';
import '../models/navigation_metrics.dart';
import '../models/user_location.dart';
import 'route_service.dart';

class NavigationService {
  // Singleton instance
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Services
  final RouteService _routeService = RouteService();

  // State
  NavigationState _state = NavigationState.idle();
  NavigationMetrics? _metrics;

  // Location tracking
  StreamSubscription<Position>? _locationSubscription;
  LatLng? _lastKnownPosition;
  DateTime? _lastRouteUpdateTime;

  // Configuration
  static const double deviationThreshold = 50.0; // meters
  static const double arrivalThreshold = 10.0; // meters
  static const Duration rerouteDebounce = Duration(seconds: 15);
  static const Duration metricsUpdateInterval = Duration(seconds: 2);

  // Stream controllers
  final StreamController<NavigationState> _stateController =
      StreamController<NavigationState>.broadcast();
  final StreamController<NavigationMetrics> _metricsController =
      StreamController<NavigationMetrics>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // Getters for streams
  Stream<NavigationState> get stateStream => _stateController.stream;
  Stream<NavigationMetrics> get metricsStream => _metricsController.stream;
  Stream<String> get errorStream => _errorController.stream;

  // Getters for state
  NavigationState get state => _state;
  NavigationMetrics? get metrics => _metrics;
  bool get isNavigating => _state.isNavigating || _state.isRerouting;

  /// Start navigation to destination
  Future<bool> startNavigation({
    required UserLocation destination,
    required LatLng currentLocation,
    required String destinationUserId,
    Stream<UserLocation>? destinationLocationStream,
  }) async {
    try {
      // Stop any existing navigation
      await stopNavigation();

      // Calculate initial route
      final destinationLatLng = LatLng(
        destination.latitude,
        destination.longitude,
      );

      final routePoints = await _routeService.getRoutePoints(
        currentLocation,
        destinationLatLng,
      );

      if (routePoints.isEmpty) {
        _errorController.add('Failed to calculate route');
        return false;
      }

      // Calculate total distance
      final totalDistance = _routeService.calculateRouteDistance(routePoints);

      // Update state
      _state = NavigationState.navigating(
        destination: destination,
        route: routePoints,
        distanceRemaining: totalDistance,
        startTime: DateTime.now(),
        destinationUserId: destinationUserId,
      );

      // Initialize metrics
      _metrics = NavigationMetrics.initial(
        totalDistance: totalDistance,
        routePoints: routePoints.length,
      );

      _stateController.add(_state);
      _metricsController.add(_metrics!);

      // Start location tracking
      _startLocationTracking();

      return true;
    } catch (e) {
      _errorController.add('Failed to start navigation: $e');
      return false;
    }
  }

  /// Update destination location when destination user moves
  Future<void> updateDestination(UserLocation newDestination) async {
    if (!isNavigating) return;

    // Update state with new destination
    _state = _state.copyWith(destination: newDestination);
    _stateController.add(_state);

    // Trigger rerouting with new destination
    if (_lastKnownPosition != null) {
      await _recalculateToNewDestination(_lastKnownPosition!, newDestination);
    }
  }

  /// Recalculate route to new destination position
  Future<void> _recalculateToNewDestination(
    LatLng currentPosition,
    UserLocation newDestination,
  ) async {
    try {
      final destinationLatLng = LatLng(
        newDestination.latitude,
        newDestination.longitude,
      );

      final newRoute = await _routeService.getRoutePoints(
        currentPosition,
        destinationLatLng,
      );

      if (newRoute.isEmpty) {
        return;
      }

      // Calculate new distance
      final newDistance = _routeService.calculateRouteDistance(newRoute);

      // Update state with new route
      _state = NavigationState.navigating(
        destination: newDestination,
        route: newRoute,
        distanceRemaining: newDistance,
        startTime: _state.startTime!,
        destinationUserId: _state.destinationUserId!,
      );

      _stateController.add(_state);
    } catch (e) {
      developer.log('Error recalculating to new destination: $e');
    }
  }

  /// Stop navigation
  Future<void> stopNavigation() async {
    await _stopLocationTracking();

    _state = NavigationState.idle();
    _metrics = null;
    _lastKnownPosition = null;
    _lastRouteUpdateTime = null;

    _stateController.add(_state);
  }

  /// Start continuous location tracking
  void _startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onLocationUpdate,
      onError: (error) {
        _errorController.add('Location tracking error: $error');
      },
    );
  }

  /// Stop location tracking
  Future<void> _stopLocationTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  /// Handle location updates
  Future<void> _onLocationUpdate(Position position) async {
    if (!isNavigating) return;

    final currentPosition = LatLng(position.latitude, position.longitude);
    _lastKnownPosition = currentPosition;

    // Check if arrived
    if (_checkArrival(currentPosition)) {
      await _handleArrival();
      return;
    }

    // Update metrics
    _updateMetrics(currentPosition, position.speed);

    // Check deviation and reroute if needed
    if (_shouldReroute(currentPosition)) {
      await _triggerRerouting(currentPosition);
    }
  }

  /// Check if user has arrived at destination
  bool _checkArrival(LatLng currentPosition) {
    if (_state.destination == null) return false;

    final destinationLatLng = LatLng(
      _state.destination!.latitude,
      _state.destination!.longitude,
    );

    final distance = _routeService.calculateDistance(
      currentPosition,
      destinationLatLng,
    );

    final distanceInMeters = distance * 1000;
    return distanceInMeters <= arrivalThreshold;
  }

  /// Handle arrival at destination
  Future<void> _handleArrival() async {
    _state = NavigationState.arrived(
      destination: _state.destination!,
      destinationUserId: _state.destinationUserId!,
    );

    _stateController.add(_state);

    // Stop tracking after a short delay
    await Future.delayed(const Duration(seconds: 2));
    await stopNavigation();
  }

  /// Check if rerouting is needed
  bool _shouldReroute(LatLng currentPosition) {
    // Do not reroute if already rerouting
    if (_state.isRerouting) return false;

    // Do not reroute too frequently
    if (_lastRouteUpdateTime != null) {
      final timeSinceLastUpdate = DateTime.now().difference(
        _lastRouteUpdateTime!,
      );
      if (timeSinceLastUpdate < rerouteDebounce) {
        return false;
      }
    }

    // Check if off route
    if (_state.currentRoute.isEmpty) return false;

    final distanceToRoute = _routeService.distanceToRoute(
      currentPosition,
      _state.currentRoute,
    );

    return distanceToRoute > deviationThreshold;
  }

  /// Trigger rerouting
  Future<void> _triggerRerouting(LatLng currentPosition) async {
    // Update state to rerouting
    _state = NavigationState.rerouting(
      destination: _state.destination!,
      oldRoute: _state.currentRoute,
      destinationUserId: _state.destinationUserId!,
      startTime: _state.startTime!,
    );
    _stateController.add(_state);

    try {
      // Calculate new route
      final destinationLatLng = LatLng(
        _state.destination!.latitude,
        _state.destination!.longitude,
      );

      final newRoute = await _routeService.getRoutePoints(
        currentPosition,
        destinationLatLng,
      );

      if (newRoute.isEmpty) {
        _errorController.add('Failed to recalculate route');

        // Revert to navigating state with old route
        _state = _state.copyWith(status: NavigationStatus.navigating);
        _stateController.add(_state);
        return;
      }

      // Calculate new distance
      final newDistance = _routeService.calculateRouteDistance(newRoute);

      // Update state with new route
      _state = NavigationState.navigating(
        destination: _state.destination!,
        route: newRoute,
        distanceRemaining: newDistance,
        startTime: _state.startTime!,
        destinationUserId: _state.destinationUserId!,
      );

      _lastRouteUpdateTime = DateTime.now();
      _stateController.add(_state);
    } catch (e) {
      _errorController.add('Rerouting failed: $e');

      // Revert to navigating state
      _state = _state.copyWith(status: NavigationStatus.navigating);
      _stateController.add(_state);
    }
  }

  /// Update navigation metrics
  void _updateMetrics(LatLng currentPosition, double speedMps) {
    if (_state.destination == null || _metrics == null) return;

    // Calculate distance to destination
    final destinationLatLng = LatLng(
      _state.destination!.latitude,
      _state.destination!.longitude,
    );

    final distanceRemaining = _routeService.calculateDistance(
      currentPosition,
      destinationLatLng,
    );

    // Convert speed from m/s to km/h
    final speedKmh = speedMps * 3.6;

    // Calculate elapsed time
    final elapsed = DateTime.now().difference(_state.startTime!);

    // Calculate ETA
    double? eta;
    if (speedKmh > 0) {
      eta = (distanceRemaining / speedKmh) * 60; // in minutes
    }

    // Update metrics
    _metrics = _metrics!.copyWith(
      distanceRemaining: distanceRemaining,
      currentSpeed: speedKmh,
      estimatedTimeArrival: eta,
      elapsed: elapsed,
    );

    _metricsController.add(_metrics!);

    // Also update state with distance
    _state = _state.copyWith(
      distanceRemaining: distanceRemaining,
      estimatedTimeArrival: eta,
    );
    _stateController.add(_state);
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopNavigation();
    await _stateController.close();
    await _metricsController.close();
    await _errorController.close();
  }
}
