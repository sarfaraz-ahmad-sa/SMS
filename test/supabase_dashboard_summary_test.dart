import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/services/supabase_dashboard_summary_service.dart';

void main() {
  test('maps PostgreSQL summary fields to the shared dashboard shape', () {
    final summary = SupabaseDashboardSummaryMapper.fromRow(
      <String, dynamic>{
        'counts': <String, dynamic>{'students': 12, 'fee_invoices': 8},
        'status_counts': <String, dynamic>{
          'students': <String, dynamic>{'active': 12},
        },
        'updated_at': '2026-08-03T11:00:00Z',
      },
    );

    expect((summary['counts'] as Map)['students'], 12);
    expect(
      ((summary['statusCounts'] as Map)['students'] as Map)['active'],
      12,
    );
    expect(summary['updatedAt'], '2026-08-03T11:00:00Z');
  });

  test('missing summary returns an empty map for safe UI fallback', () {
    expect(
      SupabaseDashboardSummaryMapper.fromRow(null),
      const <String, dynamic>{},
    );
  });
}
