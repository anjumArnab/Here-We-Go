/// App-wide tunable values that are not tied to a single widget.
class AppConstants {
  AppConstants._();

  // Navigation
  static const double deviationThresholdMeters = 50.0;
  static const double arrivalThresholdMeters = 10.0;
  static const Duration rerouteDebounce = Duration(seconds: 15);
  static const Duration metricsUpdateInterval = Duration(seconds: 2);
}
