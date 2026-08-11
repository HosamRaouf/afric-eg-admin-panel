import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

/// Wraps Firebase Authentication for the admin panel.
///
/// The panel signs in with email/password credentials. Firestore rules gate
/// write access to email/password sessions (`sign_in_provider == "password"`)
/// so the congress app's anonymous attendees can never mutate admin content.
class AuthService {
  final FirebaseAuth _auth;

  final StreamController<bool> _isSignedIn =
      StreamController<bool>.broadcast();

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    _auth.authStateChanges().listen((user) {
      _isSignedIn.add(user != null);
    });
    if (_auth.currentUser != null) {
      _isSignedIn.add(true);
    }
  }

  Stream<bool> get isSignedIn => _isSignedIn.stream;

  User? get currentUser => _auth.currentUser;

  String? get currentUid => _auth.currentUser?.uid;

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _isSignedIn.add(false);
  }
}
