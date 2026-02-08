import 'package:flutter/material.dart';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;

/// Renders a Google Sign-In button using the GIS library via JS Interop.
Widget buildGoogleSignInButton({
  required VoidCallback process,
  required bool isLoading,
}) {
  return const _GoogleSignInButtonWeb();
}

class _GoogleSignInButtonWeb extends StatefulWidget {
  const _GoogleSignInButtonWeb();

  @override
  State<_GoogleSignInButtonWeb> createState() => _GoogleSignInButtonWebState();
}

class _GoogleSignInButtonWebState extends State<_GoogleSignInButtonWeb> {
  final String _viewType = 'google-sign-in-button';

  @override
  void initState() {
    super.initState();
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final element = web.document.createElement('div') as web.HTMLDivElement;
      element.id = 'google-sign-in-button-$viewId';
      element.style.width = '100%';
      element.style.height = '100%';

      // Render the button using JS Interop
      // We wrap it in a microtask to ensure the element is ready?
      // Actually platform view factory returns the element, so it is ready.
      // But we need to make sure 'google' global is defined.
      _renderButton(element);

      return element;
    });
  }

  void _renderButton(web.HTMLDivElement element) {
    try {
      // Create the configuration object using Map and jsify
      final options = {
        'type': 'standard',
        'theme': 'outline',
        'size': 'large',
        'text': 'signin_with',
        'shape': 'rectangular',
        'width': 250,
      }.jsify();

      // Call the global google.accounts.id.renderButton
      renderGoogleButton(element, options!);
    } catch (e) {
      debugPrint('Error rendering Google Sign-In button: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: 250,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}

// --- JS Interop Definitions ---

@JS('google.accounts.id.renderButton')
external void renderGoogleButton(web.HTMLDivElement parent, JSAny options);
