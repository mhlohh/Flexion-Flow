import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'services/auth_service.dart';
import 'firebase_options.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  // Android uses google-services.json (auto-init), Web needs manual options
  await Firebase.initializeApp(
    options: kIsWeb ? DefaultFirebaseOptions.currentPlatform : null,
  );

  // Initialize cameras
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error: $e.code\nError Message: $e.message');
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
      home: const AuthWrapper(),
    );
  }
}

// Handles routing based on authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F5F5),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is logged in, show MainScreen (Dashboard)
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreen();
        }

        // Otherwise, show LoginScreen
        return const LoginScreen();
      },
    );
  }
}
