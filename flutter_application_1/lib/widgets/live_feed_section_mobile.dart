import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../main.dart'; // Import to access the 'cameras' list
import '../services/pose_detection_service.dart';
import '../painters/pose_painter.dart';
import 'glass_feedback_panel.dart'; // Import the new widget
import '../enums/exercise_type.dart'; // Import ExerciseType enum

class LiveFeedSection extends StatefulWidget {
  final Function(double)? onAngleUpdate;
  final double? targetAngle;
  final ExerciseType? exerciseType;
  final int? currentRep;
  final int? targetReps;
  final int? currentSet;
  final int? targetSets;

  const LiveFeedSection({
    super.key,
    this.onAngleUpdate,
    this.targetAngle,
    this.exerciseType,
    this.currentRep,
    this.targetReps,
    this.currentSet,
    this.targetSets,
  });

  @override
  State<LiveFeedSection> createState() => _LiveFeedSectionState();
}

class _LiveFeedSectionState extends State<LiveFeedSection> {
  CameraController? _controller; // Nullable because it might not load instantly
  bool _isCameraInitialized = false;
  final PoseDetectionService _poseDetectionService = PoseDetectionService();

  // State for Visualization
  List<Pose> _poses = [];
  Size? _cameraImageSize;
  InputImageRotation? _rotation;
  CameraDescription? _frontCamera;

