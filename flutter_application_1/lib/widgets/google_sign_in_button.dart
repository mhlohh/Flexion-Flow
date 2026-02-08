import 'package:flutter/material.dart';

import 'src/google_sign_in_button_mobile.dart'
    if (dart.library.js_interop) 'src/google_sign_in_button_web.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return buildGoogleSignInButton(process: onPressed, isLoading: isLoading);
  }
}
