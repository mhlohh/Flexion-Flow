import 'package:flutter/material.dart';

class LiveFeedSection extends StatelessWidget {
  const LiveFeedSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Top Section (60% of the screen height effectively handled by the parent flex)
    // Using a Container to represent the live feed area
    return Stack(
      children: [
        // Placeholder for Camera Preview
        // TODO: Replace this Container with CameraPreview widget later
        Container(
          color: Colors.black,
          width: double.infinity,
          height: double.infinity,
        ),
        // Score Overlay
        Positioned(
          top: 40, // Adjust status bar padding as needed
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  Colors.black54, // Semi-transparent background for readability
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Score: 0',
              style: TextStyle(
                // Google Fonts 'Roboto' is the default in Flutter, so we can use standard TextStyle
                // or explicitly use GoogleFonts package if added to pubspec.yaml.
                // For now, using standard TextStyle with Roboto-like characteristics.
                fontFamily: 'Roboto',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
