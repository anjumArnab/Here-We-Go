class NavigationMetrics {
  final double distanceRemaining; // in kilometers
  final double? estimatedTimeArrival; // in minutes
  final double? currentSpeed; // in km/h
  final DateTime startTime;
  final Duration elapsed;
  final int routePointsCount;
  final double totalRouteDistance; // in kilometers

  const NavigationMetrics({
    required this.distanceRemaining,
    this.estimatedTimeArrival,
    this.currentSpeed,
    required this.startTime,
    required this.elapsed,
    this.routePointsCount = 0,
    this.totalRouteDistance = 0.0,
  });

  // Initial metrics
  factory NavigationMetrics.initial({
    required double totalDistance,
    required int routePoints,
  }) {
    final now = DateTime.now();
    return NavigationMetrics(
      distanceRemaining: totalDistance,
      estimatedTimeArrival: null,
      currentSpeed: null,
      startTime: now,
      elapsed: Duration.zero,
      routePointsCount: routePoints,
      totalRouteDistance: totalDistance,
    );
  }

  double? calculateETA() {
    if (currentSpeed == null || currentSpeed! <= 0) return null;
    return (distanceRemaining / currentSpeed!) * 60;
  }

  String get formattedDistance {
    if (distanceRemaining < 1.0) {
      return '${(distanceRemaining * 1000).toInt()} m';
    }
    return '${distanceRemaining.toStringAsFixed(1)} km';
  }

  String get formattedETA {
    final eta = estimatedTimeArrival ?? calculateETA();
    if (eta == null) return '--';

    if (eta < 60) {
      return '${eta.toInt()} min';
    }
    final hours = eta ~/ 60;
    final minutes = (eta % 60).toInt();
    return '${hours}h ${minutes}min';
  }

  String get formattedSpeed {
    if (currentSpeed == null) return '-- km/h';
    return '${currentSpeed!.toInt()} km/h';
  }

  String get formattedElapsed {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;
    final seconds = elapsed.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  double get progressPercentage {
    if (totalRouteDistance <= 0) return 0.0;
    final traveled = totalRouteDistance - distanceRemaining;
    return (traveled / totalRouteDistance * 100).clamp(0.0, 100.0);
  }

  NavigationMetrics copyWith({
    double? distanceRemaining,
    double? estimatedTimeArrival,
    double? currentSpeed,
    DateTime? startTime,
    Duration? elapsed,
    int? routePointsCount,
    double? totalRouteDistance,
  }) {
    return NavigationMetrics(
      distanceRemaining: distanceRemaining ?? this.distanceRemaining,
      estimatedTimeArrival: estimatedTimeArrival ?? this.estimatedTimeArrival,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      startTime: startTime ?? this.startTime,
      elapsed: elapsed ?? this.elapsed,
      routePointsCount: routePointsCount ?? this.routePointsCount,
      totalRouteDistance: totalRouteDistance ?? this.totalRouteDistance,
    );
  }

  @override
  String toString() {
    return 'NavigationMetrics(distance: $formattedDistance, eta: $formattedETA, speed: $formattedSpeed)';
  }
}
