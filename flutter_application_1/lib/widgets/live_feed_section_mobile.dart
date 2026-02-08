import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../main.dart'; // Import to access the 'cameras' list
import '../services/pose_detection_service.dart';
import '../painters/pose_painter.dart';

class LiveFeedSection extends StatefulWidget {
  const LiveFeedSection({super.key});

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
  double _currentAngle = 0.0;
  String _feedbackMessage = "Keep Moving";
  Color _feedbackColor = Colors.orange;

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
      ResolutionPreset.medium, // 'medium' is enough for ML Kit (480p/720p).
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

        // 🔥 DEBUG
        debugPrint("🔥🔥🔥 DETECTED POSES: ${poses.length}");

        // Calculate Angle
        double angle = 0.0;
        String message = "Keep Moving";
        Color color = Colors.orange;

        if (poses.isNotEmpty) {
          final pose = poses.first;
          final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
          final elbow = pose.landmarks[PoseLandmarkType.rightElbow];
          final wrist = pose.landmarks[PoseLandmarkType.rightWrist];

          if (shoulder != null && elbow != null && wrist != null) {
            angle = PoseDetectionService.getAngle(shoulder, elbow, wrist);

            // Feedback Logic
            if (angle < 50) {
              color = Colors.green;
              message = "Good Hold";
            } else if (angle > 160) {
              color = Colors.blue;
              message = "Fully Extended";
            }
          }
        }

        // Only update UI if there are actual changes
        if (poses.isNotEmpty || _poses.isNotEmpty) {
          // Check if we need to update (avoid unnecessary setState)
          bool shouldUpdate =
              poses.length != _poses.length ||
              (_currentAngle - angle).abs() >
                  0.5 || // Only update if angle changed by >0.5°
              message != _feedbackMessage;

          if (shouldUpdate) {
            setState(() {
              _poses = poses;
              _currentAngle = angle;
              _feedbackMessage = message;
              _feedbackColor = color;
              _cameraImageSize = Size(
                image.width.toDouble(),
                image.height.toDouble(),
              );
              _rotation = InputImageRotation.rotation270deg;
            });
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
          _isCameraInitialized
              ? CameraPreview(_controller!)
              : const Center(child: CircularProgressIndicator()),
          // 2. Pose Painter Overlay
          if (_isCameraInitialized &&
              _poses.isNotEmpty &&
              _cameraImageSize != null &&
              _rotation != null)
            CustomPaint(
              painter: PosePainter(_poses, _cameraImageSize!, _rotation!),
            ),

          // 3. The Score/Angle Overlay (Safe Area + Aligned)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87, // High contrast opaque background
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Angle: ${_currentAngle.toStringAsFixed(1)}°",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _feedbackMessage,
                      style: TextStyle(
                        color: _feedbackColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
