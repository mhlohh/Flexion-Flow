import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../main.dart'; // Import to access the 'cameras' list
import '../services/pose_detection_service.dart';

class LiveFeedSection extends StatefulWidget {
  const LiveFeedSection({super.key});

  @override
  State<LiveFeedSection> createState() => _LiveFeedSectionState();
}

class _LiveFeedSectionState extends State<LiveFeedSection> {
  CameraController? _controller; // Nullable because it might not load instantly
  bool _isCameraInitialized = false;
  final PoseDetectionService _poseDetectionService = PoseDetectionService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Logic to find the FRONT camera (since this is a selfie app)
  void _initializeCamera() async {
    if (cameras.isEmpty) return;

    // Find the front-facing camera
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first, // Fallback to back camera if no front camera
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset
          .medium, // 'medium' is enough for ML Kit (480p/720p). Don't use 'max' or 'ultraHigh', it overheats the phone.
      enableAudio: false, // We don't need audio for vision
      imageFormatGroup: ImageFormatGroup.yuv420, // Required for Android ML Kit
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;

      // Start streaming images for pose detection
      await _controller!.startImageStream((CameraImage image) async {
        final poses = await _poseDetectionService.detectPose(
          image,
          frontCamera,
        );
        if (poses.isNotEmpty) {
          // For verification: Print Right Elbow coordinates
          final pose = poses.first;
          final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
          if (rightElbow != null) {
            print('Elbow Pos: x=${rightElbow.x}, y=${rightElbow.y}');
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
    _controller
        ?.dispose(); // CRITICAL: Failure to do this will crash the app on restart
    // Note: We don't dispose the singleton service here as it might be used elsewhere,
    // but if we wanted to close the detector we could add a method for that.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 60% of the screen height is handled by the parent Column,
    // so we just fill the available space here.
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
          // 2. The Score Overlay (Static for now)
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Score: 0",
                style: TextStyle(
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
