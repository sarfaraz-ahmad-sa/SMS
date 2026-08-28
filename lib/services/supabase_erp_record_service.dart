import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/erp/erp_record.dart';
import '../core/erp/erp_repository.dart';
import 'supabase_bootstrap.dart';

/// Bounded PostgreSQL adapter for non-financial ERP catalog records.
/// Mutations always use security-definer RPCs; direct table writes are denied.
class SupabaseErpRecordService {
  SupabaseErpRecordService({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  Future<ErpPage> fetchPage({
    required String tenantId,
    required String collection,
    required String campusId,
    required String academicYearId,
    int pageSize = 50,
    String? afterId,
    String? query,
    String? status,
  }) async {
    _scope(tenantId, collection, campusId, academicYearId);
    final safeSize = pageSize.clamp(10, 100).toInt();
    var request = _client
        .from('erp_records')
        .select('id,data,status,created_at,updated_at')
        .eq('tenant_id', tenantId)
        .eq('collection', collection)
        .eq('campus_id', campusId)
        .eq('academic_year_id', academicYearId)
        .eq('is_archived', false);
    final cursor = _text(afterId);
    final search = _text(query);
    final statusFilter = _text(status);
    if (search != null) {
      final pattern = search
          .toLowerCase()
          .replaceAll('\\', '\\\\')
          .replaceAll('%', '\\%')
          .replaceAll('_', '\\_');
      request = request.ilike('search_text', '%$pattern%');
    }
    if (statusFilter != null) request = request.eq('status', statusFilter);
    if (cursor != null) request = request.gt('id', cursor);
    final response = await request.order('id').limit(safeSize + 1);
    final rows = response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
    final hasMore = rows.length > safeSize;
    final visible = hasMore ? rows.take(safeSize) : rows;
    final records = visible.map(_record).toList(growable: false);
    return ErpPage(
      records: records,
      hasMore: hasMore,
      cursor: records.isEmpty ? cursor : records.last.id,
    );
  }

  Future<String> create({
    required String tenantId,
    required String collection,
    required String campusId,
    required String academicYearId,
    required Map<String, dynamic> values,
  }) async {
    _scope(tenantId, collection, campusId, academicYearId);
    final actor = _client.auth.currentUser?.id;
    if (actor == null) throw StateError('No authenticated Supabase user.');
    final response = await _client.rpc(
      'create_erp_record',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_collection': collection,
        'p_campus_id': campusId,
        'p_academic_year_id': academicYearId,
        'p_values': _jsonSafe(values),
        'p_idempotency_key':
            '$actor:$collection:${DateTime.now().microsecondsSinceEpoch}',
      },
    );
    return _row(response)['id']?.toString() ??
        (throw const FormatException('ERP create returned no record ID.'));
  }

  Future<String> createSelfService({
    required String tenantId,
    required String collection,
    required String campusId,
    required String academicYearId,
    required Map<String, dynamic> values,
  }) async {
    _scope(tenantId, collection, campusId, academicYearId);
    final actor = _client.auth.currentUser?.id;
    if (actor == null) throw StateError('No authenticated Supabase user.');
    final response = await _client.rpc(
      'create_self_service_erp_record',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_collection': collection,
        'p_campus_id': campusId,
        'p_academic_year_id': academicYearId,
        'p_values': _jsonSafe(values),
        'p_idempotency_key':
            '$actor:self:$collection:${DateTime.now().microsecondsSinceEpoch}',
      },
    );
    return _row(response)['id']?.toString() ??
        (throw const FormatException(
          'Self-service create returned no record ID.',
        ));
  }

