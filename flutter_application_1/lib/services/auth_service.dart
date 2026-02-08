import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initialize();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isInitialized = false;

  // Initialize GoogleSignIn with configuration
  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      await _googleSignIn.initialize(
        // Web Client ID from Firebase Console (OAuth 2.0 client)
        clientId:
            '353454091403-vnq35bfd5e1joosn6d7fitf093ng56r2.apps.googleusercontent.com',
      );
      _isInitialized = true;
      debugPrint('GoogleSignIn initialized successfully');
    } catch (e) {
      debugPrint('Error initializing GoogleSignIn: $e');
    }
  }

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    // Ensure GoogleSignIn is initialized
    await _initialize();

    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .authenticate();

      // If user cancels the sign-in, return null
      if (googleUser == null) {
        debugPrint('User cancelled Google Sign-In');
        return null;
      }

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      debugPrint('Successfully signed in: ${userCredential.user?.email}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}
