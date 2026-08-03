import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/backend_config.dart';

class SupabaseBootstrap {
  SupabaseBootstrap._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initializeClient() async {
    BackendConfig.validate();
    if (!BackendConfig.shouldInitializeSupabase) return;

    await Supabase.initialize(
      url: BackendConfig.supabaseUrl,
      publishableKey: BackendConfig.supabasePublishableKey,
    );
    _initialized = true;
  }

  @Deprecated('Use initializeClient; Supabase may now be the primary backend.')
  static Future<void> initializeShadowClient() => initializeClient();

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError('The Supabase client is not initialized.');
    }
    return Supabase.instance.client;
  }
}
