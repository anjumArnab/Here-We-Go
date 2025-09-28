import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(HereWeGo());
}

class HereWeGo extends StatelessWidget {
  const HereWeGo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HereWeGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
    );
  }
}
