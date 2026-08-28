import 'erp_entity.dart';
import 'erp_record.dart';

class ErpPage {
  const ErpPage({required this.records, required this.hasMore, this.cursor});

  final List<ErpRecord> records;
  final bool hasMore;
  final Object? cursor;
}

/// Provider-neutral contract used during the Firebase-to-PostgreSQL migration.
///
/// Firebase remains the production implementation until the Supabase adapter,
/// RLS tests, data reconciliation, and auth cutover have all passed.
abstract interface class ErpRepository {
  bool get isDemoMode;

  Future<ErpPage> fetchPage(
    ErpEntity entity, {
    int pageSize = 50,
    Object? startAfter,
    String? query,
    String? status,
  });

  Future<int> countVisible(ErpEntity entity);

  Future<Map<String, dynamic>> loadDashboardSummary();

  Future<int> count(String collection);

  Future<int> countWhere(String collection, String field, dynamic value);

  Future<String> create(ErpEntity entity, Map<String, dynamic> values);

  Future<void> update(
    ErpEntity entity,
    String recordId,
    Map<String, dynamic> values,
  );

  Future<void> archive(ErpEntity entity, String recordId);
}
