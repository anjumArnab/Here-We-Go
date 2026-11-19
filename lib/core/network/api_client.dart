import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'api_exception.dart';

/// Thin wrapper around `package:http`: applies base URL, default headers
/// and timeout, decodes JSON, and maps failures to [ApiException].
class ApiClient {
  final String baseUrl;
  final Duration timeout;
  final Map<String, String> defaultHeaders;
  final http.Client _client;

  ApiClient({
    required this.baseUrl,
    this.timeout = ApiConstants.requestTimeout,
    this.defaultHeaders = const {'Content-Type': 'application/json'},
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// GET [path] (relative to [baseUrl]) and return the decoded JSON body.
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _send(
      () => _client.get(
        _uri(path, queryParameters),
        headers: {...defaultHeaders, ...?headers},
      ),
    );
  }

  /// POST [body] as JSON to [path] and return the decoded JSON response.
  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _send(
      () => _client.post(
        _uri(path, queryParameters),
        headers: {...defaultHeaders, ...?headers},
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Uri _uri(String path, Map<String, dynamic>? query) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: query.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException(ApiErrorType.timeout, 'Request timed out');
    } on SocketException catch (e) {
      throw ApiException(ApiErrorType.noConnection, e.message);
    } on http.ClientException catch (e) {
      throw ApiException(ApiErrorType.noConnection, e.message);
    } catch (e) {
      throw ApiException(ApiErrorType.unknown, e.toString());
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        ApiErrorType.badStatus,
        'Unexpected status code',
        statusCode: response.statusCode,
      );
    }

    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } on FormatException catch (e) {
      throw ApiException(ApiErrorType.parse, e.message);
    }
  }

  void dispose() => _client.close();
}
