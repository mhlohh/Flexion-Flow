import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final bool isRightSide;

  PosePainter(
    this.poses,
    this.absoluteImageSize,
    this.rotation, {
    this.isRightSide = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Get the fitted rectangle (BoxFit.cover) matches CameraPreview logic
    final isRotated =
        rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;

    final sourceSize = isRotated
        ? Size(absoluteImageSize.height, absoluteImageSize.width)
        : absoluteImageSize;

    final fitted = applyBoxFit(BoxFit.cover, sourceSize, size);
    final destination = fitted.destination;
    final rect = Alignment.center.inscribe(destination, Offset.zero & size);

    // Style
    // Active (Neon)
    final paintBoneActive = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          12.0 // Much Thicker
      ..color = const Color(0xFFE100FF);

    final paintJointActive = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth =
          14.0 // Much Thicker
      ..color = Colors.white;

    // Inactive (Dimmed)
    final paintBoneInactive = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..color = const Color(0xFFE100FF).withValues(alpha: 0.2);

    final paintJointInactive = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 10.0
      ..color = Colors.white.withValues(alpha: 0.2);

    for (final pose in poses) {
      Offset transform(PoseLandmark landmark) {
        double px = landmark.x / sourceSize.width;
        double py = landmark.y / sourceSize.height;
        px = 1.0 - px; // Mirror
        return Offset(rect.left + px * rect.width, rect.top + py * rect.height);
      }

      // Helper to draw connection with active/inactive state
      void drawConnection(
        PoseLandmarkType p1,
        PoseLandmarkType p2,
        bool isActive,
      ) {
        final l1 = pose.landmarks[p1];
        final l2 = pose.landmarks[p2];
        if (l1 != null &&
            l2 != null &&
            l1.likelihood > 0.3 && // Lowered from 0.5 to ensure visibility
            l2.likelihood > 0.3) {
          canvas.drawLine(
            transform(l1),
            transform(l2),
            isActive ? paintBoneActive : paintBoneInactive,
          );
        }
      }

      // Helper to draw joint
      void drawJoint(PoseLandmarkType type, bool isActive) {
        final l = pose.landmarks[type];
        if (l != null && l.likelihood > 0.3) {
          // Lowered from 0.5
          canvas.drawCircle(
            transform(l),
            5,
            isActive ? paintJointActive : paintJointInactive,
          );
        }
      }

      // --- DRAW SKELETON ---

      // Torso (Neutral/Active)
      drawConnection(
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.rightShoulder,
        true,
      );
      drawConnection(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, true);
      drawConnection(
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftHip,
        !isRightSide,
      ); // Left side
      drawConnection(
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightHip,
        isRightSide,
      ); // Right side

      // Arms (Conditional)
      drawConnection(
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftElbow,
        !isRightSide,
      );
      drawConnection(
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.leftWrist,
        !isRightSide,
      );
      drawConnection(
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightElbow,
        isRightSide,
      );
      drawConnection(
        PoseLandmarkType.rightElbow,
        PoseLandmarkType.rightWrist,
        isRightSide,
      );

      // Legs (Conditional)
      drawConnection(
        PoseLandmarkType.leftHip,
        PoseLandmarkType.leftKnee,
        !isRightSide,
      );
      drawConnection(
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.leftAnkle,
        !isRightSide,
      );
      drawConnection(
        PoseLandmarkType.rightHip,
        PoseLandmarkType.rightKnee,
        isRightSide,
      );
      drawConnection(
        PoseLandmarkType.rightKnee,
        PoseLandmarkType.rightAnkle,
        isRightSide,
      );

      // --- DRAW JOINTS ---
      pose.landmarks.forEach((type, _) {
        bool isActive = true;
        final name = type.toString();
        if (name.contains("right")) isActive = isRightSide;
        if (name.contains("left")) isActive = !isRightSide;
        drawJoint(type, isActive);
      });
    }
  }

  // NOTE: Used internal transform() helper instead of separate methods
  // to keep all logic (Rotation -> Mirror -> Scale -> Offset) tightly coupled.
  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.poses != poses ||
        oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.rotation != rotation ||
        oldDelegate.isRightSide != isRightSide;
  }
}