  // Feedback State
  double _currentAngle = 0.0;
  String _feedbackMessage = "Keep Moving";
  Color _feedbackColor = Colors.orange;
  bool _isRightSide = true;
  DateTime _lastValidPoseTime = DateTime.now(); // For Persistence Logic
  final int _sideSwitchCounter = 0; // Debounce counter for side switching

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeCamera();
    }
  }

  // Logic to find the FRONT camera (since this is a selfie app)
  void _initializeCamera() async {
    if (cameras.isEmpty) return;

    // Find the front-facing camera
    _frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first, // Fallback to back camera if no front camera
    );

    _controller = CameraController(
      _frontCamera!,
      ResolutionPreset.medium, // 'medium' (480p) for better performance
      enableAudio: false, // We don't need audio for vision
      imageFormatGroup: ImageFormatGroup.yuv420, // Required for Android ML Kit
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;

      // Start streaming images for pose detection
      // on Web calling startImageStream might fail or cause issues if not supported
      await _controller!.startImageStream((CameraImage image) async {
        final poses = await _poseDetectionService.detectPose(
          image,
          _frontCamera!,
          _controller!.value.deviceOrientation,
        );

        if (!mounted) return;

        if (!mounted) return;

        // Calculate Angle for UI
        double angle = _currentAngle; // Default to last known
        String message = _feedbackMessage;
        Color color = _feedbackColor;
        bool isRight = _isRightSide;
        List<Pose> posesToDisplay = _poses; // Default to holding last pose

        // PERSISTENCE LOGIC
        // If we found a pose, update everything
        if (poses.isNotEmpty) {
          posesToDisplay = poses;
          _lastValidPoseTime = DateTime.now(); // Reset timer

          final pose = poses.first;
          // Side Detection Logic
          // ROBUST SIDE SWITCHING: Simple Hysteresis (Like Web)
          // Summing Likelihoods (0.0 - 3.0)
          final double leftScore =
              (pose.landmarks[PoseLandmarkType.leftShoulder]?.likelihood ?? 0) +
              (pose.landmarks[PoseLandmarkType.leftElbow]?.likelihood ?? 0) +
              (pose.landmarks[PoseLandmarkType.leftWrist]?.likelihood ?? 0);

          final double rightScore =
              (pose.landmarks[PoseLandmarkType.rightShoulder]?.likelihood ??
                  0) +
              (pose.landmarks[PoseLandmarkType.rightElbow]?.likelihood ?? 0) +
              (pose.landmarks[PoseLandmarkType.rightWrist]?.likelihood ?? 0);

          // Buffer: Change side only if Other > Current + 0.2
          // This worked perfectly on Web.
          if (leftScore > rightScore + 0.2) {
            isRight = false;
          } else if (rightScore > leftScore + 0.2) {
            isRight = true;
          }

          // Extract Landmarks for Active Side
          final shoulder =
              pose.landmarks[isRight
                  ? PoseLandmarkType.rightShoulder
                  : PoseLandmarkType.leftShoulder];
          final elbow =
              pose.landmarks[isRight
                  ? PoseLandmarkType.rightElbow
                  : PoseLandmarkType.leftElbow];
          final wrist =
              pose.landmarks[isRight
                  ? PoseLandmarkType.rightWrist
                  : PoseLandmarkType.leftWrist];

          // Check for VALIDITY before calculating Angle
          // Prevent calculating "stuck" angles from ghost limbs
          bool isValid =
              shoulder != null &&
              shoulder.likelihood > 0.4 &&
              elbow != null &&
              elbow.likelihood > 0.4 &&
              wrist != null &&
              wrist.likelihood > 0.4;

          if (isValid) {
            angle = PoseDetectionService.getAngle(shoulder, elbow, wrist);

            // Callback for Calibration
            if (widget.onAngleUpdate != null) {
              widget.onAngleUpdate!(angle);
            }

            // Feedback Logic
            // Use dynamic target if provided, else default to 160
            final double target = widget.targetAngle ?? 160;

            if (widget.exerciseType == ExerciseType.elbowFlexion) {
              // Specific Logic for Elbow Flexion (Bicep Curl)
              if (angle < 50) {
                color = Colors.green;
                message = "Good Curl!";
              } else if (angle > 160) {
                color = Colors.blue;
                message = "Fully Extended";
              } else {
                message = "Keep going...";
                color = Colors.orange;
              }
            } else {
              // Default / Calibration Logic
              if (angle < 60) {
                // Relaxed to 60 for Mobile
                color = Colors.blue;
                message = "FLEXED";
              } else if (angle > target) {
                color = Colors.green;
                message = "EXTENDED"; // Or "GOOD HOLD"
              } else {
                message = "MOVING";
              }
            }
          } else {
            // OPTIONAL: If confidence drops, keep old angle?
            // Or maybe dim text color? For now, we keep old angle but don't update junk.
          }
        } else {
          // NO POSE DETECTED
          // Check if we typically assume the user is still there (Persistence)
          // If < 2 seconds since last pose, KEEP DISPLAYING OLD DATA
          if (DateTime.now().difference(_lastValidPoseTime).inMilliseconds <
              2000) {
            // Do NOT clear posesToDisplay. Keep it as _poses.
            // Do NOT change angle/message.
          } else {
            // Timed out. Clear screen.
            posesToDisplay = [];
            angle = 0.0;
            message = "Keep Moving";
          }
        }

        // Only update UI if there are actual changes
        if (posesToDisplay.isNotEmpty || _poses.isNotEmpty) {
          bool shouldUpdate =
              posesToDisplay.length != _poses.length ||
              (_currentAngle - angle).abs() > 0.5 ||
              message != _feedbackMessage ||
              isRight != _isRightSide;

          if (shouldUpdate) {
            if (mounted) {
              setState(() {
                _poses = posesToDisplay;
                _currentAngle = angle;
                _feedbackMessage = message;
                _feedbackColor = color;
                _isRightSide = isRight;
                _cameraImageSize = Size(
                  image.width.toDouble(),
                  image.height.toDouble(),
                );
                _rotation = InputImageRotation.rotation270deg;
              });
            }
          }
        }
      });

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print("Camera crash: $e");
    }
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // ... (web check) ...
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            "Camera Pose Detection not supported on Web.\nPlease use Android/iOS.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. The Camera Feed
          _isCameraInitialized &&
                  _controller != null &&
                  _controller!.value.isInitialized
              ? CameraPreview(_controller!)
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        "Initializing Camera...",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
          // 2. Pose Painter Overlay
          if (_isCameraInitialized &&
              _poses.isNotEmpty &&
              _cameraImageSize != null &&
              _rotation != null)
            CustomPaint(
              painter: PosePainter(
                _poses,
                _cameraImageSize!,
                _rotation!,
                isRightSide: _isRightSide,
              ),
            ),

          // 3. Glassmorphic Feedback Panel (Fixed Position)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Center(
              child: GlassFeedbackPanel(
                angle: _currentAngle,
                feedback: _feedbackMessage,
                color: _feedbackColor,
                currentRep: widget.currentRep,
                targetReps: widget.targetReps,
                currentSet: widget.currentSet,
                targetSets: widget.targetSets,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
