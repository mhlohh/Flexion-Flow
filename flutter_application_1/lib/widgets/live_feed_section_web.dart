import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe'; // For getProperty
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'glass_feedback_panel.dart'; // Import Glass Widget
import '../enums/exercise_type.dart'; // Import ExerciseType enum

class LiveFeedSection extends StatefulWidget {
  final Function(double)? onAngleUpdate;
  final double? targetAngle;
  final ExerciseType? exerciseType;
  final int? currentRep;
  final int? targetReps;
  final int? currentSet;
  final int? targetSets;

  const LiveFeedSection({
    super.key,
    this.onAngleUpdate,
    this.targetAngle,
    this.exerciseType,
    this.currentRep,
    this.targetReps,
    this.currentSet,
    this.targetSets,
  });

  @override
  State<LiveFeedSection> createState() => _LiveFeedSectionState();
}

class _LiveFeedSectionState extends State<LiveFeedSection> {
  final web.HTMLVideoElement _videoElement = web.HTMLVideoElement()
    ..autoplay = true
    ..muted = true;
  bool _isCameraInitialized = false;
  List<dynamic> _webLandmarks = [];
  Size _videoSize = Size.zero;

  // Feedback State
  double _currentAngle = 0.0;
  String _feedbackMessage = "Keep Moving";
  Color _feedbackColor = Colors.orange;
  bool _isRightSide = true; // Track dominant side

  @override
  void initState() {
    super.initState();
    _initializeWebCamera();
  }

  void _initializeWebCamera() async {
    // register factory
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      'web-camera-view',
      (int viewId) => _videoElement,
    );

    // Ensure video scales correctly in the view
    _videoElement.style.width = '100%';
    _videoElement.style.height = '100%';
    _videoElement.style.objectFit = 'contain';

