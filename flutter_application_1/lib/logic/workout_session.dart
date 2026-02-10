import '../enums/exercise_type.dart';

/// Manages workout session state including sets, reps, and rep detection
class WorkoutSession {
  final int targetSets;
  final int targetRepsPerSet;
  final int restDurationSeconds;
  final bool isBilateral; // Track if exercise uses both sides
  final ExerciseType exerciseType; // Type of exercise being tracked

  int currentSet = 1;
  int currentRep = 0;
  ExerciseSide currentSide = ExerciseSide.left; // Start with left side
  RepState _state = RepState.extended;

  // Callbacks for state changes
  final Function(int rep)? onRepCompleted;
  final Function(ExerciseSide side)?
  onSideCompleted; // New callback for side completion
  final Function(int set)? onSetCompleted;
  final Function()? onWorkoutCompleted;

  WorkoutSession({
    required this.targetSets,
    required this.targetRepsPerSet,
    required this.exerciseType,
    this.isBilateral = true, // Default to bilateral
    this.restDurationSeconds = 60,
    this.onRepCompleted,
    this.onSideCompleted,
    this.onSetCompleted,
    this.onWorkoutCompleted,
  });

  /// Update the session with the current angle measurement
  void updateAngle(double angle) {
    // Exercise-specific angle thresholds
    switch (exerciseType) {
      case ExerciseType.elbowFlexion:
        _updateElbowFlexion(angle);
        break;
      case ExerciseType.shoulderAbduction:
        _updateShoulderAbduction(angle);
        break;
      case ExerciseType.calibration:
        // Calibration doesn't use rep detection
        break;
    }
  }

  /// Elbow Flexion: Extended (>160°) → Flexed (<50°) → Extended
  void _updateElbowFlexion(double angle) {
    switch (_state) {
      case RepState.extended:
        if (angle < 60) {
          _state = RepState.flexing;
        }
        break;

      case RepState.flexing:
        if (angle < 50) {
          _state = RepState.flexed;
        } else if (angle >= 160) {
          _state = RepState.extended;
        }
        break;

      case RepState.flexed:
        if (angle > 140) {
          _state = RepState.extending;
        }
        break;

      case RepState.extending:
        if (angle > 160) {
          _state = RepState.extended;
          _completeRep();
        } else if (angle < 50) {
          _state = RepState.flexed;
        }
        break;
    }
  }

  /// Shoulder Abduction: Extended (>160°) → Abducted (<30°) → Extended
  void _updateShoulderAbduction(double angle) {
    switch (_state) {
      case RepState.extended:
        if (angle < 100) {
          // Starting to abduct (raise arm)
          _state = RepState.flexing; // Reusing flexing state for abducting
        }
        break;

      case RepState.flexing: // Abducting phase
        if (angle < 30) {
          // Reached full abduction (arm raised)
          _state = RepState.flexed; // Reusing flexed state for abducted
        } else if (angle >= 160) {
          // Returned to starting position without completing
          _state = RepState.extended;
        }
        break;

      case RepState.flexed: // Abducted (arm up)
        if (angle > 100) {
          // Starting to adduct (lower arm)
          _state = RepState.extending; // Reusing extending state for adducting
        }
        break;

      case RepState.extending: // Adducting phase
        if (angle > 160) {
          // Returned to starting position - REP COMPLETE!
          _state = RepState.extended;
          _completeRep();
        } else if (angle < 30) {
          // Raised arm again without completing
          _state = RepState.flexed;
        }
        break;
    }
  }

  void _completeRep() {
    currentRep++;
    onRepCompleted?.call(currentRep);

    // Check if side is complete (for bilateral exercises)
    if (isBilateral && currentRep >= targetRepsPerSet) {
      _completeSide();
    } else if (!isBilateral && currentRep >= targetRepsPerSet) {
      // For unilateral exercises, complete the set directly
      _completeSet();
    }
  }

  void _completeSide() {
    if (currentSide == ExerciseSide.left) {
      // Switch to right side - Reset state FIRST for immediate response
      currentSide = ExerciseSide.right;
      currentRep = 0;
      _state = RepState.extended;

      // THEN notify UI (this shows overlay, but state is already ready)
      onSideCompleted?.call(ExerciseSide.left);
    } else {
      // Both sides complete, move to next set
      _completeSet();
    }
  }

  void _completeSet() {
    onSetCompleted?.call(currentSet);

    if (currentSet >= targetSets) {
      // Workout complete!
      onWorkoutCompleted?.call();
    } else {
      // Move to next set, reset to left side
      currentSet++;
      currentRep = 0;
      currentSide = ExerciseSide.left;
      _state = RepState.extended;
    }
  }

  /// Manually trigger set completion (for rest timer skip)
  void skipToNextSet() {
    if (currentSet < targetSets) {
      currentSet++;
      currentRep = 0;
      _state = RepState.extended;
    }
  }

  /// Reset the workout session
  void reset() {
    currentSet = 1;
    currentRep = 0;
    _state = RepState.extended;
  }

  // Getters
  bool get isSetComplete => currentRep >= targetRepsPerSet;
  bool get isWorkoutComplete => currentSet > targetSets;
  double get overallProgress =>
      ((currentSet - 1) * targetRepsPerSet + currentRep) /
      (targetSets * targetRepsPerSet);
  String get progressText =>
      "Set $currentSet/$targetSets | Rep $currentRep/$targetRepsPerSet";
}

/// Enum representing the state of a repetition cycle
enum RepState {
  extended, // Arm fully extended (>160°)
  flexing, // Moving from extended to flexed
  flexed, // Arm fully flexed (<50°)
  extending, // Moving from flexed to extended
}

/// Enum representing which side is being exercised
enum ExerciseSide { left, right }
