import 'package:flutter/material.dart';
import '../widgets/live_feed_section.dart';
import '../widgets/instruction_player.dart';
import '../services/auth_service.dart';
import 'calibration_screen.dart';
import '../logic/workout_session.dart';
import '../enums/exercise_type.dart';
import '../widgets/loading_progress_screen.dart';

class TherapySessionScreen extends StatefulWidget {
  final ExerciseType? exerciseType;
  final int? sets;
  final int? repsPerSet;

  const TherapySessionScreen({
    super.key,
    this.exerciseType,
    this.sets,
    this.repsPerSet,
  });

  @override
  State<TherapySessionScreen> createState() => _TherapySessionScreenState();
}

class _TherapySessionScreenState extends State<TherapySessionScreen> {
  double _userBaseline = 160.0; // Default fallback
  final AuthService _auth = AuthService();
  bool _isLoading = true;
  double _loadingProgress = 0.0; // 0.0 to 1.0
  String _loadingStep = "Initializing...";
  WorkoutSession? _workoutSession;
  bool _showSetComplete = false;
  bool _showSideSwitch = false; // For side switching overlay
  bool _isWorkoutPaused = false; // For workout controls

  @override
  void initState() {
    super.initState();
    _loadUserBaseline();
    _initializeWorkoutSession();
  }

  void _initializeWorkoutSession() {
    // Only create session if sets and reps are provided
    if (widget.sets != null && widget.repsPerSet != null) {
      _workoutSession = WorkoutSession(
        targetSets: widget.sets!,
        targetRepsPerSet: widget.repsPerSet!,
        exerciseType: widget.exerciseType ?? ExerciseType.elbowFlexion,
        isBilateral: true, // Elbow flexion is bilateral
        onRepCompleted: (rep) {
          setState(() {}); // Trigger UI update
          debugPrint("✅ Rep $rep completed!");
        },
        onSideCompleted: (side) {
          setState(() {
            _showSideSwitch = true;
          });
          debugPrint("🔄 ${side.name.toUpperCase()} side completed!");

          // Auto-dismiss after 2 seconds for smoother UX on slower phones
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _showSideSwitch) {
              setState(() {
                _showSideSwitch = false;
              });
            }
          });
        },
        onSetCompleted: (set) {
          setState(() {
            _showSetComplete = true;
          });
          debugPrint("🎉 Set $set completed!");
        },
        onWorkoutCompleted: () {
          _saveWorkoutHistory();
          debugPrint("🏆 Workout completed!");
        },
      );
    }
  }

  void _handleAngleUpdate(double angle) {
    // Don't update angles if workout is paused
    // NOTE: Side switch overlay does NOT pause the workout - keep tracking!
    if (_isWorkoutPaused) return;

    if (_workoutSession != null) {
      setState(() {
        _workoutSession!.updateAngle(angle);
      });
    }
  }

  void _togglePause() {
    setState(() {
      _isWorkoutPaused = !_isWorkoutPaused;
    });
  }

  void _resetWorkout() {
    setState(() {
      _isWorkoutPaused = false;
      _showSetComplete = false;
      // Reinitialize workout session
      _initializeWorkoutSession();
    });
  }

  Future<void> _saveWorkoutHistory() async {
    if (_workoutSession == null) return;

    await _auth.saveWorkoutHistory(
      exerciseType: widget.exerciseType?.toString() ?? 'unknown',
      setsCompleted: _workoutSession!.targetSets,
      repsPerSet: _workoutSession!.targetRepsPerSet,
      timestamp: DateTime.now(),
    );
  }

  Future<void> _loadUserBaseline() async {
    // Stage 1: Loading user data (0-20%)
    if (mounted) {
      setState(() {
        _loadingProgress = 0.1;
        _loadingStep = "Loading user data...";
      });
    }

    final double? baseline = await _auth.getUserBaseline();

    if (mounted) {
      setState(() {
        if (baseline != null && baseline > 0) {
          _userBaseline = baseline;
        }
        _loadingProgress = 0.2;
        _loadingStep = "Initializing camera...";
      });
    }

    // Simulate camera initialization delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _loadingProgress = 0.4;
        _loadingStep = "Loading AI pose detection model...";
      });
    }

    // Simulate AI model loading (this is where the actual delay happens in reality)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _loadingProgress = 0.8;
        _loadingStep = "Setting up workout session...";
      });
    }

    // Final setup
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _loadingProgress = 1.0;
        _loadingStep = "Ready!";
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
          ? LoadingProgressScreen(
              progress: _loadingProgress,
              currentStep: _loadingStep,
            )
          : Column(
              children: [
                // Top Section: Live Feed (60% height)
                Expanded(
                  flex: 6,
                  child: Stack(
                    children: [
                      LiveFeedSection(
                        targetAngle: exerciseTarget,
                        exerciseType: widget.exerciseType,
                        onAngleUpdate: _handleAngleUpdate,
                        currentRep: _workoutSession?.currentRep,
                        targetReps: _workoutSession?.targetRepsPerSet,
                        currentSet: _workoutSession?.currentSet,
                        targetSets: _workoutSession?.targetSets,
                      ),

                      // Workout Progress Display (Top Left)
                      if (_workoutSession != null)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.tealAccent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Set ${_workoutSession!.currentSet}/${_workoutSession!.targetSets} - ${_workoutSession!.currentSide.name.toUpperCase()}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${_workoutSession!.currentRep}/${_workoutSession!.targetRepsPerSet} Reps",
                                  style: const TextStyle(
                                    color: Colors.tealAccent,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Target Angle Display (Top Right)
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

                      // Overlays
                      if (_workoutSession != null && _showSetComplete)
                        _buildSetCompleteOverlay(),

                      // Side Switch Overlay
                      if (_workoutSession != null && _showSideSwitch)
                        _buildSideSwitchOverlay(),
                    ],
                  ),
                ),

                // Bottom Section: Instruction Area (40% height)
                Expanded(
                  flex: 4,
                  child: InstructionPlayer(
                    onReset: _workoutSession != null ? _resetWorkout : null,
                    onTogglePause: _workoutSession != null
                        ? _togglePause
                        : null,
                    isPaused: _isWorkoutPaused,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSetCompleteOverlay() {
    final bool isWorkoutComplete = _workoutSession!.isWorkoutComplete;

    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isWorkoutComplete ? Icons.emoji_events : Icons.check_circle,
                size: 64,
                color: isWorkoutComplete ? Colors.amber : Colors.teal,
              ),
              const SizedBox(height: 16),
              Text(
                isWorkoutComplete ? "Workout Complete!" : "Set Complete!",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isWorkoutComplete
                    ? "Great job! 💪"
                    : "Rest for ${_workoutSession!.restDurationSeconds} seconds",
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showSetComplete = false;
                  });
                  if (isWorkoutComplete) {
                    Navigator.of(context).pop(); // Return to home
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  isWorkoutComplete ? "Done" : "Continue",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideSwitchOverlay() {
    // Lightweight overlay for better performance on old phones
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_horiz, size: 48, color: Colors.orange),
              const SizedBox(height: 12),
              const Text(
                "Switch Elbow!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${_workoutSession!.currentSide == ExerciseSide.left ? 'Right' : 'Left'} side",
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
