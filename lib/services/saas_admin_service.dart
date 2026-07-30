import 'package:cloud_functions/cloud_functions.dart';

import '../core/erp/tenant_erp_service.dart';
import 'session_state.dart';

class SaasAdminService {
  final FirebaseFunctions _functions;

  SaasAdminService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-south1');

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

    final tenantId = _tenantId();
    final result = await _functions
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

    final result = await _functions
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

    await _functions.httpsCallable('decideApproval').call(<String, dynamic>{
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
