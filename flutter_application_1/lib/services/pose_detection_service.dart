import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
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
  ) async {
    // Throttling: Drop frames if busy
    if (_isBusy) return [];
    _isBusy = true;

    try {
      final inputImage = _inputImageFromCameraImage(image, camera);
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
  ) {
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[DeviceOrientation.portraitUp]!; // Fixed lookup
      // Basic rotation compensation logic for Android
      // Note: In a real app we might need to listen to device orientation changes
      // but for now we assume portrait mode fixed.
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    // For iOS, the bytes usually need to be FLATTENED if there are multiple planes
    // But basic BGRA8888 usually has 1 plane. YUV420 has 3.
    // MLKit expects specific plane ordering.

    // Concatenating planes for the bytes buffer
    final allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    // Size: Width/Height depend on rotation?
    // MLKit docs say: "The image data size should correspond to the image dimensions"
    // Usually we pass width/height as is from the camera image.
    final size = Size(image.width.toDouble(), image.height.toDouble());

    final inputImageMetadata = InputImageMetadata(
      size: size,
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
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
