import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../services/navigation_service.dart';
import '../models/navigation_state.dart';
import '../models/navigation_metrics.dart';
import '../models/user_location.dart';

class NavigationProvider extends ChangeNotifier {
  final NavigationService _navigationService = NavigationService();

  // Stream subscriptions
  StreamSubscription<NavigationState>? _stateSubscription;
  StreamSubscription<NavigationMetrics>? _metricsSubscription;
  StreamSubscription<String>? _errorSubscription;

  // State
  NavigationState _state = NavigationState.idle();
  NavigationMetrics? _metrics;
  String? _lastError;
  bool _arrivedFlagShown = false;

  // Getters
  NavigationState get state => _state;
  NavigationMetrics? get metrics => _metrics;
  String? get lastError => _lastError;

  // Status getters
  bool get isNavigating => _state.isNavigating;
  bool get isRerouting => _state.isRerouting;
  bool get isIdle => _state.isIdle;
  bool get hasArrived => _state.hasArrived && !_arrivedFlagShown;
  bool get isActive => _state.isActive;

  // Data getters
  UserLocation? get destination => _state.destination;
  String? get destinationUserId => _state.destinationUserId;
  List<LatLng>? get currentRoute => 
      _state.currentRoute.isEmpty ? null : _state.currentRoute;
  double get distanceRemaining => _state.distanceRemaining;
  double? get estimatedTimeArrival => _state.estimatedTimeArrival;

  NavigationProvider() {
    _setupListeners();
  }

  void _setupListeners() {
    _stateSubscription = _navigationService.stateStream.listen((newState) {
      _state = newState;
      
      // Reset arrived flag when state changes to arrived
      if (_state.hasArrived) {
        _arrivedFlagShown = false;
      }
      
      notifyListeners();
    });

    _metricsSubscription = _navigationService.metricsStream.listen((newMetrics) {
      _metrics = newMetrics;
      notifyListeners();
    });

    _errorSubscription = _navigationService.errorStream.listen((error) {
      _lastError = error;
      notifyListeners();
    });
  }

  /// Start navigation to a destination
  Future<bool> startNavigation({
    required UserLocation destination,
    required LatLng currentLocation,
    required String destinationUserId,
  }) async {
    _lastError = null;
    _arrivedFlagShown = false;
    notifyListeners();

    final success = await _navigationService.startNavigation(
      destination: destination,
      currentLocation: currentLocation,
      destinationUserId: destinationUserId,
    );

    return success;
  }

  /// Update destination when it moves
  Future<void> updateDestination(UserLocation newDestination) async {
    await _navigationService.updateDestination(newDestination);
  }

  /// Stop navigation
  Future<void> stopNavigation() async {
    await _navigationService.stopNavigation();
    _arrivedFlagShown = false;
    _metrics = null;
    notifyListeners();
  }

  /// Reset arrival flag
  void resetArrivalFlag() {
    _arrivedFlagShown = true;
    notifyListeners();
  }

  /// Clear last error
  void clearLastError() {
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _metricsSubscription?.cancel();
    _errorSubscription?.cancel();
    _navigationService.dispose();
    super.dispose();
  }
}