import 'package:latlong2/latlong.dart';
import 'user_location.dart';

enum NavigationStatus { idle, navigating, rerouting, arrived }

class NavigationState {
  final NavigationStatus status;
  final UserLocation? destination;
  final List<LatLng> currentRoute;
  final double distanceRemaining; // in kilometers
  final double? estimatedTimeArrival; // in minutes
  final bool isOffRoute;
  final DateTime? startTime;
  final String? destinationUserId;

  const NavigationState({
    required this.status,
    this.destination,
    this.currentRoute = const [],
    this.distanceRemaining = 0.0,
    this.estimatedTimeArrival,
    this.isOffRoute = false,
    this.startTime,
    this.destinationUserId,
  });

  factory NavigationState.idle() {
    return const NavigationState(status: NavigationStatus.idle);
  }

  factory NavigationState.navigating({
    required UserLocation destination,
    required List<LatLng> route,
    required double distanceRemaining,
    double? eta,
    required DateTime startTime,
    required String destinationUserId,
  }) {
    return NavigationState(
      status: NavigationStatus.navigating,
      destination: destination,
      currentRoute: route,
      distanceRemaining: distanceRemaining,
      estimatedTimeArrival: eta,
      isOffRoute: false,
      startTime: startTime,
      destinationUserId: destinationUserId,
    );
  }

  factory NavigationState.rerouting({
    required UserLocation destination,
    required List<LatLng> oldRoute,
    required String destinationUserId,
    required DateTime startTime,
  }) {
    return NavigationState(
      status: NavigationStatus.rerouting,
      destination: destination,
      currentRoute: oldRoute,
      distanceRemaining: 0.0,
      isOffRoute: true,
      startTime: startTime,
      destinationUserId: destinationUserId,
    );
  }

  factory NavigationState.arrived({
    required UserLocation destination,
    required String destinationUserId,
  }) {
    return NavigationState(
      status: NavigationStatus.arrived,
      destination: destination,
      destinationUserId: destinationUserId,
    );
  }

  NavigationState copyWith({
    NavigationStatus? status,
    UserLocation? destination,
    List<LatLng>? currentRoute,
    double? distanceRemaining,
    double? estimatedTimeArrival,
    bool? isOffRoute,
    DateTime? startTime,
    String? destinationUserId,
  }) {
    return NavigationState(
      status: status ?? this.status,
      destination: destination ?? this.destination,
      currentRoute: currentRoute ?? this.currentRoute,
      distanceRemaining: distanceRemaining ?? this.distanceRemaining,
      estimatedTimeArrival: estimatedTimeArrival ?? this.estimatedTimeArrival,
      isOffRoute: isOffRoute ?? this.isOffRoute,
      startTime: startTime ?? this.startTime,
      destinationUserId: destinationUserId ?? this.destinationUserId,
    );
  }

  bool get isNavigating => status == NavigationStatus.navigating;
  bool get isRerouting => status == NavigationStatus.rerouting;
  bool get isIdle => status == NavigationStatus.idle;
  bool get hasArrived => status == NavigationStatus.arrived;
  bool get isActive => isNavigating || isRerouting;

  @override
  String toString() {
    return 'NavigationState(status: $status, destination: ${destinationUserId ?? 'none'}, distanceRemaining: ${distanceRemaining.toStringAsFixed(2)} km)';
  }
}
