import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/backend_config.dart';
import 'models/user_role.dart';
import 'supabase_bootstrap.dart';

enum AccountSetupMethod { temporaryPassword, emailLink }

class ProvisionAccountResult {
  const ProvisionAccountResult({
    required this.uid,
    required this.created,
    required this.requiresPasswordChange,
    required this.passwordEmailSent,
    this.passwordEmailError,
    this.existingAuthenticationAccount = false,
  });

  final String uid;
  final bool created;
  final bool requiresPasswordChange;
  final bool passwordEmailSent;
  final String? passwordEmailError;
  final bool existingAuthenticationAccount;
}

class SchoolAccountRecord {
  const SchoolAccountRecord({
    required this.id,
    required Map<String, dynamic> data,
  }) : _data = data;

  final String id;
  final Map<String, dynamic> _data;

  Map<String, dynamic> data() => _data;
}

class SchoolAccountService {
  SchoolAccountService({
    SupabaseClient? client,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _client = client ??
            (BackendConfig.isSupabasePrimary ? SupabaseBootstrap.client : null),
        _firestore = firestore ??
            (BackendConfig.isSupabasePrimary
                ? null
                : FirebaseFirestore.instance),
        _functions = functions ??
            (BackendConfig.isSupabasePrimary
                ? null
                : FirebaseFunctions.instanceFor(region: 'asia-south1'));

  final SupabaseClient? _client;
  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;

  Stream<List<SchoolAccountRecord>> watchMembers(String tenantId) async* {
    // Account management does not need a permanent realtime subscription.
    // Refreshes after mutations are emitted by rebuilding this stream.
    yield await listMembers(tenantId);
  }

  Future<List<SchoolAccountRecord>> listMembers(String tenantId) async {
    if (!BackendConfig.isSupabasePrimary) {
      return _firestoreRecords(
        await _firestore!
            .collection('tenants')
            .doc(tenantId)
            .collection('members')
            .orderBy('displayName')
            .limit(300)
            .get(),
      );
    }
    final rows = await _client!
        .from('tenant_members')
        .select()
        .eq('tenant_id', tenantId)
        .order('display_name')
        .limit(300);
    return _records(rows, member: true);
  }

  Future<List<SchoolAccountRecord>> listCampuses(String tenantId) async {
    if (!BackendConfig.isSupabasePrimary) {
      return _firestoreRecords(
        await _firestore!
            .collection('tenants')
            .doc(tenantId)
            .collection('campuses')
            .where('isArchived', isEqualTo: false)
            .limit(100)
            .get(),
      );
    }
    final rows = await _client!
        .from('campuses')
        .select('id, code, name, is_archived')
        .eq('tenant_id', tenantId)
        .eq('is_archived', false)
        .order('name')
        .limit(100);
    return _records(rows);
  }

  Future<List<SchoolAccountRecord>> listLinkedRecords({
    required String tenantId,
    required String recordType,
  }) async {
    if (!BackendConfig.isSupabasePrimary) {
      final collection = switch (recordType) {
        'student' => 'students',
        'guardian' => 'guardians',
        _ => 'teachers',
      };
      return _firestoreRecords(
        await _firestore!
            .collection('tenants')
            .doc(tenantId)
            .collection(collection)
            .where('isArchived', isEqualTo: false)
            .limit(300)
            .get(),
      );
    }
    if (recordType == 'student') {
      final rows = await _client!
          .from('students')
          .select('id, full_name, admission_no, is_archived')
          .eq('tenant_id', tenantId)
          .eq('is_archived', false)
          .order('full_name')
          .limit(300);
      return _records(rows);
    }
    if (recordType == 'guardian') {
      final rows = await _client!
          .from('guardians')
          .select('id, full_name, phone, is_archived')
          .eq('tenant_id', tenantId)
          .eq('is_archived', false)
          .order('full_name')
          .limit(300);
      return _records(rows);
    }

    final rows = await _client!
        .from('erp_records')
        .select('id, data')
        .eq('tenant_id', tenantId)
        .eq('collection', 'teachers')
        .eq('is_archived', false)
        .order('id')
        .limit(300);
    return _records(rows, payload: true);
  }

  Future<ProvisionAccountResult> provisionAccount({
    required String tenantId,
    required String email,
    required String displayName,
    required UserRole role,
    required List<String> campusIds,
    required AccountSetupMethod setupMethod,
    String? temporaryPassword,
    bool forcePasswordChange = true,
    String? recordType,
    String? recordId,
  }) async {
    final body = <String, dynamic>{
      'action': 'provision',
      'tenantId': tenantId,
      'email': email.trim().toLowerCase(),
      'displayName': displayName.trim(),
      'roles': <String>[role.value],
      'campusIds': campusIds,
      'recordType': recordType?.trim() ?? '',
      'recordId': recordId?.trim() ?? '',
      'setupMethod': setupMethod.name,
      'temporaryPassword': temporaryPassword ?? '',
      'forcePasswordChange': forcePasswordChange,
    };
    final data = BackendConfig.isSupabasePrimary
        ? await _invoke(body)
        : await _callFirebase('provisionSchoolUser', body);

    return ProvisionAccountResult(
      uid: data['uid']?.toString() ?? '',
      created: data['created'] == true,
      requiresPasswordChange: data['requiresPasswordChange'] == true,
      passwordEmailSent: data['passwordEmailSent'] == true,
      passwordEmailError: data['passwordEmailError']?.toString(),
      existingAuthenticationAccount:
          data['existingAuthenticationAccount'] == true,
    );
  }

  Future<void> updateAccess({
    required String tenantId,
    required String targetUid,
    required String displayName,
    required List<UserRole> roles,
    required List<String> campusIds,
  }) async {
    final body = <String, dynamic>{
      'action': 'updateAccess',
      'tenantId': tenantId,
      'targetUid': targetUid,
      'displayName': displayName.trim(),
      'roles': roles.map((UserRole role) => role.value).toList(),
      'campusIds': campusIds,
    };
    if (BackendConfig.isSupabasePrimary) {
      await _invoke(body);
    } else {
      await _callFirebase('manageSchoolUser', body);
    }
  }

  Future<void> setAccountActive({
    required String tenantId,
    required String targetUid,
    required bool active,
    String? reason,
  }) async {
    final body = <String, dynamic>{
      'action': active ? 'activate' : 'suspend',
      'tenantId': tenantId,
      'targetUid': targetUid,
      'reason': reason?.trim() ?? '',
    };
    if (BackendConfig.isSupabasePrimary) {
      await _invoke(body);
    } else {
      await _callFirebase('manageSchoolUser', body);
    }
  }

  Future<void> resetTemporaryPassword({
    required String tenantId,
    required String targetUid,
    required String temporaryPassword,
  }) async {
    final body = <String, dynamic>{
      'action': 'resetPassword',
      'tenantId': tenantId,
      'targetUid': targetUid,
      'temporaryPassword': temporaryPassword,
    };
    if (BackendConfig.isSupabasePrimary) {
      await _invoke(body);
    } else {
      await _callFirebase('manageSchoolUser', body);
    }
  }

  Future<void> completeInitialPasswordChange(
    String tenantId,
    String newPassword,
  ) async {
    if (!BackendConfig.isSupabasePrimary) {
      await _callFirebase('completeInitialPasswordChange', <String, dynamic>{
        'tenantId': tenantId,
        'newPassword': newPassword,
      });
      return;
    }
    await _client!.auth.updateUser(UserAttributes(password: newPassword));
    final request = <String, dynamic>{
      'action': 'completePasswordChange',
      'tenantId': tenantId,
    };
    try {
      await _invoke(request);
    } on SchoolAccountException {
      // Updating the password can rotate the Supabase session. Refresh once
      // and retry the idempotent membership completion with the fresh token.
      try {
        await _client.auth.refreshSession();
        await _invoke(request);
      } catch (_) {
        throw const SchoolAccountException(
          'password-profile-sync-failed',
          'Your password was changed, but school access could not be finalized. '
              'Sign in with the new password and contact the school administrator.',
        );
      }
    }
  }

  Future<void> recordSuccessfulLogin(String tenantId) async {
    if (!BackendConfig.isSupabasePrimary) {
      await _callFirebase('recordSuccessfulLogin', <String, dynamic>{
        'tenantId': tenantId,
      });
      return;
    }
    await _invoke(<String, dynamic>{
      'action': 'recordLogin',
      'tenantId': tenantId,
    });
  }

  Future<void> sendPasswordSetupEmail(String email) async {
    if (BackendConfig.isSupabasePrimary) {
      await _client!.auth.resetPasswordForEmail(email.trim().toLowerCase());
    } else {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.trim().toLowerCase(),
      );
    }
  }

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    try {
      final response = await _client!.functions.invoke(
        'school-accounts',
        body: body,
      );
      if (response.status < 200 || response.status >= 300) {
        throw SchoolAccountException(
          'backend-error',
          _errorMessage(response.data),
        );
      }
      if (response.data is! Map) return const <String, dynamic>{};
      return Map<String, dynamic>.from(response.data as Map);
    } on FunctionException catch (error) {
      throw SchoolAccountException(
        'backend-error',
        _errorMessage(error.details),
      );
    }
  }

