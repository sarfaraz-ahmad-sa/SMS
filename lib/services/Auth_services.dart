import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Web pe redirect se sign in shuru karta hai; result app reload ke baad
  // getRedirectResult() se milta hai. Isliye web pe UserCredential nahi lautata.
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      // Popup COOP ki wajah se atakta hai, isliye redirect use karte hain.
      await _firebaseAuth.signInWithRedirect(GoogleAuthProvider());
      return null;
    }

    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }

    final authentication = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: authentication.accessToken,
      idToken: authentication.idToken,
    );
    return _firebaseAuth.signInWithCredential(credential);
  }

  // Web pe redirect ke baad app dobara load hone par ye call karo
  // taaki sign-in ka result mil jaaye.
  Future<UserCredential?> getRedirectResultIfAny() async {
    if (!kIsWeb) return null;
    try {
      return await _firebaseAuth.getRedirectResult();
    } catch (_) {
      return null;
    }
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> reauthenticateWithPassword({
    required String currentPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.trim().isEmpty) {
      throw FirebaseAuthException(
        code: 'user-not-available',
        message: 'No email/password account is currently signed in.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.getIdToken(true);
  }

  Future<void> refreshCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    await user.reload();
    await _firebaseAuth.currentUser?.getIdToken(true);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.trim().isEmpty) {
      throw FirebaseAuthException(
        code: 'user-not-available',
        message: 'No email/password account is currently signed in.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
    await user.reload();
    await user.getIdToken(true);
  }

  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-available',
        message: 'No authenticated account is available.',
      );
    }
    if (!user.emailVerified) await user.sendEmailVerification();
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Google Sign-In may not be initialized for email/password users.
    }
    await _firebaseAuth.signOut();
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }
}