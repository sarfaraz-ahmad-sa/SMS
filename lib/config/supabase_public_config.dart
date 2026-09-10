/// No seller backend is bundled. Supply public client settings at build time.
/// Never place service-role keys or server secrets in a Flutter build.
class SupabasePublicConfig {
  const SupabasePublicConfig._();
  static const String url = '';
  static const String publishableKey = '';
}
