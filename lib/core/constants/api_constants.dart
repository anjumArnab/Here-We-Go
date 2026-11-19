/// Endpoints and timeouts for external HTTP APIs.
class ApiConstants {
  ApiConstants._();

  /// OSRM routing API (HTTPS: cleartext HTTP is blocked in release builds).
  static const String osrmBaseUrl = 'https://router.project-osrm.org';
  static const String osrmRoutePath = '/route/v1';

  static const Duration requestTimeout = Duration(seconds: 10);
}
