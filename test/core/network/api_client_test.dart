import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:herewego/core/network/api_client.dart';
import 'package:herewego/core/network/api_exception.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient clientFor(
  Future<http.Response> Function(http.Request) handler, {
  Duration timeout = const Duration(seconds: 1),
}) {
  return ApiClient(
    baseUrl: 'https://example.test',
    timeout: timeout,
    client: MockClient(handler),
  );
}

Future<ApiException> expectApiError(Future<dynamic> Function() call) async {
  try {
    await call();
  } on ApiException catch (e) {
    return e;
  }
  fail('Expected ApiException');
}

void main() {
  group('ApiClient.get', () {
    test('builds URL with query params and decodes JSON', () async {
      late http.Request seen;
      final client = clientFor((req) async {
        seen = req;
        return http.Response(jsonEncode({'ok': true}), 200);
      });

      final result = await client.get('/route', queryParameters: {'a': 1});

      expect(result, {'ok': true});
      expect(seen.url.toString(), 'https://example.test/route?a=1');
      expect(seen.headers['Content-Type'], contains('application/json'));
    });

    test('returns null for an empty body', () async {
      final client = clientFor((_) async => http.Response('', 204));
      expect(await client.get('/x'), isNull);
    });

    test('throws badStatus with the status code on non-2xx', () async {
      final client = clientFor((_) async => http.Response('nope', 500));

      final e = await expectApiError(() => client.get('/x'));

      expect(e.type, ApiErrorType.badStatus);
      expect(e.statusCode, 500);
    });

    test('throws parse on invalid JSON', () async {
      final client = clientFor((_) async => http.Response('not json', 200));

      final e = await expectApiError(() => client.get('/x'));

      expect(e.type, ApiErrorType.parse);
    });

    test('throws timeout when the request is too slow', () async {
      final client = clientFor(
        (_) => Completer<http.Response>().future,
        timeout: const Duration(milliseconds: 20),
      );

      final e = await expectApiError(() => client.get('/x'));

      expect(e.type, ApiErrorType.timeout);
    });

    test('throws noConnection on a client error', () async {
      final client = clientFor((_) async {
        throw http.ClientException('offline');
      });

      final e = await expectApiError(() => client.get('/x'));

      expect(e.type, ApiErrorType.noConnection);
    });
  });

  group('ApiClient.post', () {
    test('sends the body as JSON', () async {
      late http.Request seen;
      final client = clientFor((req) async {
        seen = req;
        return http.Response('{}', 200);
      });

      await client.post('/x', body: {'a': 1});

      expect(seen.method, 'POST');
      expect(jsonDecode(seen.body), {'a': 1});
    });
  });
}
