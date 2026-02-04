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
  double _currentAngle = 0.0; // Angle state

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

    // ... (rest of filtering logic)

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
        if (poses.isNotEmpty) {
          final pose = poses.first;
          final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
          final elbow = pose.landmarks[PoseLandmarkType.rightElbow];
          final wrist = pose.landmarks[PoseLandmarkType.rightWrist];

          if (shoulder != null && elbow != null && wrist != null) {
            angle = PoseDetectionService.getAngle(shoulder, elbow, wrist);
          }
        }

        setState(() {
          _poses = poses;
          _currentAngle = angle; // Update state
          _cameraImageSize = Size(
            image.width.toDouble(),
            image.height.toDouble(),
          );
          _rotation =
              InputImageRotation.rotation270deg; // Force 270 per debugging
        });
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
              : const Center(
                  child: CircularProgressIndicator(),
                ), // Loading spinner
          // 2. Pose Painter Overlay
          if (_isCameraInitialized &&
              _poses.isNotEmpty &&
              _cameraImageSize != null &&
              _rotation != null)
            CustomPaint(
              painter: PosePainter(_poses, _cameraImageSize!, _rotation!),
            ),

          // 3. The Score/Angle Overlay
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Angle: ${_currentAngle.toStringAsFixed(1)}°",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
