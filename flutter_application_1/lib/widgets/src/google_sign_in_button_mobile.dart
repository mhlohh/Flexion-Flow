import 'package:flutter/material.dart';

Widget buildGoogleSignInButton({
  required VoidCallback process,
  required bool isLoading,
}) {
  return isLoading
      ? const Center(child: CircularProgressIndicator())
      : ElevatedButton.icon(
          onPressed: process,
          icon: const Icon(Icons.login, size: 24, color: Colors.blue),
          label: const Text(
            'Sign in with Google',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            minimumSize: const Size(double.infinity, 56),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
        );
}
