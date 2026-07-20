import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/app_permission.dart';
import 'models/school_event.dart';
import 'session_state.dart';

class EventService {
  EventService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _collection(String tenantId) =>
      _db.collection('tenants').doc(tenantId).collection('events');

  String _requireTenant() {
    final tenantId = SessionState.instance.tenant?.id;
    if (tenantId == null || tenantId.isEmpty) {
      throw StateError('No active school session.');
    }
    return tenantId;
  }

  void _requirePermission(String permission) {
    if (!SessionState.instance.hasPermission(permission)) {
      throw StateError('Permission denied: $permission');
    }
  }

  Future<String> addEvent(SchoolEvent event) async {
    _requirePermission(AppPermission.eventsManage);
    final tenantId = _requireTenant();
    final userId = SessionState.instance.user?.uid;
    if (userId == null) throw StateError('No authenticated user.');

    final reference = await _collection(tenantId).add(
      event.copyWithTenant(tenantId).toCreateMap(createdBy: userId),
    );
    return reference.id;
  }

  Future<void> archiveEvent(String id) async {
    _requirePermission(AppPermission.eventsManage);
    final tenantId = _requireTenant();
    final userId = SessionState.instance.user?.uid;
    if (userId == null) throw StateError('No authenticated user.');

    await _collection(tenantId).doc(id).update(<String, dynamic>{
      'isArchived': true,
      'archivedAt': FieldValue.serverTimestamp(),
      'archivedBy': userId,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': userId,
    });
  }

  Future<void> deleteEvent(String id) => archiveEvent(id);

  Stream<List<SchoolEvent>> streamEvents() {
    _requirePermission(AppPermission.eventsView);
    final tenantId = _requireTenant();
    return _collection(tenantId)
        .where('isArchived', isEqualTo: false)
        .orderBy('dateKey')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> document) =>
                    SchoolEvent.fromDoc(document.id, document.data()),
              )
              .where((SchoolEvent event) => !event.isArchived)
              .toList(),
        );
  }
}
