import '../config/backend_config.dart';
import 'session_state.dart';
import 'supabase_bootstrap.dart';

class OperationalJobService {
  const OperationalJobService();

  Future<String> requestExport({
    required String sourceCollection,
    required String format,
  }) async {
    _requireSupabase();
    final scope = _scope();
    final response = await SupabaseBootstrap.client.rpc(
      'request_export_job',
      params: <String, dynamic>{
        'p_tenant_id': scope.$1,
        'p_campus_id': scope.$2,
        'p_academic_year_id': scope.$3,
        'p_source_collection': sourceCollection.trim(),
        'p_format': format.trim().toUpperCase(),
      },
    );
    return _recordId(response);
  }

  Future<String> requestBackup() async {
    _requireSupabase();
    final scope = _scope();
    final response = await SupabaseBootstrap.client.rpc(
      'request_backup_job',
      params: <String, dynamic>{
        'p_tenant_id': scope.$1,
        'p_campus_id': scope.$2,
        'p_academic_year_id': scope.$3,
      },
    );
    return _recordId(response);
  }

  void _requireSupabase() {
    if (!BackendConfig.isSupabasePrimary) {
      throw UnsupportedError(
        'Trusted export and backup jobs require the Supabase backend.',
      );
    }
  }

  (String, String, String) _scope() {
    final state = SessionState.instance;
    final values = (
      state.tenant?.id.trim() ?? '',
      state.activeCampusId?.trim() ?? '',
      state.activeAcademicYearId?.trim() ?? '',
    );
    if (values.$1.isEmpty || values.$2.isEmpty || values.$3.isEmpty) {
      throw StateError('School, campus and academic year are required.');
    }
    return values;
  }

  String _recordId(dynamic response) {
    if (response is Map && response['id']?.toString().trim().isNotEmpty == true) {
      return response['id'].toString();
    }
    throw StateError('The server did not return a job reference.');
  }
}
