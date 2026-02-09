import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/exercise_card.dart';
import '../enums/exercise_type.dart';
import 'therapy_session_screen.dart';
import 'calibration_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final userName = user?.displayName?.split(' ').first ?? "User";

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                "Welcome back!",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
              ),
              Text(
                "$userName 👋",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),

              // Section Title
              Text(
                "Select Your Therapy",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Exercise List
              ExerciseCard(
                title: "Elbow Flexion",
                subtitle: "Range of Motion: 50° - 160°",
                // time: "5 min",
                icon: Icons.fitness_center,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TherapySessionScreen(
                        exerciseType: ExerciseType.elbowFlexion,
                      ),
                    ),
                  );
                },
              ),

              ExerciseCard(
                title: "Shoulder Abduction",
                subtitle: "Coming Soon",
                icon: Icons.accessibility_new,
                color: Colors.grey,
                onTap: () {
                  // Placeholder
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("Coming Soon!")));
                },
              ),

              ExerciseCard(
                title: "Calibration",
                subtitle: "Set your baseline flexibility",
                icon: Icons.tune,
                color: Colors.purple,
                onTap: () {
                  // Navigate to Calibration
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CalibrationScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