  Future<Map<String, dynamic>> _callFirebase(
    String name,
    Map<String, dynamic> body,
  ) async {
    final result = await _functions!.httpsCallable(name).call(body);
    if (result.data is Map) {
      return Map<String, dynamic>.from(result.data as Map);
    }
    return const <String, dynamic>{};
  }

  static List<SchoolAccountRecord> _firestoreRecords(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(
          (document) => SchoolAccountRecord(
            id: document.id,
            data: document.data(),
          ),
        )
        .toList(growable: false);
  }

  static List<SchoolAccountRecord> _records(
    dynamic value, {
    bool member = false,
    bool payload = false,
  }) {
    if (value is! Iterable) return const <SchoolAccountRecord>[];
    return value
        .whereType<Map>()
        .map((Map row) {
          final raw = Map<String, dynamic>.from(row);
          final id = (member ? raw['user_id'] : raw['id'])?.toString() ?? '';
          final normalized = payload && raw['data'] is Map
              ? <String, dynamic>{
                  ...Map<String, dynamic>.from(raw['data'] as Map),
                  'id': id,
                }
              : _camelize(raw);
          return SchoolAccountRecord(id: id, data: normalized);
        })
        .where((SchoolAccountRecord record) => record.id.isNotEmpty)
        .toList();
  }

  static Map<String, dynamic> _camelize(Map<String, dynamic> row) {
    return row.map((String key, dynamic value) {
      final converted = key.replaceAllMapped(
        RegExp(r'_([a-z])'),
        (Match match) => match.group(1)!.toUpperCase(),
      );
      return MapEntry<String, dynamic>(converted, value);
    });
  }

  static String _errorMessage(dynamic data) {
    if (data is Map) {
      return data['error']?.toString() ??
          data['message']?.toString() ??
          'School Accounts backend request failed.';
    }
    return data?.toString() ?? 'School Accounts backend request failed.';
  }
}

class SchoolAccountException implements Exception {
  const SchoolAccountException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}