  Future<void> update({
    required String tenantId,
    required String collection,
    required String campusId,
    required String academicYearId,
    required String recordId,
    required Map<String, dynamic> values,
  }) async {
    final current = await _fetchRow(
      tenantId: tenantId,
      collection: collection,
      campusId: campusId,
      academicYearId: academicYearId,
      recordId: recordId,
    );
    await _client.rpc(
      'update_erp_record',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_collection': collection,
        'p_record_id': recordId,
        'p_expected_updated_at': current['updated_at'],
        'p_values': _jsonSafe(values),
      },
    );
  }

  Future<void> archive({
    required String tenantId,
    required String collection,
    required String campusId,
    required String academicYearId,
    required String recordId,
  }) async {
    final current = await _fetchRow(
      tenantId: tenantId,
      collection: collection,
      campusId: campusId,
      academicYearId: academicYearId,
      recordId: recordId,
    );
    await _client.rpc(
      'archive_erp_record',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_collection': collection,
        'p_record_id': recordId,
        'p_expected_updated_at': current['updated_at'],
      },
    );
  }

  Future<Map<String, dynamic>> _fetchRow({
    required String tenantId,
    required String collection,
    required String campusId,
    required String academicYearId,
    required String recordId,
  }) async {
    _scope(tenantId, collection, campusId, academicYearId);
    final row = await _client
        .from('erp_records')
        .select('id,updated_at')
        .eq('tenant_id', tenantId)
        .eq('collection', collection)
        .eq('campus_id', campusId)
        .eq('academic_year_id', academicYearId)
        .eq('id', recordId)
        .eq('is_archived', false)
        .limit(1)
        .maybeSingle();
    if (row == null) throw StateError('ERP record was not found.');
    return row;
  }

  ErpRecord _record(Map<String, dynamic> row) {
    final rawData = row['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    return ErpRecord(id: row['id']?.toString() ?? '', data: <String, dynamic>{
      ...data,
      if (row['status'] != null) 'status': row['status'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
      'isArchived': false,
    });
  }

  void _scope(
    String tenantId,
    String collection,
    String campusId,
    String academicYearId,
  ) {
    for (final entry in <String, String>{
      'tenantId': tenantId,
      'collection': collection,
      'campusId': campusId,
      'academicYearId': academicYearId,
    }.entries) {
      if (entry.value.trim().isEmpty) {
        throw ArgumentError.value(entry.value, entry.key, 'Cannot be empty.');
      }
    }
  }
}

/// Transaction-only adapter for money, payroll, accounting and publication
/// records. Every mutation is validated and audited inside PostgreSQL.
class SupabaseTrustedErpService {
  SupabaseTrustedErpService({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  Future<ErpPage> fetchPayments({
    required String tenantId,
    required String campusId,
    required String academicYearId,
    int pageSize = 50,
    String? afterId,
  }) async {
    final safeSize = pageSize.clamp(10, 100).toInt();
    var query = _client
        .from('payments')
        .select(
          'id,receipt_no,amount,method,reference,paid_at,status,'
          'invoice:fee_invoices(invoice_no),student:students(full_name)',
        )
        .eq('tenant_id', tenantId)
        .eq('campus_id', campusId)
        .eq('academic_year_id', academicYearId);
    final cursor = _text(afterId);
    if (cursor != null) query = query.gt('id', cursor);
    final response = await query.order('id').limit(safeSize + 1);
    final rows = response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
    final hasMore = rows.length > safeSize;
    final visible = hasMore ? rows.take(safeSize) : rows;
    final records = visible.map((row) {
      final invoice = row['invoice'];
      final student = row['student'];
      final invoiceData = invoice is Map ? invoice : const <String, dynamic>{};
      final studentData = student is Map ? student : const <String, dynamic>{};
      return ErpRecord(id: row['id']?.toString() ?? '', data: <String, dynamic>{
        'receiptNo': row['receipt_no'],
        'invoiceNo': invoiceData['invoice_no'],
        'studentName': studentData['full_name'],
        'paymentDate': row['paid_at'],
        'amount': row['amount'],
        'paymentMethod': row['method'],
        'transactionReference': row['reference'],
        'status': row['status'],
        'isArchived': false,
      });
    }).toList(growable: false);
    return ErpPage(
      records: records,
      hasMore: hasMore,
      cursor: records.isEmpty ? cursor : records.last.id,
    );
  }

  Future<String> create({
    required String tenantId,
    required String collection,
    required String campusId,
    required String academicYearId,
    required Map<String, dynamic> values,
  }) async {
    final actor = _client.auth.currentUser?.id;
    if (actor == null) throw StateError('No authenticated Supabase user.');
    final idempotencyKey =
        '$actor:$collection:${DateTime.now().microsecondsSinceEpoch}';
    if (collection == 'payments') {
      final response = await _client.rpc(
        'record_fee_payment_by_number',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_invoice_no': values['invoiceNo']?.toString().trim() ?? '',
          'p_amount': values['amount'],
          'p_method': values['paymentMethod']?.toString() ?? '',
          'p_reference':
              values['transactionReference']?.toString().trim() ?? '',
          'p_idempotency_key': idempotencyKey,
        },
      );
      return _row(response)['id']?.toString() ??
          (throw const FormatException('Payment returned no record ID.'));
    }
    final response = await _client.rpc(
      'create_trusted_erp_record',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_collection': collection,
        'p_campus_id': campusId,
        'p_academic_year_id': academicYearId,
        'p_values': _jsonSafe(values),
        'p_idempotency_key': idempotencyKey,
      },
    );
    return _row(response)['id']?.toString() ??
        (throw const FormatException('Trusted create returned no record ID.'));
  }

