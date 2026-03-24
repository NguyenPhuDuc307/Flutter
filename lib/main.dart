import 'package:flutter/material.dart';
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
      theme: ThemeData(fontFamily: 'monospace', useMaterial3: false),
      home: const ModeSelectionScreen(),
    );
  }
}
