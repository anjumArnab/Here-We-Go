import 'package:flutter_test/flutter_test.dart';
import 'package:herewego/core/di/service_locator.dart';
import 'package:herewego/core/network/socket_client.dart';
import 'package:herewego/features/chat/data/chat_service.dart';
import 'package:herewego/features/connection/data/connection_service.dart';
import 'package:herewego/features/location/data/location_service.dart';
import 'package:herewego/features/location/data/user_location_handler.dart';
import 'package:herewego/features/navigation/data/navigation_service.dart';
import 'package:herewego/features/routing/data/route_service.dart';

void main() {
  setUp(() async {
    await sl.reset();
    setupServiceLocator();
  });

  tearDown(() => sl.reset());

  test('every service resolves', () {
    expect(sl<SocketClient>(), isNotNull);
    expect(sl<ConnectionService>(), isNotNull);
    expect(sl<LocationService>(), isNotNull);
    expect(sl<ChatService>(), isNotNull);
    expect(sl<UserLocationHandler>(), isNotNull);
    expect(sl<NavigationService>(), isNotNull);
  });

  test('stateful services are shared singletons', () {
    expect(sl<ConnectionService>(), same(sl<ConnectionService>()));
    expect(sl<ChatService>(), same(sl<ChatService>()));
    expect(sl<SocketClient>(), same(sl<SocketClient>()));
  });

  test('RouteService is a new instance per request', () {
    expect(sl<RouteService>(), isNot(same(sl<RouteService>())));
  });
}
