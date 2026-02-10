import 'package:flutter/material.dart';

/// A beautiful loading screen with linear progress indicator
/// Shows percentage and current loading step
class LoadingProgressScreen extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String currentStep;

  const LoadingProgressScreen({
    super.key,
    required this.progress,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.black, Colors.grey.shade900],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Loading Icon - Changed to medical/therapy theme
              const Icon(
                Icons.healing,
                size: 64,
                color: Colors.lightBlueAccent,
              ),
              const SizedBox(height: 24),

              // Title - Changed to therapy-focused
              const Text(
                "Preparing Your Therapy Session",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),

              // Linear Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 20,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.lightBlueAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Percentage Display
              Text(
                "$percentage%",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlueAccent,
                ),
              ),
              const SizedBox(height: 24),

              // Current Step
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.lightBlueAccent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.lightBlueAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        currentStep,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