    try {
      print('🚀 [Web] Requesting camera access...');
      final mediaStream = await web.window.navigator.mediaDevices
          .getUserMedia(web.MediaStreamConstraints(video: true.toJS))
          .toDart;

      print('✅ [Web] Camera access granted.');
      _videoElement.srcObject = mediaStream;

      // Wait for metadata to get dimensions
      // onLoadedMetadata is a stream in dart:html, but in package:web it's an event.
      // We can wrap it in a completer or just verify dimensions in the listener.
      // Simple approach: Poll or one-shot listener.

      final completer = Completer<void>();
      _videoElement.onloadedmetadata = (web.Event e) {
        if (!completer.isCompleted) completer.complete();
      }.toJS;

      await completer.future;

      print(
        '📏 [Web] Video Size: ${_videoElement.videoWidth} x ${_videoElement.videoHeight}',
      );

      setState(() {
        _videoSize = Size(
          _videoElement.videoWidth.toDouble(),
          _videoElement.videoHeight.toDouble(),
        );
      });

      // Initialize JS Worker
      print('🔧 [Web] Initializing JS Worker...');

      final onPoseResults = (JSAny? landmarks) {
        if (!mounted) return;

        print('🎯 Dart callback received data');

        if (landmarks != null) {
          try {
            final jsArray = landmarks as JSArray;
            final list = jsArray.toDart;

            print('📦 Converted list length: ${list.length}');

            if (list.isNotEmpty) {
              // Calculate Angle
              double angle = _currentAngle;
              String message = _feedbackMessage;
              Color color = _feedbackColor;
              bool isRight = _isRightSide; // Keep current by default

              // Indexes for Right Arm: 12 (Shoulder), 14 (Elbow), 16 (Wrist)
              if (list.length > 20) {
                // Side Detection (Visibility Hysteresis)
                // Left: 11, 13, 15
                // Right: 12, 14, 16
                final double leftScore =
                    _getLikelihood(list, 11) +
                    _getLikelihood(list, 13) +
                    _getLikelihood(list, 15);
                final double rightScore =
                    _getLikelihood(list, 12) +
                    _getLikelihood(list, 14) +
                    _getLikelihood(list, 16);

                // Buffer: Change side only if significant (> 0.2 diff)
                if (leftScore > rightScore + 0.2) {
                  isRight = false;
                } else if (rightScore > leftScore + 0.2) {
                  isRight = true;
                }

                // Get landmarks for the ACTIVE side
                final p1 = _getRawLandmark(list, isRight ? 12 : 11); // Shoulder
                final p2 = _getRawLandmark(list, isRight ? 14 : 13); // Elbow
                final p3 = _getRawLandmark(list, isRight ? 16 : 15); // Wrist

                if (p1 != null && p2 != null && p3 != null) {
                  angle = _calculateAngle(p1, p2, p3);
                  // Feedback Logic
                  final double target = widget.targetAngle ?? 160;

                  if (widget.exerciseType == ExerciseType.elbowFlexion) {
                    if (angle < 50) {
                      color = Colors.green;
                      message = "Good Curl!";
                    } else if (angle > 160) {
                      color = Colors.blue;
                      message = "Fully Extended";
                    } else {
                      message = "Keep going...";
                      color = Colors.orange;
                    }
                  } else {
                    // Default
                    if (angle < 50) {
                      color = Colors.blue;
                      message = "FLEXED";
                    } else if (angle > target) {
                      color = Colors.green;
                      message = "EXTENDED";
                    } else {
                      message = "MOVING";
                    }
                  }

                  // Trigger callback
                  if (widget.onAngleUpdate != null) {
                    widget.onAngleUpdate!(angle);
                  }
                }
              }

              setState(() {
                _webLandmarks = list;
                _currentAngle = angle;
                _feedbackMessage = message;
                _feedbackColor = color;
                _isRightSide = isRight;
              });
            }
          } catch (e) {
            print('🚨 Dart Error: $e');
          }
        } else {
          print('⚠️ Landmarks is null');
        }
      }.toJS;

      // Access global poseWorker with retry
      JSObject? worker;
      int attempts = 0;
      while (attempts < 10) {
        worker = web.window.getProperty('poseWorker'.toJS) as JSObject?;
        if (worker != null) break;
        print('⏳ [Web] Waiting for poseWorker... ($attempts)');
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      if (worker != null) {
        print('✅ [Web] poseWorker found! Calling initialize...');

        // Direct property set to ensure it exists
        worker.setProperty('onResultsCallback'.toJS, onPoseResults);

        // Pass it in initialize too, just in case
        worker.callMethod('initialize'.toJS, null, onPoseResults);

        print('✅ [Web] Calling startCamera...');
        worker.callMethod('startCamera'.toJS, _videoElement);
      } else {
        print(
          '❌ [Web] poseWorker is NULL after retries. Check index.html imports.',
        );
      }

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('🚨 [Web] Camera Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isCameraInitialized)
            HtmlElementView(viewType: 'web-camera-view')
          else
            const Center(child: CircularProgressIndicator()),

          // Painter
          if (_webLandmarks.isNotEmpty && _videoSize != Size.zero)
            CustomPaint(
              painter: WebPosePainter(
                landmarks: _webLandmarks,
                sourceSize: _videoSize,
                isRightSide: _isRightSide,
              ),
            ),

          // Glassmorphic Feedback Overlay
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Center(
              child: GlassFeedbackPanel(
                angle: _currentAngle,
                feedback: _feedbackMessage,
                color: _feedbackColor,
                currentRep: widget.currentRep,
                targetReps: widget.targetReps,
                currentSet: widget.currentSet,
                targetSets: widget.targetSets,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to extract x,y from the raw JS List
  Offset? _getRawLandmark(List<dynamic> landmarks, int index) {
    if (index >= landmarks.length) return null;
    final lm = landmarks[index];
    if (lm == null) return null;

    try {
      final lmObj = lm as JSObject;
      // x, y are normalized [0,1]
      final x = (lmObj.getProperty('x'.toJS) as JSNumber).toDartDouble;
      final y = (lmObj.getProperty('y'.toJS) as JSNumber).toDartDouble;
      return Offset(x, y);
      return Offset(x, y);
    } catch (e) {
      return null;
    }
  }

  double _getLikelihood(List<dynamic> landmarks, int index) {
    if (index >= landmarks.length) return 0.0;
    final lm = landmarks[index];
    if (lm == null) return 0.0;

    try {
      final lmObj = lm as JSObject;
      // Try 'visibility' (MediaPipe standard) or 'score'
      // We'll check for visibility first
      if (lmObj.hasProperty('visibility'.toJS).toDart) {
        return (lmObj.getProperty('visibility'.toJS) as JSNumber).toDartDouble;
      }
      if (lmObj.hasProperty('score'.toJS).toDart) {
        return (lmObj.getProperty('score'.toJS) as JSNumber).toDartDouble;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  double _calculateAngle(Offset first, Offset middle, Offset last) {
    // atan2(y, x)
    final double result =
        math.atan2(last.dy - middle.dy, last.dx - middle.dx) -
        math.atan2(first.dy - middle.dy, first.dx - middle.dx);
    double angle = result.abs() * 180.0 / math.pi;

    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }
}

class WebPosePainter extends CustomPainter {
  final List<dynamic> landmarks; // JSObjects or Maps
  final Size sourceSize;
  final bool isRightSide;

  WebPosePainter({
    required this.landmarks,
    required this.sourceSize,
    this.isRightSide = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    // SCALING LOGIC:
    // Scale the sourceSize (camera resolution) to fit within the widget size (canvas)
    // keeping aspect ratio.
    // scale logic
    final fitted = applyBoxFit(BoxFit.contain, sourceSize, size);
    final destinationSize = fitted.destination;
    final sourceRect = Alignment.center.inscribe(
      destinationSize,
      Offset.zero & size,
    );

    // DEBUG: Draw border around active area
    // canvas.drawRect(sourceRect, Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth = 2);

    // PAINTS
    // Active
    final paintBoneActive = Paint()
      ..color = const Color(0xFFE100FF)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final paintJointActive = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final paintJointBorderActive = Paint()
      ..color = const Color(0xFFE100FF)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Inactive (Dimmed)
    final paintBoneInactive = Paint()
      ..color = const Color(0xFFE100FF).withValues(alpha: 0.2)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final paintJointInactive = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final paintJointBorderInactive = Paint()
      ..color = const Color(0xFFE100FF).withValues(alpha: 0.2)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // CONNECTIONS (Body parts)
    // We split them by side
    final torso = [
      [11, 12], [23, 24], // Shoulders, Hips
      [11, 23], [12, 24], // Sides
    ]; // 11=LeftShoulder, 12=RightShoulder, 23=LeftHip, 24=RightHip

    // Explicit Side Connections
    // Left: 11-13 (Sh-Elb), 13-15 (Elb-Wri), 11-23 (Body-L), 23-25 (Hip-Knee), 25-27 (Knee-Ank)
    // Right: 12-14, 14-16, 12-24, 24-26, 26-28

    void drawConnection(int startIdx, int endIdx, bool isActive) {
      final start = _getLandmark(startIdx, sourceRect);
      final end = _getLandmark(endIdx, sourceRect);
      if (start != null && end != null) {
        canvas.drawLine(
          start,
          end,
          isActive ? paintBoneActive : paintBoneInactive,
        );
      }
    }

    // Draw Torso (Neutral or Active? Let's make Neutral Active)
    for (var pair in torso) {
      // Check if connection is specific to a side?
      // 11-23 is Left Side of body. 12-24 is Right Side.
      bool isActive = true;
      if (pair[0] == 11 && pair[1] == 23) isActive = !isRightSide;
      if (pair[0] == 12 && pair[1] == 24) isActive = isRightSide;
      drawConnection(pair[0], pair[1], isActive);
    }

    // Arms
    drawConnection(11, 13, !isRightSide); // Left Arm top
    drawConnection(13, 15, !isRightSide); // Left Arm bot
    drawConnection(12, 14, isRightSide); // Right Arm top
    drawConnection(14, 16, isRightSide); // Right Arm bot

    // Legs
    drawConnection(23, 25, !isRightSide); // Left Leg top
    drawConnection(25, 27, !isRightSide); // Left Leg bot
    drawConnection(24, 26, isRightSide); // Right Leg top
    drawConnection(26, 28, isRightSide); // Right Leg bot

    // Draw Joints
    for (int i = 0; i < 33; i++) {
      final point = _getLandmark(i, sourceRect);
      if (point != null) {
        // Determine side of joint
        bool isActive = true;
        // Odd numbers are usually Left in BlazePose (11, 13, 15...)
        // Even numbers are Right (12, 14, 16...)
        // 0 is Nose (Neutral)
        if (i > 0) {
          if (i % 2 != 0) {
            isActive = !isRightSide; // Odd = Left
          } else {
            isActive = isRightSide; // Even = Right
          }
        }

        canvas.drawCircle(
          point,
          5.0,
          isActive ? paintJointActive : paintJointInactive,
        );
        canvas.drawCircle(
          point,
          5.0,
          isActive ? paintJointBorderActive : paintJointBorderInactive,
        );
      }
    }

    // ANGLE & FEEDBACK LOGIC (REMOVED)
    // Handled by GlassFeedbackPanel widget in the parent Stack.
  }

  Offset? _getLandmark(int index, Rect destinationRect) {
    if (index >= landmarks.length) return null;

    final lm = landmarks[index]; // This is JSAny/JSObject
    if (lm == null) return null;

    double x = 0;
    double y = 0;

    try {
      // Robust extraction from JS Object
      final lmObj = lm as JSObject;
      x = (lmObj.getProperty('x'.toJS) as JSNumber).toDartDouble;
      y = (lmObj.getProperty('y'.toJS) as JSNumber).toDartDouble;

      // Mediapipe coordinates are normalized [0, 1].
      // Scale to destinationRect
      return Offset(
        destinationRect.left + x * destinationRect.width,
        destinationRect.top + y * destinationRect.height,
      );
    } catch (e) {
      // Fail silently for single frame errors to avoid noise
      return null;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
