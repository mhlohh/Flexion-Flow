import 'dart:ui';
import 'package:flutter/material.dart';

class GlassFeedbackPanel extends StatelessWidget {
  final double angle;
  final String feedback;
  final Color color;

  const GlassFeedbackPanel({
    super.key,
    required this.angle,
    required this.feedback,
    required this.color,
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
          child: Row(
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
        ),
      ),
    );
  }
}
