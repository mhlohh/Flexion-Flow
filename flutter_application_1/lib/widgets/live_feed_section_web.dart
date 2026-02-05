import 'dart:async';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'dart:ui_web'
    as ui_web; // Required for platformViewRegistry in newer Flutter
import 'dart:js' as js; // Required for allowInterop
import 'dart:js_util' as js_util; // Required for accessing JS properties
import 'dart:math' as math; // Required for angle calculation
import 'package:flutter/material.dart';

class LiveFeedSection extends StatefulWidget {
  const LiveFeedSection({super.key});

  @override
  State<LiveFeedSection> createState() => _LiveFeedSectionState();
}

class _LiveFeedSectionState extends State<LiveFeedSection> {
  final html.VideoElement _videoElement = html.VideoElement()
    ..autoplay = true
    ..muted = true;
  bool _isCameraInitialized = false;
  List<dynamic> _webLandmarks = [];
  Size _videoSize = Size.zero; // Intrinsic video size

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
      final mediaStream = await html.window.navigator.mediaDevices!
          .getUserMedia({'video': true});
      print('✅ [Web] Camera access granted.');
      _videoElement.srcObject = mediaStream;

      // Wait for metadata to get dimensions
      await _videoElement.onLoadedMetadata.first;
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

      final onPoseResults = js.allowInterop((dynamic landmarks) {
        if (!mounted) return;
        if (landmarks is List) {
          setState(() {
            _webLandmarks = landmarks;
          });
        }
      });

      final poseWorker = js_util.getProperty(html.window, 'poseWorker');

      if (poseWorker != null) {
        js_util.callMethod(poseWorker, 'initialize', [null, onPoseResults]);
        js_util.callMethod(poseWorker, 'startCamera', [_videoElement]);
      } else {
        print('❌ [Web] poseWorker is NULL.');
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
              ),
            ),
        ],
      ),
    );
  }
}

class WebPosePainter extends CustomPainter {
  final List<dynamic> landmarks;
  final Size sourceSize;

  WebPosePainter({required this.landmarks, required this.sourceSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    // Calculate scaling to match 'BoxFit.contain'
    // This ensures drawn points align with the video shown by HtmlElementView
    final fitted = applyBoxFit(BoxFit.contain, sourceSize, size);
    final destinationSize = fitted.destination;
    final sourceRect = Alignment.center.inscribe(
      destinationSize,
      Offset.zero & size,
    );

    final paintJoint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4
      ..style = PaintingStyle.fill;

    final paintBone = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // --- 1. Draw Full Body Skeleton ---
    final connections = [
      [11, 12], [11, 13], [13, 15], [12, 14], [14, 16], // Arms
      [11, 23], [12, 24], [23, 24], // Torso
      [23, 25], [25, 27], [24, 26], [26, 28], // Legs
    ];

    for (final connection in connections) {
      final start = _getLandmark(connection[0], sourceRect);
      final end = _getLandmark(connection[1], sourceRect);
      if (start != null && end != null) {
        canvas.drawLine(start, end, paintBone);
        canvas.drawCircle(start, 4, paintJoint);
        canvas.drawCircle(end, 4, paintJoint);
      }
    }

    // --- 2. Calculate and Show Angle (Right Elbow) ---
    // Indices: 12 (Shoulder), 14 (Elbow), 16 (Wrist)
    final p1 = _getLandmark(12, sourceRect);
    final p2 = _getLandmark(14, sourceRect);
    final p3 = _getLandmark(16, sourceRect);

    if (p1 != null && p2 != null && p3 != null) {
      final angle = _calculateAngle(p1, p2, p3);

      // --- Feedback Logic ---
      Color color;
      String message;

      if (angle < 50) {
        color = Colors.green;
        message = "Good Hold";
      } else if (angle > 160) {
        color = Colors.blue;
        message = "Fully Extended";
      } else {
        color = Colors.orange;
        message = "Keep Moving";
      }

      // Draw Feedback Text
      final textSpan = TextSpan(
        text: 'Angle: ${angle.toStringAsFixed(1)}°\n$message',
        style: TextStyle(
          color: color,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black54,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
      );

      textPainter.layout();
      textPainter.paint(canvas, const Offset(20, 40));

      // Highlight the Elbow Joint with status color
      final highlightPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p2, 12, highlightPaint);

      // Draw lines for the arm in status color too
      final armPaint = Paint()
        ..color = color
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;

      canvas.drawLine(p1, p2, armPaint);
      canvas.drawLine(p2, p3, armPaint);
    }
  }

  // Math Helper: Calculate angle 0-180 degrees
  double _calculateAngle(Offset first, Offset middle, Offset last) {
    final radians =
        (math.atan2(last.dy - middle.dy, last.dx - middle.dx) -
                math.atan2(first.dy - middle.dy, first.dx - middle.dx))
            .abs();
    var angle = radians * 180.0 / math.pi;
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }

  Offset? _getLandmark(int index, Rect destinationRect) {
    if (index >= landmarks.length) return null;
    var lm = landmarks[index];
    double x = 0;
    double y = 0;
    try {
      x = js_util.getProperty(lm, 'x');
      y = js_util.getProperty(lm, 'y');
    } catch (e) {
      return null;
    }

    // Map normalized coordinates [0,1] to the destinationRect
    return Offset(
      destinationRect.left + x * destinationRect.width,
      destinationRect.top + y * destinationRect.height,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
