import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/backend_config.dart';
import 'supabase_bootstrap.dart';

class AccessRequestRecord {
  const AccessRequestRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.rollOrEmployeeId,
    required this.classOrDepartment,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String rollOrEmployeeId;
  final String classOrDepartment;
  final String status;
  final DateTime? createdAt;
}

class AccessRequestService {
  AccessRequestService({
    FirebaseFirestore? firestore,
    SupabaseClient? supabaseClient,
  })  : _db = firestore ??
            (BackendConfig.isSupabasePrimary
                ? null
                : FirebaseFirestore.instance),
        _supabase = supabaseClient ??
            (BackendConfig.isSupabasePrimary
                ? SupabaseBootstrap.client
                : null);

  final FirebaseFirestore? _db;
  final SupabaseClient? _supabase;

  Future<String> submit({
    required String schoolCode,
    required String name,
    required String rollNumber,
    required String className,
    required String email,
    required String phone,
  }) async {
    final values = <String, dynamic>{
      'schoolCode': schoolCode.trim().toUpperCase(),
      'name': name.trim(),
      'rollNumber': rollNumber.trim(),
      'className': className.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
    };
    if (BackendConfig.isSupabasePrimary) {
      final response = await _supabase!.functions.invoke(
        'request-school-access',
        body: values,
      );
      final data = response.data;
      if (data is! Map || data['requestId']?.toString().trim().isEmpty != false) {
        throw StateError('The access request service returned no reference.');
      }
      return data['requestId'].toString();
    }

    final reference = await _db!.collection('accessRequests').add({
      ...values,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  }

  Future<List<AccessRequestRecord>> listForSchool(String tenantId) async {
    if (!BackendConfig.isSupabasePrimary) {
      throw UnsupportedError(
        'Access-request review is available on the Supabase backend.',
      );
    }
    final rows = await _supabase!
        .from('access_requests')
        .select(
          'id,full_name,email,phone,roll_or_employee_id,'
          'class_or_department,status,created_at',
        )
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false)
        .limit(200);
    return rows.whereType<Map>().map((raw) {
      final row = Map<String, dynamic>.from(raw);
      return AccessRequestRecord(
        id: row['id']?.toString() ?? '',
        name: row['full_name']?.toString() ?? '',
        email: row['email']?.toString() ?? '',
        phone: row['phone']?.toString() ?? '',
        rollOrEmployeeId: row['roll_or_employee_id']?.toString() ?? '',
        classOrDepartment: row['class_or_department']?.toString() ?? '',
        status: row['status']?.toString() ?? 'pending',
        createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
      );
    }).where((record) => record.id.isNotEmpty).toList(growable: false);
  }

  Future<void> review({
    required String tenantId,
    required String requestId,
    required String decision,
    String? note,
  }) async {
    if (!BackendConfig.isSupabasePrimary) {
      throw UnsupportedError(
        'Access-request review is available on the Supabase backend.',
      );
    }
    await _supabase!.rpc(
      'review_access_request',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_request_id': requestId,
        'p_decision': decision,
        'p_note': note?.trim() ?? '',
      },
    );
  }
}
