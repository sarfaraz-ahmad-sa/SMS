import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/session_state.dart';
import '../../services/models/user_role.dart';
import 'demo_erp_store.dart';
import 'erp_access_policy.dart';
import 'erp_entity.dart';
import 'erp_record.dart';

class TenantErpService {
  TenantErpService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  bool get isDemoMode => _auth.currentUser == null;

  String get _tenantId {
    final id = SessionState.instance.tenant?.id.trim() ?? '';
    if (id.isEmpty) throw StateError('No active school session.');
    return id;
  }

  String get _actorId {
    return _auth.currentUser?.uid ??
        SessionState.instance.user?.uid ??
        'unknown-user';
  }

  CollectionReference<Map<String, dynamic>> _collection(String collection) {
    return _db
        .collection('tenants')
        .doc(_tenantId)
        .collection(collection);
  }

  Stream<List<ErpRecord>> watch(ErpEntity entity) {
    final user = SessionState.instance.user;
    if (isDemoMode) {
      return DemoErpStore.instance
          .watch(_tenantId, entity)
          .map((List<ErpRecord> records) => _applyLocalScope(entity, records));
    }

    Query<Map<String, dynamic>> query = _collection(entity.collection)
        .where('isArchived', isEqualTo: false);

    final selfScoped = user != null &&
        ErpAccessPolicy.selfServiceCollections.contains(entity.collection) &&
        !user.hasPermission(entity.managePermission);

    if (selfScoped) {
      query = query.where('createdBy', isEqualTo: user.uid);
    } else if (user != null && user.role.isLearner &&
        ErpAccessPolicy.personalStudentCollections.contains(entity.collection)) {
      query = query.where('authUid', isEqualTo: user.uid);
    } else if (user != null && user.role.isGuardian &&
        ErpAccessPolicy.personalStudentCollections.contains(entity.collection)) {
      query = query.where('guardianUids', arrayContains: user.uid);
    }

    return query.limit(500).snapshots().map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        final records = snapshot.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> document) =>
                  ErpRecord(id: document.id, data: document.data()),
            )
            .where((ErpRecord record) => !record.isArchived)
            .toList();
        records.sort((ErpRecord a, ErpRecord b) {
          final left = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final right = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return right.compareTo(left);
        });
        return records;
      },
    );
  }

  List<ErpRecord> _applyLocalScope(
    ErpEntity entity,
    List<ErpRecord> records,
  ) {
    final user = SessionState.instance.user;
    if (user == null) return records;

    final selfScoped =
        ErpAccessPolicy.selfServiceCollections.contains(entity.collection) &&
            !user.hasPermission(entity.managePermission);
    if (selfScoped) {
      return records
          .where((ErpRecord record) =>
              record.data['createdBy'] == user.uid ||
              record.data['requesterUid'] == user.uid)
          .toList(growable: false);
    }

    if (!user.role.isLearner && !user.role.isGuardian) return records;

    if (ErpAccessPolicy.personalStudentCollections
        .contains(entity.collection)) {
      return records.where((ErpRecord record) {
        if (user.role.isLearner) {
          return record.data['authUid'] == user.uid ||
              record.data['studentAuthUid'] == user.uid;
        }
        final guardians = record.data['guardianUids'];
        return guardians is Iterable && guardians.contains(user.uid);
      }).toList(growable: false);
    }
    return records;
  }

  Future<int> countVisible(ErpEntity entity) async {
    return (await watch(entity).first).length;
  }

  Future<int> count(String collection) async {
    if (isDemoMode) {
      return DemoErpStore.instance.count(_tenantId, collection);
    }
    final result = await _collection(collection)
        .where('isArchived', isEqualTo: false)
        .count()
        .get();
    return result.count ?? 0;
  }


  Future<int> countWhere(
    String collection,
    String field,
    dynamic value,
  ) async {
    if (isDemoMode) {
      return DemoErpStore.instance.countWhere(
        _tenantId,
        collection,
        field,
        value,
      );
    }
    final result = await _collection(collection)
        .where('isArchived', isEqualTo: false)
        .where(field, isEqualTo: value)
        .count()
        .get();
    return result.count ?? 0;
  }

  Future<String> create(
    ErpEntity entity,
    Map<String, dynamic> values,
  ) async {
    final state = SessionState.instance;
    final user = state.user;
    final selfServiceMetadata = <String, dynamic>{
      if (user != null &&
          entity.allowSelfServiceCreate &&
          !user.hasPermission(entity.managePermission))
        'requesterUid': user.uid,
      if (user != null && user.role.isLearner) 'authUid': user.uid,
      if (user != null && user.role.isGuardian)
        'guardianUids': <String>[user.uid],
    };
    values = <String, dynamic>{...values, ...selfServiceMetadata};
    if (isDemoMode) {
      return DemoErpStore.instance.create(
        tenantId: _tenantId,
        entity: entity,
        values: values,
        actorId: _actorId,
        campusId: state.activeCampusId,
        academicYearId: state.activeAcademicYearId,
      );
    }

    final reference = _collection(entity.collection).doc();
    await reference.set(<String, dynamic>{
      ...values,
      'tenantId': _tenantId,
      'campusId': state.activeCampusId,
      'academicYearId': state.activeAcademicYearId,
      'createdBy': _actorId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedBy': _actorId,
      'updatedAt': FieldValue.serverTimestamp(),
      'isArchived': false,
    });
    return reference.id;
  }

  Future<void> update(
    ErpEntity entity,
    String recordId,
    Map<String, dynamic> values,
  ) async {
    if (isDemoMode) {
      return DemoErpStore.instance.update(
        tenantId: _tenantId,
        entity: entity,
        recordId: recordId,
        values: values,
        actorId: _actorId,
      );
    }

    await _collection(entity.collection).doc(recordId).update(
      <String, dynamic>{
        ...values,
        'updatedBy': _actorId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> archive(ErpEntity entity, String recordId) async {
    if (isDemoMode) {
      return DemoErpStore.instance.archive(
        tenantId: _tenantId,
        entity: entity,
        recordId: recordId,
        actorId: _actorId,
      );
    }

    await _collection(entity.collection).doc(recordId).update(
      <String, dynamic>{
        'isArchived': true,
        'archivedBy': _actorId,
        'archivedAt': FieldValue.serverTimestamp(),
        'updatedBy': _actorId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }
}
