import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/backend_config.dart';
import 'supabase_auth_service.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _firebaseAuth = firebaseAuth ??
            (BackendConfig.isSupabasePrimary ? null : FirebaseAuth.instance),
        _googleSignIn = googleSignIn;

  final FirebaseAuth? _firebaseAuth;
  GoogleSignIn? _googleSignIn;

  FirebaseAuth get _legacyAuth =>
      _firebaseAuth ??
      (throw StateError('Firebase authentication is disabled.'));

  Stream<User?> get authStateChanges => _legacyAuth.authStateChanges();
  User? get currentUser => _firebaseAuth?.currentUser;

  /// Firebase Web can briefly return a credential whose `user` has not yet
  /// propagated to `currentUser`. Resolve the signed-in account from both
  /// sources and wait for the auth-state stream before treating login as
  /// failed.
  Future<User?> resolveSignedInUser({
    User? credentialUser,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (credentialUser != null) return credentialUser;

    final immediateUser = _legacyAuth.currentUser;
    if (immediateUser != null) return immediateUser;

    try {
      return await _legacyAuth
          .authStateChanges()
          .firstWhere((User? user) => user != null)
          .timeout(timeout);
    } catch (_) {
      return _legacyAuth.currentUser;
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _legacyAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Web pe redirect se sign in shuru karta hai; result app reload ke baad
  // getRedirectResult() se milta hai. Isliye web pe UserCredential nahi lautata.
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      // Popup COOP ki wajah se atakta hai, isliye redirect use karte hain.
      await _legacyAuth.signInWithRedirect(GoogleAuthProvider());
      return null;
    }

    final googleSignIn = _googleSignIn ??= GoogleSignIn();
    final account = await googleSignIn.signIn();
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
    return _legacyAuth.signInWithCredential(credential);
  }

  // Web pe redirect ke baad app dobara load hone par ye call karo
  // taaki sign-in ka result mil jaaye.
  Future<UserCredential?> getRedirectResultIfAny() async {
    if (!kIsWeb) return null;
    try {
      return await _legacyAuth.getRedirectResult();
    } catch (_) {
      return null;
    }
  }

  Future<void> sendPasswordResetEmail(String email) {
    if (BackendConfig.isSupabasePrimary) {
      return SupabaseAuthService().sendPasswordReset(email);
    }
    return _legacyAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> reauthenticateWithPassword({
    required String currentPassword,
  }) async {
    if (BackendConfig.isSupabasePrimary) {
      final user = SupabaseAuthService().currentUser;
      final email = user?.email;
      if (email == null || email.trim().isEmpty) {
        throw StateError('No email/password account is currently signed in.');
      }
      await SupabaseAuthService().signInWithPassword(
        email: email,
        password: currentPassword,
      );
      return;
    }
    final user = _legacyAuth.currentUser;
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
    if (BackendConfig.isSupabasePrimary) {
      await SupabaseAuthService().refreshSession();
      return;
    }
    final user = _legacyAuth.currentUser;
    if (user == null) return;
    await user.reload();
    await _legacyAuth.currentUser?.getIdToken(true);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (BackendConfig.isSupabasePrimary) {
      await SupabaseAuthService().changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return;
    }
    final user = _legacyAuth.currentUser;
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
    if (BackendConfig.isSupabasePrimary) {
      if (!SupabaseAuthService().isEmailVerified) {
        throw StateError(
          'Use password recovery to verify access to this email address.',
        );
      }
      return;
    }
    final user = _legacyAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-available',
        message: 'No authenticated account is available.',
      );
    }
    if (!user.emailVerified) await user.sendEmailVerification();
  }

  Future<void> signOut() async {
    if (BackendConfig.isSupabasePrimary) {
      await SupabaseAuthService().signOut();
      return;
    }
    try {
      await _googleSignIn?.signOut();
    } catch (_) {
      // Google Sign-In may not be initialized for email/password users.
    }
    await _legacyAuth.signOut();
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _firebaseAuth?.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }
}
