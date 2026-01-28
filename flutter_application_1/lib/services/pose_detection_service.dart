import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint and defaultTargetPlatform
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:typed_data';
import 'dart:io';

class PoseDetectionService {
  // Singleton pattern
  static final PoseDetectionService _instance =
      PoseDetectionService._internal();
  factory PoseDetectionService() => _instance;
  PoseDetectionService._internal();

  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(),
  );
  bool _isBusy = false;

  Future<List<Pose>> detectPose(
    CameraImage image,
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) async {
    // Throttling: Drop frames if busy
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
      return poses;
    } catch (e) {
      debugPrint('Error detecting pose: $e'); // Changed print to debugPrint
      return [];
    } finally {
      _isBusy = false;
    }
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
    rotation = InputImageRotation.rotation0deg;
    // rotation = InputImageRotation.rotation90deg;
    // rotation = InputImageRotation.rotation270deg;

    debugPrint("DEBUG ROTATION (Forced): $rotation");

    if (rotation == null) return null;

    // 🔥 THE FIX: Strictly Force NV21 for Android
    // We do NOT use auto-detection.
    final format = InputImageFormat.nv21;

    // Byte Stitching using helper
    final bytes = _concatenatePlanes(image.planes);

    final size = Size(image.width.toDouble(), image.height.toDouble());

    final inputImageMetadata = InputImageMetadata(
      size: size,
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
  }

  // Helper to stitch planes
  Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  // Helper for orientations
  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  void dispose() {
    _poseDetector.close();
  }
}
