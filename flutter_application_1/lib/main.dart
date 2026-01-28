import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/therapy_session_screen.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flexion Flow',
      theme: ThemeData(
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
