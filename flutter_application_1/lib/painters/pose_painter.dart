import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  PosePainter(this.poses, this.absoluteImageSize, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Define a "Debug Paint"
    final debugPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 10
      ..style = PaintingStyle.fill;

    // 2. Force draw a circle in the middle of the screen
    canvas.drawCircle(const Offset(200, 200), 50, debugPaint);

    final paintJoint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 4.0
      ..color = Colors.blue;

    final paintBone = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.white;

    for (final pose in poses) {
      // Landmarks
      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
      final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
      final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

      // Check nulls
      if (rightShoulder == null || rightElbow == null || rightWrist == null) {
        continue;
      }

      // Check likelihood > 0.5
      if (rightShoulder.likelihood < 0.5 ||
          rightElbow.likelihood < 0.5 ||
          rightWrist.likelihood < 0.5) {
        continue;
      }

      // Transform coordinates
      final shoulderX = translateX(
        rightShoulder.x,
        rotation,
        size,
        absoluteImageSize,
      );
      final shoulderY = translateY(
        rightShoulder.y,
        rotation,
        size,
        absoluteImageSize,
      );

      final elbowX = translateX(
        rightElbow.x,
        rotation,
        size,
        absoluteImageSize,
      );
      final elbowY = translateY(
        rightElbow.y,
        rotation,
        size,
        absoluteImageSize,
      );

      final wristX = translateX(
        rightWrist.x,
        rotation,
        size,
        absoluteImageSize,
      );
      final wristY = translateY(
        rightWrist.y,
        rotation,
        size,
        absoluteImageSize,
      );

      // Draw Bones
      canvas.drawLine(
        Offset(shoulderX, shoulderY),
        Offset(elbowX, elbowY),
        paintBone,
      );
      canvas.drawLine(
        Offset(elbowX, elbowY),
        Offset(wristX, wristY),
        paintBone,
      );

      // Draw Joints (Radius 8)
      canvas.drawCircle(Offset(shoulderX, shoulderY), 8, paintJoint);
      canvas.drawCircle(Offset(elbowX, elbowY), 8, paintJoint);
      canvas.drawCircle(Offset(wristX, wristY), 8, paintJoint);
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
