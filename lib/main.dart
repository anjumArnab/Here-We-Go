import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:herewego/providers/chat_provider.dart';
import 'package:herewego/providers/connection_provider.dart';
import 'package:provider/provider.dart';
import 'providers/location_provider.dart';
import 'providers/route_provider.dart';
import 'providers/user_location_provider.dart';
import '../views/homepage.dart';

void main() {
  runApp(const HereWeGo());
}

class HereWeGo extends StatelessWidget {
  const HereWeGo({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
        ChangeNotifierProvider(create: (_) => UserLocationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
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
