import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/backend_config.dart';
import 'supabase_bootstrap.dart';

class SupabaseAuthService {
  SupabaseAuthService({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  User? get currentUser => _auth.currentUser;

  Session? get currentSession => _auth.currentSession;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
      redirectTo: BackendConfig.supabaseAuthRedirectUrl.trim().isEmpty
          ? null
          : BackendConfig.supabaseAuthRedirectUrl,
    );
  }

  Future<UserResponse> updatePassword(String password) {
    return _auth.updateUser(UserAttributes(password: password));
  }

  Future<AuthResponse> refreshSession() => _auth.refreshSession();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    final email = user?.email;
    if (user == null || email == null || email.trim().isEmpty) {
      throw StateError('No email/password account is signed in.');
    }
    await signInWithPassword(email: email, password: currentPassword);
    await updatePassword(newPassword);
  }

  bool get isEmailVerified => currentUser?.emailConfirmedAt != null;

  Future<void> signOut() => _auth.signOut();
}
