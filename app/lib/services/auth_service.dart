import 'package:firebase_auth/firebase_auth.dart';

import '../models/user.dart';
import 'firebase_service.dart';

/// Email/password authentication plus the user's profile node.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(name.trim());
      // update() so it never overwrites devices the ESP32 may already have written.
      await FirebaseService.user(user.uid)
          .update({'name': name.trim(), 'email': email.trim()});
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<AppUser> loadProfile(String uid) async {
    final snap = await FirebaseService.user(uid).child('name').get();
    final user = _auth.currentUser;
    return AppUser(
      uid: uid,
      name: (snap.value as String?) ?? user?.displayName ?? '',
      email: user?.email ?? '',
    );
  }

  static String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return e.message ?? 'Something went wrong (${e.code}).';
    }
  }
}

/// Auth error with a message that can be shown to the user.
class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
