import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  PosePainter(this.poses, this.absoluteImageSize, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Get the fitted rectangle (BoxFit.cover) matches CameraPreview logic
    // We stick to "No Swap" (Vertical) based on User confirmation.
    final sourceSize = absoluteImageSize;
    final fitted = applyBoxFit(BoxFit.cover, sourceSize, size);
    final destination = fitted.destination;

    // Calculate the rect within the canvas (centering it)
    // applyBoxFit returns the geometry, but we need to center that geometry on the canvas.
    // If destination is larger than size (BoxFit.cover), we center it.
    final rect = Alignment.center.inscribe(destination, Offset.zero & size);

    // Style
    final paintJoint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 4.0
      ..color = Colors.yellow;
    final paintBone = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.white;

    for (final pose in poses) {
      Offset transform(PoseLandmark landmark) {
        // Step 1: Normalize (0..1)
        // using raw buffer size
        double px = landmark.x / sourceSize.width;
        double py = landmark.y / sourceSize.height;

        // Step 2: Mirror X (Selfie)
        px = 1.0 - px;

        // Step 3: Map to Fitted Rect
        return Offset(rect.left + px * rect.width, rect.top + py * rect.height);
      }

      // Draw Landmarks
      pose.landmarks.forEach((_, landmark) {
        if (landmark.likelihood > 0.5) {
          canvas.drawCircle(transform(landmark), 5, paintJoint);
        }
      });

      // Draw Bones
      final connections = [
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
        [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
        [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
        [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
        [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
        [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
        [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
        [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
        [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
        [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
      ];

      for (final pair in connections) {
        final joint1 = pose.landmarks[pair[0]];
        final joint2 = pose.landmarks[pair[1]];

        if (joint1 != null &&
            joint2 != null &&
            joint1.likelihood > 0.5 &&
            joint2.likelihood > 0.5) {
          canvas.drawLine(transform(joint1), transform(joint2), paintBone);
        }
      }
    }
  }

  // NOTE: Used internal transform() helper instead of separate methods
  // to keep all logic (Rotation -> Mirror -> Scale -> Offset) tightly coupled.
  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.poses != poses ||
        oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.rotation != rotation;
  }
}
