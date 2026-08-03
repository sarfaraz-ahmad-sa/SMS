import 'supabase_public_config.dart';

enum BackendMigrationMode { firebaseOnly, supabaseShadow, supabasePrimary }

class BackendConfig {
  BackendConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: SupabasePublicConfig.url,
  );
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: SupabasePublicConfig.publishableKey,
  );
  static const bool enableSupabaseShadow = bool.fromEnvironment(
    'ENABLE_SUPABASE_SHADOW',
  );
  static const bool enableSupabaseAuthPilot = bool.fromEnvironment(
    'ENABLE_SUPABASE_AUTH_PILOT',
  );
  static const bool enableSupabasePrimary = bool.fromEnvironment(
    'ENABLE_SUPABASE_PRIMARY',
    defaultValue: true,
  );
  static const String supabaseAuthRedirectUrl = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT_URL',
  );

  static BackendMigrationMode get mode => enableSupabasePrimary
      ? BackendMigrationMode.supabasePrimary
      : enableSupabaseShadow
          ? BackendMigrationMode.supabaseShadow
          : BackendMigrationMode.firebaseOnly;

  static bool get isSupabasePrimary =>
      mode == BackendMigrationMode.supabasePrimary;

  static bool get hasSupabaseClientConfiguration =>
      supabaseUrl.trim().isNotEmpty && supabasePublishableKey.trim().isNotEmpty;

  static bool get shouldInitializeSupabase =>
      enableSupabasePrimary || enableSupabaseShadow || enableSupabaseAuthPilot;

  static void validate() {
    if (!shouldInitializeSupabase) return;
    if (!hasSupabaseClientConfiguration) {
      throw StateError(
        'SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY are required when '
        'ENABLE_SUPABASE_PRIMARY, ENABLE_SUPABASE_SHADOW, or '
        'ENABLE_SUPABASE_AUTH_PILOT must be enabled.',
      );
    }
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw StateError('SUPABASE_URL must be a valid HTTPS project URL.');
    }
    if (enableSupabaseAuthPilot) {
      final redirect = Uri.tryParse(supabaseAuthRedirectUrl);
      if (redirect == null || !redirect.hasScheme || redirect.host.isEmpty) {
        throw StateError(
          'SUPABASE_AUTH_REDIRECT_URL is required when '
          'ENABLE_SUPABASE_AUTH_PILOT=true.',
        );
      }
    }
  }
}
