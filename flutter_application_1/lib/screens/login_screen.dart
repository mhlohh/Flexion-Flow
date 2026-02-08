import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    final user = await _authService.signInWithGoogle();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (user == null) {
        // Show error message if sign-in failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign-in failed. Please try again.'),
            backgroundColor: Color(0xFFFF3B30),
          ),
        );
      }
      // Note: Navigation is handled automatically by auth state stream in main.dart
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // App Logo/Icon Placeholder
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.accessibility_new,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                // App Title
                const Text(
                  'Flexion Flow',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007AFF),
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                const Text(
                  'Your Digital Therapist',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const Spacer(flex: 3),

                // Google Sign-In Button
                // Replaced with platform-aware widget
                GoogleSignInButton(
                  onPressed: _handleGoogleSignIn,
                  isLoading: _isLoading,
                ),

                const Spacer(flex: 2),

                // Privacy text
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    'By signing in, you agree to our Terms of Service\nand Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
