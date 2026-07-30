import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/erp/tenant_erp_service.dart';
import 'models/saas_usage.dart';
import 'session_state.dart';

class SaasUsageService {
  final FirebaseFirestore _firestore;

  SaasUsageService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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

    return _firestore
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
}
