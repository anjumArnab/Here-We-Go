import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:herewego/core/network/api_client.dart';
import 'package:herewego/features/routing/data/route_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

const origin = LatLng(23.78, 90.41);
const destination = LatLng(23.73, 90.39);

String osrmOk() => jsonEncode({
  'code': 'Ok',
  'routes': [
    {
      'geometry': {
        'coordinates': [
          [90.41, 23.78],
          [90.40, 23.75],
          [90.39, 23.73],
        ],
      },
    },
  ],
});

class Harness {
  final List<Uri> requests = [];
  late final RouteService service;

  Harness(http.Response Function(http.Request) respond) {
    service = RouteService(
      apiClient: ApiClient(
        baseUrl: 'https://osrm.test',
        client: MockClient((req) async {
          requests.add(req.url);
          return respond(req);
        }),
      ),
    );
  }
}

void main() {
  group('RouteService.getRoutePoints', () {
    test('parses OSRM geometry (lng,lat -> LatLng)', () async {
      final h = Harness((_) => http.Response(osrmOk(), 200));

      final points = await h.service.getRoutePoints(origin, destination);

      expect(points, hasLength(3));
      expect(points.first, const LatLng(23.78, 90.41));
      expect(points.last, const LatLng(23.73, 90.39));
    });

    test('requests the right path, profile and query', () async {
      final h = Harness((_) => http.Response(osrmOk(), 200));
      h.service.setRouteMode('walking');

      await h.service.getRoutePoints(origin, destination);

      final url = h.requests.single;
      expect(url.path, '/route/v1/foot/90.41,23.78;90.39,23.73');
      expect(url.queryParameters, {'overview': 'full', 'geometries': 'geojson'});
    });

    test('falls back to a direct line on a bad status', () async {
      final h = Harness((_) => http.Response('err', 503));

      final points = await h.service.getRoutePoints(origin, destination);

      expect(points, [origin, destination]);
    });

    test('falls back to a direct line when OSRM code is not Ok', () async {
      final h = Harness(
        (_) => http.Response(jsonEncode({'code': 'NoRoute'}), 200),
      );

      final points = await h.service.getRoutePoints(origin, destination);

      expect(points, [origin, destination]);
    });

    test('caches results per origin/destination/mode', () async {
      final h = Harness((_) => http.Response(osrmOk(), 200));

      await h.service.getRoutePoints(origin, destination);
      await h.service.getRoutePoints(origin, destination);
      expect(h.requests, hasLength(1));

      h.service.setRouteMode('cycling'); // clears the cache
      await h.service.getRoutePoints(origin, destination);
      expect(h.requests, hasLength(2));
    });
  });

  group('RouteService geometry helpers', () {
    final service = RouteService(
      apiClient: ApiClient(baseUrl: 'https://osrm.test'),
    );

    test('calculateRouteDistance is 0 for fewer than 2 points', () {
      expect(service.calculateRouteDistance([origin]), 0.0);
    });

    test('calculateRouteDistance sums segments in km', () {
      final km = service.calculateRouteDistance([origin, destination]);
      final expectedKm = const Distance()(origin, destination) / 1000;
      expect(km, closeTo(expectedKm, 0.001));
    });

    test('distanceToRoute is infinity for a degenerate route', () {
      expect(service.distanceToRoute(origin, [origin]), double.infinity);
    });

    test('distanceToRoute is ~0 for a point on the route', () {
      final d = service.distanceToRoute(origin, [origin, destination]);
      expect(d, lessThan(1));
    });
  });
}
