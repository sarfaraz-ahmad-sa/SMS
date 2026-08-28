import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/backend_config.dart';
import 'models/app_permission.dart';
import 'models/school_event.dart';
import 'session_state.dart';
import 'supabase_erp_record_service.dart';

class EventService {
  EventService({FirebaseFirestore? firestore})
      : _db = firestore ??
            (BackendConfig.isSupabasePrimary
                ? null
                : FirebaseFirestore.instance);

  final FirebaseFirestore? _db;
  final SupabaseErpRecordService? _supabase = BackendConfig.isSupabasePrimary
      ? SupabaseErpRecordService()
      : null;

  CollectionReference<Map<String, dynamic>> _collection(String tenantId) =>
      _db!.collection('tenants').doc(tenantId).collection('events');

  (String, String, String) _supabaseScope() {
    final state = SessionState.instance;
    final tenantId = state.tenant?.id.trim() ?? '';
    final campusId = state.activeCampusId?.trim() ?? '';
    final academicYearId = state.activeAcademicYearId?.trim() ?? '';
    if (tenantId.isEmpty || campusId.isEmpty || academicYearId.isEmpty) {
      throw StateError('School, campus or academic year is not selected.');
    }
    return (tenantId, campusId, academicYearId);
  }

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
    if (BackendConfig.isSupabasePrimary) {
      final scope = _supabaseScope();
      return _supabase!.create(
        tenantId: scope.$1,
        collection: 'events',
        campusId: scope.$2,
        academicYearId: scope.$3,
        values: <String, dynamic>{
          'title': event.title,
          'description': event.description,
          'type': event.type,
          'dateKey': event.dateKey,
          'status': 'Published',
        },
      );
    }
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
    if (BackendConfig.isSupabasePrimary) {
      final scope = _supabaseScope();
      return _supabase!.archive(
        tenantId: scope.$1,
        collection: 'events',
        campusId: scope.$2,
        academicYearId: scope.$3,
        recordId: id,
      );
    }
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
    if (BackendConfig.isSupabasePrimary) {
      final scope = _supabaseScope();
      return Stream.fromFuture(
        _supabase!.fetchPage(
          tenantId: scope.$1,
          collection: 'events',
          campusId: scope.$2,
          academicYearId: scope.$3,
          pageSize: 100,
        ),
      ).map(
        (page) => page.records
            .map((record) => SchoolEvent.fromDoc(record.id, record.data))
            .toList(growable: false),
      );
    }
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
