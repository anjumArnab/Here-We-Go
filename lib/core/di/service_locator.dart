import 'package:get_it/get_it.dart';
import '../../services/chat_service.dart';
import '../../services/connection_service.dart';
import '../../services/location_service.dart';
import '../../services/navigation_service.dart';
import '../services/notification_service.dart';
import '../../features/routing/data/route_service.dart';
import '../../services/user_location_handler.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../network/socket_client.dart';

/// Global service locator. Call [setupServiceLocator] once before `runApp`.
final GetIt sl = GetIt.instance;

void setupServiceLocator() {
  // Core
  sl.registerLazySingleton<SocketClient>(() => SocketClient());
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(baseUrl: ApiConstants.osrmBaseUrl),
  );

  // Services (shared, stateful)
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<ConnectionService>(
    () => ConnectionService(sl<SocketClient>()),
  );
  sl.registerLazySingleton<LocationService>(
    () => LocationService(sl<SocketClient>()),
  );
  sl.registerLazySingleton<ChatService>(
    () => ChatService(sl<SocketClient>(), sl<NotificationService>()),
  );
  sl.registerLazySingleton<UserLocationHandler>(() => UserLocationHandler());

  // RouteService keeps per-owner state (mode, selected users, cache), and
  // RouteProvider and NavigationService each used their own instance, so it
  // is a factory rather than a shared singleton.
  sl.registerFactory<RouteService>(
    () => RouteService(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<NavigationService>(
    () => NavigationService(sl<RouteService>()),
  );
}
