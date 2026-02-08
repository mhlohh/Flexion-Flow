import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint and defaultTargetPlatform
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math; // Import math at top

class PoseDetectionService {
  // Singleton pattern
  static final PoseDetectionService _instance =
      PoseDetectionService._internal();
  factory PoseDetectionService() => _instance;
  PoseDetectionService._internal();

  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream, // Optimized for real-time video
      model:
          PoseDetectionModel.accurate, // Best quality (slower but more precise)
    ),
  );
  bool _isBusy = false;

  // Smoothing state
  Map<PoseLandmarkType, PoseLandmark>? _previousLandmarks;
  final double _landmarkSmoothingFactor =
      0.7; // Stronger smoothing for stability

  // Smoothing for angle measurements (Deprecated - using landmark smoothing instead)
  double? _previousAngle;
  // _smoothingFactor removed as it's no longer used

  DateTime _lastPoseTime = DateTime.now(); // Added for persistence

  Future<List<Pose>> detectPose(
    CameraImage image,
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) async {
    // Frame throttling (REMOVED for maximum smoothness)
    // We rely on _isBusy to prevent overlapping calls.
    // _frameCount++;
    // if (_frameCount % _processEveryNthFrame != 0) return [];

    // Throttling
    if (_isBusy) return [];
    _isBusy = true;

    try {
      final inputImage = _inputImageFromCameraImage(
        image,
        camera,
        deviceOrientation,
      );
      if (inputImage == null) return [];

      final poses = await _poseDetector.processImage(inputImage);

      // Persistence Logic: If no pose found, return last known pose for short duration
      if (poses.isEmpty) {
        if (_previousLandmarks != null &&
            DateTime.now().difference(_lastPoseTime).inMilliseconds < 300) {
          // Return phantom pose to prevent flicker
          return [Pose(landmarks: _previousLandmarks!)];
        }
        return [];
      }

      // Found a pose! Update timestamp and smooth
      _lastPoseTime = DateTime.now();

      // Apply smoothing to the first pose (assuming single user)
      final rawPose = poses.first;
      final smoothedPose = _smoothPose(rawPose);

      return [smoothedPose];
    } catch (e) {
      debugPrint('Error detecting pose: $e');
      return [];
    } finally {
      _isBusy = false;
    }
  }

  // Smooth all landmarks in a pose
  Pose _smoothPose(Pose rawPose) {
    if (_previousLandmarks == null) {
      _previousLandmarks = rawPose.landmarks;
      return rawPose;
    }

    final Map<PoseLandmarkType, PoseLandmark> smoothedLandmarks = {};

    rawPose.landmarks.forEach((type, currentLandmark) {
      final previousLandmark = _previousLandmarks![type];

      if (currentLandmark.likelihood < 0.6) {
        // If confidence is low, don't smooth. Just use current (or could return null if strict)
        // Resetting smoothing for this landmark might be better to avoid dragging it
        smoothedLandmarks[type] = currentLandmark;
      } else if (previousLandmark == null) {
        smoothedLandmarks[type] = currentLandmark;
      } else {
        // Apply EWMA smoothing to X, Y, and Z
        final double smoothX =
            (_landmarkSmoothingFactor * currentLandmark.x) +
            ((1 - _landmarkSmoothingFactor) * previousLandmark.x);

        final double smoothY =
            (_landmarkSmoothingFactor * currentLandmark.y) +
            ((1 - _landmarkSmoothingFactor) * previousLandmark.y);

        final double smoothZ =
            (_landmarkSmoothingFactor * currentLandmark.z) +
            ((1 - _landmarkSmoothingFactor) * previousLandmark.z);

        // Confidence is generally just taken from the current frame
        // or could be smoothed too, but raw is usually safer for filtering.
        smoothedLandmarks[type] = PoseLandmark(
          type: type,
          x: smoothX,
          y: smoothY,
          z: smoothZ,
          likelihood: currentLandmark.likelihood,
        );
      }
    });

    _previousLandmarks = smoothedLandmarks;

    // Return a NEW Pose object with smoothed landmarks
    return Pose(landmarks: smoothedLandmarks);
  }

  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      var rotationCompensation = _orientations[deviceOrientation];
      if (rotationCompensation == null) return null;

      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    // 🔥 DEBUG: Log the calculated rotation
    debugPrint("DEBUG ROTATION (Calculated): $rotation");

    // TEMPORARY HACK: Force Hardcode rotation for Debugging
    // Try these one by one:
    // rotation = InputImageRotation.rotation0deg;
    // rotation = InputImageRotation.rotation90deg;
    rotation = InputImageRotation.rotation270deg;

    debugPrint("DEBUG ROTATION (Forced): $rotation");

    final format = InputImageFormat.nv21;

    // Use the Smart Converter (Handles Strides/Padding)
    final bytes = _convertYUV420ToNV21(image);

    final size = Size(image.width.toDouble(), image.height.toDouble());

    final inputImageMetadata = InputImageMetadata(
      size: size,
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
  }

  // ------------------------------------------------------------------------
  // 3. INTERNAL HELPER: Convert YUV420 to NV21 (Handling Padding/Strides)
  // ------------------------------------------------------------------------
  Uint8List _convertYUV420ToNV21(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    final numPixels = width * height;
    final nv21 = Uint8List(numPixels + (numPixels ~/ 2));

    // --- Copy Y Plane (Row by Row to skip padding) ---
    int idY = 0;
    for (int y = 0; y < height; y++) {
      final yOffset = y * yPlane.bytesPerRow;
      for (int x = 0; x < width; x++) {
        nv21[idY++] = yBuffer[yOffset + x];
      }
    }

    // --- Interleave VU (NV21 expects V then U) ---
    int idUV = numPixels;
    final uvWidth = width ~/ 2;
    final uvHeight = height ~/ 2;
    final uvPixelStride = 1; // Assuming Planar because of emulator behavior

    for (int y = 0; y < uvHeight; y++) {
      final uOffset = y * uPlane.bytesPerRow;
      final vOffset = y * vPlane.bytesPerRow;

      for (int x = 0; x < uvWidth; x++) {
        // NV21 = V, then U
        nv21[idUV++] = vBuffer[vOffset + (x * uvPixelStride)];
        nv21[idUV++] = uBuffer[uOffset + (x * uvPixelStride)];
      }
    }
    return nv21;
  }

  // Helper for orientations
  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  // Calculate the angle between three points (Shoulder -> Elbow -> Wrist)
  static double getAngle(
    PoseLandmark firstPoint,
    PoseLandmark midPoint,
    PoseLandmark lastPoint,
  ) {
    final double result =
        math.atan2(lastPoint.y - midPoint.y, lastPoint.x - midPoint.x) -
        math.atan2(firstPoint.y - midPoint.y, firstPoint.x - midPoint.x);

    double angle = result * (180 / math.pi); // Convert radians to degrees

    // Ensure the angle is always positive and within 0-180 range
    angle = angle.abs();
    if (angle > 180) {
      angle = 360.0 - angle;
    }

    return angle;
  }

  // Get the current smoothed angle (returns null if no angle detected yet)
  double? get currentSmoothedAngle => _previousAngle;

  void dispose() {
    _poseDetector.close();
  }
}
