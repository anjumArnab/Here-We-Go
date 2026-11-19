import 'package:flutter_test/flutter_test.dart';
import 'package:herewego/features/chat/data/chat_message.dart';
import 'package:herewego/features/location/data/user_location.dart';
import 'package:herewego/features/navigation/data/navigation_state.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('UserLocation', () {
    test('fromJson / toJson round trip', () {
      final json = {
        'userId': 'rifat',
        'latitude': 23.7,
        'longitude': 90.4,
        'timestamp': '2026-01-01T00:00:00.000',
      };

      expect(UserLocation.fromJson(json).toJson(), json);
    });

    test('fromJson accepts ints and applies defaults', () {
      final loc = UserLocation.fromJson({'latitude': 1, 'longitude': 2});

      expect(loc.userId, '');
      expect(loc.latitude, 1.0);
      expect(loc.longitude, 2.0);
      expect(loc.timestamp, isNotEmpty);
    });
  });

  group('ChatMessage', () {
    test('fromJson / toJson round trip', () {
      final json = {
        'messageId': 'msg_1',
        'userId': 'tushar',
        'message': 'hello',
        'timestamp': '2026-01-01T00:00:00.000',
      };

      expect(ChatMessage.fromJson(json).toJson(), json);
    });

    test('fromJson defaults missing fields', () {
      final msg = ChatMessage.fromJson({});

      expect(msg.messageId, '');
      expect(msg.message, '');
    });
  });

  group('NavigationState', () {
    final destination = UserLocation(
      userId: 'rana',
      latitude: 1,
      longitude: 2,
      timestamp: 't',
    );

    test('idle is idle and not active', () {
      final s = NavigationState.idle();

      expect(s.isIdle, isTrue);
      expect(s.isActive, isFalse);
    });

    test('navigating is active', () {
      final s = NavigationState.navigating(
        destination: destination,
        route: const [LatLng(0, 0)],
        distanceRemaining: 1.5,
        startTime: DateTime(2026),
        destinationUserId: 'rana',
      );

      expect(s.isNavigating, isTrue);
      expect(s.isActive, isTrue);
      expect(s.isOffRoute, isFalse);
    });

    test('rerouting is active and off route', () {
      final s = NavigationState.rerouting(
        destination: destination,
        oldRoute: const [],
        destinationUserId: 'rana',
        startTime: DateTime(2026),
      );

      expect(s.isRerouting, isTrue);
      expect(s.isActive, isTrue);
      expect(s.isOffRoute, isTrue);
    });

    test('arrived is not active', () {
      final s = NavigationState.arrived(
        destination: destination,
        destinationUserId: 'rana',
      );

      expect(s.hasArrived, isTrue);
      expect(s.isActive, isFalse);
    });

    test('copyWith overrides only the given fields', () {
      final s = NavigationState.idle().copyWith(distanceRemaining: 3);

      expect(s.distanceRemaining, 3);
      expect(s.status, NavigationStatus.idle);
    });
  });
}
