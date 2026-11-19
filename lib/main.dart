import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../views/homepage.dart';
import 'providers/chat_provider.dart';
import 'providers/connection_provider.dart';
import 'providers/location_provider.dart';
import 'features/routing/providers/route_provider.dart';
import 'providers/user_location_provider.dart';
import 'providers/navigation_provider.dart';
import 'core/di/service_locator.dart';
import 'services/chat_service.dart';
import 'services/connection_service.dart';
import 'services/location_service.dart';
import 'services/navigation_service.dart';
import 'core/services/notification_service.dart';
import 'features/routing/data/route_service.dart';
import 'services/user_location_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupServiceLocator();

  // Initialize notification service
  await sl<NotificationService>().initialize();

  runApp(const HereWeGo());
}

class HereWeGo extends StatelessWidget {
  const HereWeGo({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ConnectionProvider(sl<ConnectionService>()),
        ),
        ChangeNotifierProvider(
          create: (_) => LocationProvider(sl<LocationService>()),
        ),
        ChangeNotifierProvider(
          create: (_) => RouteProvider(sl<RouteService>()),
        ),
        ChangeNotifierProvider(
          create: (_) => UserLocationProvider(sl<UserLocationHandler>()),
        ),
        ChangeNotifierProvider(
          create: (_) => NavigationProvider(sl<NavigationService>()),
        ),
        ChangeNotifierProvider(create: (_) => ChatProvider(sl<ChatService>())),
      ],
      child: MaterialApp(
        title: 'Here We Go',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(textTheme: GoogleFonts.poppinsTextTheme()),
        home: const Homepage(),
      ),
    );
  }
}
