import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_bootstrap.dart';

/// Reads the pre-aggregated dashboard row for one explicit school scope.
/// No client-side collection scans or repeated count queries are performed.
class SupabaseDashboardSummaryService {
  SupabaseDashboardSummaryService({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  Future<Map<String, dynamic>> load({
    required String tenantId,
    required String campusId,
    required String academicYearId,
  }) async {
    _requireScope('tenantId', tenantId);
    _requireScope('campusId', campusId);
    _requireScope('academicYearId', academicYearId);

    final row = await _client
        .from('dashboard_summaries')
        .select('counts,status_counts,updated_at')
        .eq('tenant_id', tenantId)
        .eq('campus_id', campusId)
        .eq('academic_year_id', academicYearId)
        .limit(1)
        .maybeSingle();

    return SupabaseDashboardSummaryMapper.fromRow(row);
  }

  void _requireScope(String name, String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'Scope cannot be empty.');
    }
  }
}

class SupabaseDashboardSummaryMapper {
  const SupabaseDashboardSummaryMapper._();

  static Map<String, dynamic> fromRow(Map<String, dynamic>? row) {
    if (row == null) return const <String, dynamic>{};
    return <String, dynamic>{
      'counts': _stringMap(row['counts']),
      'statusCounts': _stringMap(row['status_counts']),
      'updatedAt': row['updated_at'],
    };
  }

  static Map<String, dynamic> _stringMap(dynamic value) {
    if (value is! Map) return const <String, dynamic>{};
    return Map<String, dynamic>.from(value);
  }
}
