import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  PosePainter(this.poses, this.absoluteImageSize, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    // Style: Yellow for Joints, White for Bones (High contrast)
    final paintJoint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 4.0
      ..color = Colors.yellow;

    final paintBone = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.white;

    for (final pose in poses) {
      // 1. Draw All Landmarks (Joints)
      pose.landmarks.forEach((_, landmark) {
        if (landmark.likelihood > 0.5) {
          final x = translateX(landmark.x, rotation, size, absoluteImageSize);
          final y = translateY(landmark.y, rotation, size, absoluteImageSize);
          canvas.drawCircle(Offset(x, y), 5, paintJoint);
        }
      });

      // 2. Define Connections (Bones)
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

      // 3. Draw Bones
      for (final pair in connections) {
        final joint1 = pose.landmarks[pair[0]];
        final joint2 = pose.landmarks[pair[1]];

        if (joint1 != null &&
            joint2 != null &&
            joint1.likelihood > 0.5 &&
            joint2.likelihood > 0.5) {
          final x1 = translateX(joint1.x, rotation, size, absoluteImageSize);
          final y1 = translateY(joint1.y, rotation, size, absoluteImageSize);
          final x2 = translateX(joint2.x, rotation, size, absoluteImageSize);
          final y2 = translateY(joint2.y, rotation, size, absoluteImageSize);

          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paintBone);
        }
      }
    }
  }

  double translateX(
    double x,
    InputImageRotation rotation,
    Size size,
    Size absoluteImageSize,
  ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        // Swap width and height for portrait
        return size.width - (x * size.width / absoluteImageSize.height);
      default:
        return x * size.width / absoluteImageSize.width;
    }
  }

  double translateY(
    double y,
    InputImageRotation rotation,
    Size size,
    Size absoluteImageSize,
  ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        // Swap width and height for portrait
        return y * size.height / absoluteImageSize.width;
      default:
        return y * size.height / absoluteImageSize.height;
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.poses != poses ||
        oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.rotation != rotation;
  }
}
