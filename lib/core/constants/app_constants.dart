/// App-wide tunable values that are not tied to a single widget.
class AppConstants {
  AppConstants._();

  // Socket connection
  static const int socketReconnectionAttempts = 5;
  static const int socketReconnectionDelayMs = 1000;
  static const int socketTimeoutMs = 10000;
  static const Duration joinRoomTimeout = Duration(seconds: 15);

  // Navigation
  static const double deviationThresholdMeters = 50.0;
  static const double arrivalThresholdMeters = 10.0;
  static const Duration rerouteDebounce = Duration(seconds: 15);
  static const Duration metricsUpdateInterval = Duration(seconds: 2);
}
