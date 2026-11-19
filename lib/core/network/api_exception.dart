enum ApiErrorType { timeout, noConnection, badStatus, parse, unknown }

/// Typed error thrown by [ApiClient] so callers don't deal with raw
/// http/dart:io exceptions.
class ApiException implements Exception {
  final ApiErrorType type;
  final String message;
  final int? statusCode;

  const ApiException(this.type, this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($type, $statusCode): $message';
}
