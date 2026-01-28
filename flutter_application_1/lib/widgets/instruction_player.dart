import 'package:flutter/material.dart';

class InstructionPlayer extends StatelessWidget {
  const InstructionPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5), // Off-white background
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Video Player Placeholder
          // TODO: Replace with actual VideoPlayer widget
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill, // Play icon
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Instruction Text Area
          const Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 1:',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007AFF), // Medical Blue
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Raise your arm slowly to shoulder height. Hold for 5 seconds, then lower it gently.',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Control Buttons (Optional, but good for "Instruction Area" context)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.skip_previous),
                label: const Text('Prev'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF007AFF),
                  minimumSize: const Size(120, 48), // Large touch target
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFF007AFF)),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.skip_next),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 48), // Large touch target
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
