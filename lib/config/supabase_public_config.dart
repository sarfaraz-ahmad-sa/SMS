/// Public Supabase client configuration bundled into Flutter builds.
///
/// Publishable keys are protected by PostgreSQL Row Level Security. A secret
/// or service-role key must never be added to this client configuration.
class SupabasePublicConfig {
  const SupabasePublicConfig._();

  static const String url = 'https://mmixwroevlfucxialdix.supabase.co';
  static const String publishableKey =
      'sb_publishable_GDnudnTmKfGgMKjNrPJ1Bg_uCI8hncX';
}
