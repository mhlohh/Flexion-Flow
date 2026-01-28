import 'package:flutter/material.dart';
import '../widgets/live_feed_section.dart';
import '../widgets/instruction_player.dart';

class TherapySessionScreen extends StatelessWidget {
  const TherapySessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Section: Live Feed (60% height)
            const Expanded(flex: 6, child: LiveFeedSection()),

            // Bottom Section: Instruction Area (40% height)
            const Expanded(flex: 4, child: InstructionPlayer()),
          ],
        ),
      ),
    );
  }
}
