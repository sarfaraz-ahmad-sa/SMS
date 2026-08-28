import 'package:cloud_functions/cloud_functions.dart';

import '../config/backend_config.dart';
import '../core/erp/tenant_erp_service.dart';
import 'session_state.dart';
import 'supabase_bootstrap.dart';
import 'supabase_erp_record_service.dart';

class SaasAdminService {
  final FirebaseFunctions? _functions;

  SaasAdminService({FirebaseFunctions? functions})
      : _functions = functions ??
            (BackendConfig.isSupabasePrimary
                ? null
                : FirebaseFunctions.instanceFor(region: 'asia-south1'));

  Future<Map<String, dynamic>> refreshUsage() async {
    if (TenantErpService().isDemoMode) {
      return <String, dynamic>{
        'students': 18,
        'staffUsers': 8,
        'campuses': 1,
        'storageMb': 126,
        'smsThisMonth': 74,
        'emailThisMonth': 312,
        'aiActionsThisMonth': 11,
      };
    }

    if (BackendConfig.isSupabasePrimary) {
      final usage = await SupabaseBootstrap.client.rpc(
        'get_saas_usage',
        params: <String, dynamic>{'p_tenant_id': _tenantId()},
      );
      return _asMap(usage);
    }

    final tenantId = _tenantId();
    final result = await _functions!
        .httpsCallable('refreshSaasUsage')
        .call(<String, dynamic>{'tenantId': tenantId});
    return _asMap(result.data);
  }

  Future<String> requestApproval({
    required String type,
    required String title,
    required String recordCollection,
    required String recordId,
    int totalSteps = 1,
  }) async {
    if (TenantErpService().isDemoMode) return 'demo-approval';

    if (BackendConfig.isSupabasePrimary) {
      final row = await SupabaseBootstrap.client
          .from('erp_records')
          .select('status')
          .eq('tenant_id', _tenantId())
          .eq('collection', recordCollection)
          .eq('id', recordId)
          .eq('is_archived', false)
          .maybeSingle();
      final current = row?['status']?.toString() ?? '';
      final next = switch (current) {
        'Requested' || 'Calculated' => 'Under Review',
        'Draft' => 'Submitted',
        _ => throw StateError('This record is not ready for approval.'),
      };
      await SupabaseTrustedErpService().transition(
        tenantId: _tenantId(),
        collection: recordCollection,
        recordId: recordId,
        expectedStatus: current,
        newStatus: next,
      );
      return '$recordCollection:$recordId';
    }

    final result = await _functions!
        .httpsCallable('requestApproval')
        .call(<String, dynamic>{
      'tenantId': _tenantId(),
      'type': type,
      'title': title,
      'recordCollection': recordCollection,
      'recordId': recordId,
      'totalSteps': totalSteps,
    });
    return _asMap(result.data)['approvalId']?.toString() ?? '';
  }

  Future<void> decideApproval({
    required String approvalId,
    required String decision,
    String? reason,
  }) async {
    if (TenantErpService().isDemoMode) return;

    if (BackendConfig.isSupabasePrimary) {
      final separator = approvalId.indexOf(':');
      if (separator <= 0 || separator == approvalId.length - 1) {
        throw StateError('Approval reference is invalid.');
      }
      final collection = approvalId.substring(0, separator);
      final recordId = approvalId.substring(separator + 1);
      final row = await SupabaseBootstrap.client
          .from('erp_records')
          .select('status')
          .eq('tenant_id', _tenantId())
          .eq('collection', collection)
          .eq('id', recordId)
          .eq('is_archived', false)
          .maybeSingle();
      var current = row?['status']?.toString() ?? '';
      if (current == 'Requested' || current == 'Calculated') {
        await SupabaseTrustedErpService().transition(
          tenantId: _tenantId(),
          collection: collection,
          recordId: recordId,
          expectedStatus: current,
          newStatus: 'Under Review',
        );
        current = 'Under Review';
      }
      await SupabaseTrustedErpService().transition(
        tenantId: _tenantId(),
        collection: collection,
        recordId: recordId,
        expectedStatus: current,
        newStatus: decision == 'approved' ? 'Approved' : 'Rejected',
      );
      return;
    }

    await _functions!.httpsCallable('decideApproval').call(<String, dynamic>{
      'tenantId': _tenantId(),
      'approvalId': approvalId,
      'decision': decision,
      'reason': reason?.trim() ?? '',
    });
  }

  String _tenantId() {
    final tenantId = SessionState.instance.tenant?.id;
    if (tenantId == null || tenantId.isEmpty) {
      throw StateError('No active school is selected.');
    }
    return tenantId;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}
