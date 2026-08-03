import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/config/backend_config.dart';

void main() {
  test('Supabase is the default backend after primary cutover', () {
    expect(BackendConfig.mode, BackendMigrationMode.supabasePrimary);
    expect(BackendConfig.enableSupabaseShadow, isFalse);
    expect(BackendConfig.enableSupabaseAuthPilot, isFalse);
    expect(BackendConfig.enableSupabasePrimary, isTrue);
    expect(BackendConfig.shouldInitializeSupabase, isTrue);
    expect(BackendConfig.hasSupabaseClientConfiguration, isTrue);
    expect(BackendConfig.validate, returnsNormally);
  });
}
