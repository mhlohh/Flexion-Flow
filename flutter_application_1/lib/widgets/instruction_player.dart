import 'package:flutter/material.dart';

class InstructionPlayer extends StatefulWidget {
  final VoidCallback? onReset;
  final VoidCallback? onTogglePause;
  final bool isPaused;

  const InstructionPlayer({
    super.key,
    this.onReset,
    this.onTogglePause,
    this.isPaused = false,
  });

  @override
  State<InstructionPlayer> createState() => _InstructionPlayerState();
}

class _InstructionPlayerState extends State<InstructionPlayer> {
  // GIF path
  final String _gifPath = "assets/gifs/elbow_flexion.gif";

  void _openFullScreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // Transparent background for "dark clear skin" effect
        pageBuilder: (context, _, __) {
          return FullScreenGifPlayer(gifPath: _gifPath);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // GIF Player Area (Preview)
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: _openFullScreen,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // GIF Preview
                      Image.asset(_gifPath, fit: BoxFit.contain),

                      // Expand Icon Overlay (Optional, to indicate it's clickable)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                      color: Color(0xFF007AFF),
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
          // Navigation Buttons - Replaced with Workout Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Reset Button
              OutlinedButton.icon(
                onPressed: widget.onReset,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade700, width: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              // Play/Pause Button
              ElevatedButton.icon(
                onPressed: widget.onTogglePause,
                icon: Icon(
                  widget.isPaused ? Icons.play_arrow : Icons.pause,
                  size: 20,
                ),
                label: Text(widget.isPaused ? 'Resume' : 'Pause'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
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

// Full Screen GIF Overlay
class FullScreenGifPlayer extends StatelessWidget {
  final String gifPath;

  const FullScreenGifPlayer({super.key, required this.gifPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9), // Dark clear skin
      body: SafeArea(
        child: Stack(
          children: [
            // Centered GIF
            Center(child: Image.asset(gifPath, fit: BoxFit.contain)),

            // Close Button
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
