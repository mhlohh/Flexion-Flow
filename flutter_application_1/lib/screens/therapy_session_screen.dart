import 'package:flutter/material.dart';
import '../widgets/live_feed_section.dart';
import '../widgets/instruction_player.dart';
import '../services/auth_service.dart';
import 'calibration_screen.dart';

import '../enums/exercise_type.dart';

class TherapySessionScreen extends StatefulWidget {
  final ExerciseType? exerciseType;

  const TherapySessionScreen({super.key, this.exerciseType});

  @override
  State<TherapySessionScreen> createState() => _TherapySessionScreenState();
}

class _TherapySessionScreenState extends State<TherapySessionScreen> {
  double _userBaseline = 160.0; // Default fallback
  final AuthService _auth = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserBaseline();
  }

  Future<void> _loadUserBaseline() async {
    final double? baseline = await _auth.getUserBaseline();
    if (mounted) {
      setState(() {
        if (baseline != null && baseline > 0) {
          _userBaseline = baseline;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Target: 90% of max ROM
    final double exerciseTarget = _userBaseline * 0.9;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Daily Session"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          // Calibration Button
          IconButton(
            icon: const Icon(Icons.accessibility_new, color: Colors.white),
            tooltip: "Test Flexibility",
            onPressed: () async {
              // Navigate to Calibration and refresh on return
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CalibrationScreen(),
                ),
              );
              _loadUserBaseline(); // Refresh after coming back
            },
          ),
          // Sign Out Button (Optional helper)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Sign Out",
            onPressed: () async {
              await _auth.signOut();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Section: Live Feed (60% height)
                Expanded(
                  flex: 6,
                  child: Stack(
                    children: [
                      LiveFeedSection(targetAngle: exerciseTarget),
                      // Optional: Show target overlay
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Target: ${exerciseTarget.toStringAsFixed(0)}°",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Section: Instruction Area (40% height)
                const Expanded(flex: 4, child: InstructionPlayer()),
              ],
            ),
    );
  }
}
