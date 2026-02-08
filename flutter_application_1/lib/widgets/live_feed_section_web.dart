import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe'; // For getProperty
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'dart:math' as math;
import 'package:flutter/material.dart';

class LiveFeedSection extends StatefulWidget {
  const LiveFeedSection({super.key});

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

        // Convert JS Array to Dart List
        if (landmarks != null) {
          // landmarks is likely an Array of objects
          // We can treat it as JSAny and convert if it's an array
          // Or just pass it to the painter and let painter extract properties safely
          // But CustomPainter expects List<dynamic> currently.

          // Simplest is to keep it as List<dynamic> by converting
          // assuming landmarks is a JS Array.
          try {
            final list = (landmarks as JSArray?)?.toDart;
            if (list != null) {
              setState(() {
                _webLandmarks = list;
              });
            }
          } catch (e) {
            print('Error converting landmarks: $e');
          }
        }
      }.toJS;

      // Access global poseWorker
      final worker = web.window.getProperty('poseWorker'.toJS) as JSObject?;

      if (worker != null) {
        worker.callMethod('initialize'.toJS, null, onPoseResults);
        worker.callMethod('startCamera'.toJS, _videoElement);
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
  final List<dynamic> landmarks; // These are JSObjects
  final Size sourceSize;

  WebPosePainter({required this.landmarks, required this.sourceSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

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

    // --- 2. Calculate and Show Angle ---
    final p1 = _getLandmark(12, sourceRect);
    final p2 = _getLandmark(14, sourceRect);
    final p3 = _getLandmark(16, sourceRect);

    if (p1 != null && p2 != null && p3 != null) {
      final angle = _calculateAngle(p1, p2, p3);

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

      final highlightPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p2, 12, highlightPaint);

      final armPaint = Paint()
        ..color = color
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;

      canvas.drawLine(p1, p2, armPaint);
      canvas.drawLine(p2, p3, armPaint);
    }
  }

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

    // landmarks[index] is a JSAny/JSObject
    final lm = landmarks[index];
    if (lm == null) return null;

    double x = 0;
    double y = 0;

    try {
      // Use dart:js_interop_unsafe to access properties by name
      final lmObj = lm as JSObject;
      final xProp = lmObj.getProperty('x'.toJS);
      final yProp = lmObj.getProperty('y'.toJS);

      // Convert JSNumber to double?
      // With newer interop, we cast to JSNumber then toDouble
      x = (xProp as JSNumber).toDartDouble;
      y = (yProp as JSNumber).toDartDouble;
    } catch (e) {
      return null;
    }

    return Offset(
      destinationRect.left + x * destinationRect.width,
      destinationRect.top + y * destinationRect.height,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
