import 'package:flutter/material.dart';
import '../widgets/live_feed_section_mobile.dart'; // Import the mobile implementation directly for now or the wrapper
import '../logic/calibration_logic.dart';
import '../services/auth_service.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final CalibrationSession _session = CalibrationSession();
  bool _isComplete = false;
  String _statusMessage = "Lift your arm as high as possible.";

  void _handleAngleUpdate(double angle) {
    if (_isComplete) return;

    _session.processFrame(angle);

    if (_session.isCalibrationComplete) {
      _finishCalibration();
    } else {
      // Update UI with rep count if needed, though setState on every frame might be heavy
      // Optimization: Only setState if rep count changed
    }
  }

  Future<void> _finishCalibration() async {
    setState(() {
      _isComplete = true;
      _statusMessage = "Calibration Complete!";
    });

    final double baseline = _session.getFinalBaseline();
    await AuthService().updateUserBaseline(baseline);

    if (!mounted) return;

    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Success!"),
        content: Text(
          "Your baseline Range of Motion is ${baseline.toStringAsFixed(1)}°.\n\nWe have tailored your exercise targets based on this result.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text("Start Exercising"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Calibration"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: Stack(
        children: [
          // Camera Feed with Calibration Logic
          LiveFeedSection(
            onAngleUpdate: _handleAngleUpdate,
            targetAngle: 180, // Set high target for calibration visual feedback
          ),

          // Overlay Instructions
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Reps: ${_session.repCount} / 3",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
