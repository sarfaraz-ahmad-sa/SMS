import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/backend_config.dart';
import '../core/erp/tenant_erp_service.dart';
import 'models/saas_usage.dart';
import 'session_state.dart';
import 'supabase_bootstrap.dart';

class SaasUsageService {
  final FirebaseFirestore? _firestore;

  SaasUsageService({FirebaseFirestore? firestore})
      : _firestore = firestore ??
            (BackendConfig.isSupabasePrimary
                ? null
                : FirebaseFirestore.instance);

  Stream<SaasUsage> watchCurrent() {
    if (TenantErpService().isDemoMode) {
      return Stream<SaasUsage>.value(
        const SaasUsage(
          students: 18,
          staffUsers: 8,
          campuses: 1,
          storageMb: 126,
          smsThisMonth: 74,
          emailThisMonth: 312,
          aiActionsThisMonth: 11,
        ),
      );
    }

    final tenantId = SessionState.instance.tenant?.id;
    if (tenantId == null || tenantId.isEmpty) {
      return Stream<SaasUsage>.value(const SaasUsage());
    }

    if (BackendConfig.isSupabasePrimary) {
      return Stream<SaasUsage>.fromFuture(_loadSupabase(tenantId));
    }

    return _firestore!
        .collection('tenants')
        .doc(tenantId)
        .collection('saas_usage')
        .doc('current')
        .snapshots()
        .map(
          (DocumentSnapshot<Map<String, dynamic>> snapshot) =>
              SaasUsage.fromMap(snapshot.data() ?? <String, dynamic>{}),
        );
  }

  Future<SaasUsage> _loadSupabase(String tenantId) async {
    final response = await SupabaseBootstrap.client.rpc(
      'get_saas_usage',
      params: <String, dynamic>{'p_tenant_id': tenantId},
    );
    final data = response is Map
        ? Map<String, dynamic>.from(response)
        : const <String, dynamic>{};
    return SaasUsage.fromMap(data);
  }
}