  Future<void> update({
    required String tenantId,
    required String collection,
    required String campusId,
    required String academicYearId,
    required String recordId,
    required Map<String, dynamic> values,
  }) async {
    if (collection == 'payments') {
      throw StateError('Posted payments are immutable. Use the refund flow.');
    }
    final current = await _current(
      tenantId: tenantId,
      collection: collection,
      campusId: campusId,
      academicYearId: academicYearId,
      recordId: recordId,
    );
    await _client.rpc('update_trusted_erp_record', params: <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_collection': collection,
      'p_record_id': recordId,
      'p_expected_updated_at': current['updated_at'],
      'p_values': _jsonSafe(values),
    });
  }

  Future<void> archive({
    required String tenantId,
    required String collection,
    required String campusId,
    required String academicYearId,
    required String recordId,
  }) async {
    if (collection == 'payments') {
      throw StateError('Posted payments cannot be archived.');
    }
    final current = await _current(
      tenantId: tenantId,
      collection: collection,
      campusId: campusId,
      academicYearId: academicYearId,
      recordId: recordId,
    );
    await _client.rpc('archive_trusted_erp_record', params: <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_collection': collection,
      'p_record_id': recordId,
      'p_expected_updated_at': current['updated_at'],
    });
  }

  Future<void> transition({
    required String tenantId,
    required String collection,
    required String recordId,
    required String expectedStatus,
    required String newStatus,
  }) async {
    await _client
        .rpc('transition_trusted_erp_record', params: <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_collection': collection,
      'p_record_id': recordId,
      'p_expected_status': expectedStatus,
      'p_new_status': newStatus,
    });
  }

  Future<Map<String, dynamic>> _current({
    required String tenantId,
    required String collection,
    required String campusId,
    required String academicYearId,
    required String recordId,
  }) async {
    final row = await _client
        .from('erp_records')
        .select('id,updated_at,status')
        .eq('tenant_id', tenantId)
        .eq('collection', collection)
        .eq('campus_id', campusId)
        .eq('academic_year_id', academicYearId)
        .eq('id', recordId)
        .eq('is_archived', false)
        .limit(1)
        .maybeSingle();
    if (row == null) throw StateError('Trusted record was not found.');
    return row;
  }
}

Map<String, dynamic> _row(dynamic response) {
  if (response is Map) return Map<String, dynamic>.from(response);
  if (response is List && response.length == 1 && response.first is Map) {
    return Map<String, dynamic>.from(response.first as Map);
  }
  throw const FormatException('ERP mutation returned an invalid row.');
}

Map<String, dynamic> _jsonSafe(Map<String, dynamic> values) {
  dynamic safe(dynamic value) {
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), safe(item)));
    }
    if (value is Iterable) return value.map(safe).toList(growable: false);
    return value;
  }

  return Map<String, dynamic>.from(safe(values) as Map);
}

String? _text(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
