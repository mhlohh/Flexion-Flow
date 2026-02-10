import 'dart:ui';
import 'package:flutter/material.dart';

class GlassFeedbackPanel extends StatelessWidget {
  final double angle;
  final String feedback;
  final Color color;
  final int? currentRep;
  final int? targetReps;
  final int? currentSet;
  final int? targetSets;

  const GlassFeedbackPanel({
    super.key,
    required this.angle,
    required this.feedback,
    required this.color,
    this.currentRep,
    this.targetReps,
    this.currentSet,
    this.targetSets,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Workout Progress (if available)
              if (currentSet != null && targetSets != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Set $currentSet/$targetSets",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.tealAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.tealAccent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          "${currentRep ?? 0}/$targetReps Reps",
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Existing angle and feedback
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Angle
                  Text(
                    "${angle.toStringAsFixed(0)}°",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black45,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 16),
                  // Feedback Message
                  Text(
                    feedback.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        const Shadow(
                          blurRadius: 12.0,
                          color: Colors.black54,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
