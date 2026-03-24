import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/mode_selection_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bida Score',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        textTheme: GoogleFonts.oswaldTextTheme(),
        primaryTextTheme: GoogleFonts.oswaldTextTheme(),
      ),
      home: const ModeSelectionScreen(),
    );
  }
}
