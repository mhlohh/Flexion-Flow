import 'package:flutter/material.dart';
import 'screens/therapy_session_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flexion Flow',
      theme: ThemeData(
        // Using a color scheme based on the requested Medical Blue (#007AFF)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          primary: const Color(0xFF007AFF),
          error: const Color(0xFFFF3B30),
          surface: const Color(0xFFF5F5F5),
        ),
        useMaterial3: true,
      ),
      home: const TherapySessionScreen(),
    );
  }
}
