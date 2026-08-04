import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/session_state.dart';
import '../../services/supabase_dashboard_summary_service.dart';
import '../../services/supabase_erp_record_service.dart';
import '../../services/supabase_student_service.dart';
import '../../config/backend_config.dart';
import '../../services/models/user_role.dart';
import 'demo_erp_store.dart';
import 'erp_access_policy.dart';
import 'erp_entity.dart';
import 'erp_record.dart';
import 'erp_repository.dart';

class TenantErpService implements ErpRepository {
  TenantErpService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    FirebaseFunctions? functions,
  })  : _db = firestore ??
            (BackendConfig.isSupabasePrimary
                ? null
                : FirebaseFirestore.instance),
        _auth = firebaseAuth ??
            (BackendConfig.isSupabasePrimary ? null : FirebaseAuth.instance),
        _functions = functions ??
            (BackendConfig.isSupabasePrimary
                ? null
                : FirebaseFunctions.instanceFor(region: 'asia-south1'));

  final FirebaseFirestore? _db;
  final FirebaseAuth? _auth;
  final FirebaseFunctions? _functions;
  final SupabaseStudentService? _supabaseStudents =
      BackendConfig.isSupabasePrimary ? SupabaseStudentService() : null;
  final SupabaseErpRecordService? _supabaseRecords =
      BackendConfig.isSupabasePrimary ? SupabaseErpRecordService() : null;
  final SupabaseTrustedErpService? _supabaseTrusted =
      BackendConfig.isSupabasePrimary ? SupabaseTrustedErpService() : null;

  static const Set<String> _meteredCollections = <String>{
    'students',
    'campuses',
  };

  static const Set<String> _trustedMutationCollections = <String>{
    'payments',
    'fee_refunds',
    'payroll_runs',
    'payslips',
    'chart_of_accounts',
    'journal_entries',
    'bank_accounts',
    'expenses',
    'budgets',
    'exam_results',
  };

  @override
  bool get isDemoMode =>
      !BackendConfig.isSupabasePrimary && _auth?.currentUser == null;

  String get _tenantId {
    final id = SessionState.instance.tenant?.id.trim() ?? '';
    if (id.isEmpty) throw StateError('No active school session.');
    return id;
  }

  String get _actorId {
    return _auth?.currentUser?.uid ??
        SessionState.instance.user?.uid ??
        'unknown-user';
  }

  CollectionReference<Map<String, dynamic>> _collection(String collection) {
    return _db!.collection('tenants').doc(_tenantId).collection(collection);
  }

  Query<Map<String, dynamic>> _activeScopeQuery(String collection) {
    Query<Map<String, dynamic>> query = _collection(
      collection,
    ).where('isArchived', isEqualTo: false);
    final state = SessionState.instance;
    final campusId = state.activeCampusId?.trim();
    final academicYearId = state.activeAcademicYearId?.trim();

    if (campusId?.isNotEmpty == true && collection != 'campuses') {
      query = query.where('campusId', isEqualTo: campusId);
    }
    if (academicYearId?.isNotEmpty == true && collection != 'academic_years') {
      query = query.where('academicYearId', isEqualTo: academicYearId);
    }
    return query;
  }

  Stream<List<ErpRecord>> watch(ErpEntity entity) {
    if (BackendConfig.isSupabasePrimary) {
      return Stream<ErpPage>.fromFuture(
        fetchPage(entity, pageSize: 100),
      ).map((page) => page.records);
    }
    if (isDemoMode) {
      return DemoErpStore.instance
          .watch(_tenantId, entity)
          .map((List<ErpRecord> records) => _applyLocalScope(entity, records));
    }

    final query = _applyAccessScope(
      entity,
      _activeScopeQuery(entity.collection),
    );

    return query.limit(100).snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
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
    });
  }

  Query<Map<String, dynamic>> _applyAccessScope(
    ErpEntity entity,
    Query<Map<String, dynamic>> query,
  ) {
    final user = SessionState.instance.user;
    final selfScoped = user != null &&
        ErpAccessPolicy.selfServiceCollections.contains(entity.collection) &&
        !user.hasPermission(entity.managePermission);

    if (selfScoped) {
      return query.where('createdBy', isEqualTo: user.uid);
    }
    if (user != null &&
        user.role.isLearner &&
        ErpAccessPolicy.personalStudentCollections.contains(
          entity.collection,
        )) {
      if (entity.collection == 'students' ||
          user.linkedRecordId == null ||
          user.linkedRecordId!.isEmpty) {
        return query.where('authUid', isEqualTo: user.uid);
      }
      return query.where('studentRecordId', isEqualTo: user.linkedRecordId);
    }
    if (user != null &&
        user.role.isGuardian &&
        ErpAccessPolicy.personalStudentCollections.contains(
          entity.collection,
        )) {
      return query.where('guardianUids', arrayContains: user.uid);
    }
    return query;
  }

  @override
  Future<ErpPage> fetchPage(
    ErpEntity entity, {
    int pageSize = 50,
    Object? startAfter,
  }) async {
    final safePageSize = pageSize.clamp(10, 100).toInt();
    if (BackendConfig.isSupabasePrimary) {
      final scope = _supabaseScope();
      final cursor = startAfter?.toString();
      if (entity.collection != 'students') {
        if (entity.collection == 'payments') {
          return _supabaseTrusted!.fetchPayments(
            tenantId: scope.$1,
            campusId: scope.$2,
            academicYearId: scope.$3,
            pageSize: safePageSize,
            afterId: cursor,
          );
        }
        return _supabaseRecords!.fetchPage(
          tenantId: scope.$1,
          collection: entity.collection,
          campusId: scope.$2,
          academicYearId: scope.$3,
          pageSize: safePageSize,
          afterId: cursor,
        );
      }
      final page = await _supabaseStudents!.fetchPage(
        tenantId: scope.$1,
        campusId: scope.$2,
        academicYearId: scope.$3,
        pageSize: safePageSize,
        afterId: cursor,
      );
      return ErpPage(
        records: page.records.map(_studentRecord).toList(growable: false),
        hasMore: page.hasMore,
        cursor: page.nextCursor,
      );
    }
    if (isDemoMode) {
      final records = await DemoErpStore.instance
          .watch(_tenantId, entity)
          .map((items) => _applyLocalScope(entity, items))
          .first;
      return ErpPage(
        records: records.take(safePageSize).toList(growable: false),
        hasMore: false,
      );
    }

    Query<Map<String, dynamic>> query = _applyAccessScope(
      entity,
      _activeScopeQuery(entity.collection),
    ).orderBy(FieldPath.documentId);
    if (startAfter != null &&
        startAfter is! DocumentSnapshot<Map<String, dynamic>>) {
      throw ArgumentError.value(startAfter, 'startAfter', 'Invalid cursor.');
    }
    final firestoreCursor =
        startAfter as DocumentSnapshot<Map<String, dynamic>>?;
    if (firestoreCursor != null) {
      query = query.startAfterDocument(firestoreCursor);
    }
    final snapshot = await query.limit(safePageSize + 1).get();
    final hasMore = snapshot.docs.length > safePageSize;
    final pageDocuments = snapshot.docs.take(safePageSize).toList();
    return ErpPage(
      records: pageDocuments
          .map((document) => ErpRecord(id: document.id, data: document.data()))
          .toList(growable: false),
      hasMore: hasMore,
      cursor: pageDocuments.isEmpty ? firestoreCursor : pageDocuments.last,
    );
  }

  List<ErpRecord> _applyLocalScope(ErpEntity entity, List<ErpRecord> records) {
    final user = SessionState.instance.user;
    if (user == null) return records;

    final selfScoped =
        ErpAccessPolicy.selfServiceCollections.contains(entity.collection) &&
            !user.hasPermission(entity.managePermission);
    if (selfScoped) {
      return records
          .where(
            (ErpRecord record) =>
                record.data['createdBy'] == user.uid ||
                record.data['requesterUid'] == user.uid,
          )
          .toList(growable: false);
    }

    if (!user.role.isLearner && !user.role.isGuardian) return records;

    if (ErpAccessPolicy.personalStudentCollections.contains(
      entity.collection,
    )) {
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

  @override
  Future<int> countVisible(ErpEntity entity) async {
    if (BackendConfig.isSupabasePrimary) {
      return count(entity.collection);
    }
    if (isDemoMode) {
      final records = await DemoErpStore.instance
          .watch(_tenantId, entity)
          .map((items) => _applyLocalScope(entity, items))
          .first;
      return records.length;
    }
    final query = _applyAccessScope(
      entity,
      _activeScopeQuery(entity.collection),
    );
    final result = await query.count().get();
    return result.count ?? 0;
  }

  @override
  Future<Map<String, dynamic>> loadDashboardSummary() async {
    if (BackendConfig.isSupabasePrimary) {
      final scope = _supabaseScope();
      return SupabaseDashboardSummaryService().load(
        tenantId: scope.$1,
        campusId: scope.$2,
        academicYearId: scope.$3,
      );
    }
    if (isDemoMode) return const <String, dynamic>{};
    final state = SessionState.instance;
    final year = Uri.encodeComponent(
      state.activeAcademicYearId?.trim().isNotEmpty == true
          ? state.activeAcademicYearId!.trim()
          : 'all',
    );
    final campus = Uri.encodeComponent(
      state.activeCampusId?.trim().isNotEmpty == true
          ? state.activeCampusId!.trim()
          : 'all',
    );
    try {
      final snapshot = await _collection(
        'dashboard_summaries',
      ).doc('scope_${year}_$campus').get();
      return snapshot.data() ?? const <String, dynamic>{};
    } on FirebaseException catch (error) {
      // Older deployments may not yet expose/backfill the summary document.
      // Returning an empty summary keeps the bounded aggregate fallback usable.
      if (error.code == 'permission-denied' || error.code == 'not-found') {
        return const <String, dynamic>{};
      }
      rethrow;
    }
  }

  @override
  Future<int> count(String collection) async {
    if (BackendConfig.isSupabasePrimary) {
      final summary = await loadDashboardSummary();
      final counts = summary['counts'];
      return counts is Map ? (counts[collection] as num?)?.toInt() ?? 0 : 0;
    }
    if (isDemoMode) {
      return DemoErpStore.instance.count(_tenantId, collection);
    }
    final result = await _activeScopeQuery(collection).count().get();
    return result.count ?? 0;
  }

  @override
  Future<int> countWhere(String collection, String field, dynamic value) async {
    if (BackendConfig.isSupabasePrimary) {
      if (field != 'status') return 0;
      final summary = await loadDashboardSummary();
      final statuses = summary['statusCounts'];
      final collectionStatuses = statuses is Map ? statuses[collection] : null;
      return collectionStatuses is Map
          ? (collectionStatuses[value.toString().toLowerCase()] as num?)
                  ?.toInt() ??
              0
          : 0;
    }
    if (isDemoMode) {
      return DemoErpStore.instance.countWhere(
        _tenantId,
        collection,
        field,
        value,
      );
    }
    final result = await _activeScopeQuery(
      collection,
    ).where(field, isEqualTo: value).count().get();
    return result.count ?? 0;
  }

  @override
  Future<String> create(ErpEntity entity, Map<String, dynamic> values) async {
    final state = SessionState.instance;
    if (BackendConfig.isSupabasePrimary) {
      if (entity.collection != 'students') {
        final scope = _supabaseScope();
        if (_trustedMutationCollections.contains(entity.collection)) {
          return _supabaseTrusted!.create(
            tenantId: scope.$1,
            collection: entity.collection,
            campusId: scope.$2,
            academicYearId: scope.$3,
            values: values,
          );
        }
        return _supabaseRecords!.create(
          tenantId: scope.$1,
          collection: entity.collection,
          campusId: scope.$2,
          academicYearId: scope.$3,
          values: values,
        );
      }
      final scope = _supabaseScope();
      final placement = await _placementFromValues(scope, values);
      final created = await _supabaseStudents!.create(
        tenantId: scope.$1,
        student: SupabaseStudentDraft(
          campusId: scope.$2,
          academicYearId: scope.$3,
          admissionNo: values['admissionNo']?.toString() ?? '',
          fullName: values['fullName']?.toString() ?? '',
          classId: placement?.classId,
          sectionId: placement?.sectionId,
          dateOfBirth: _optionalDate(values['dateOfBirth']),
          gender: values['gender']?.toString(),
          status: _studentStatus(values['status']),
        ),
      );
      return created.id;
    }
    final user = state.user;
    final isSelfService = user != null &&
        entity.allowSelfServiceCreate &&
        !user.hasPermission(entity.managePermission);
    final selfServiceMetadata = <String, dynamic>{
      if (isSelfService) ...<String, dynamic>{
        'requesterUid': user.uid,
        ..._selfServiceDefaults(entity.collection),
      },
      if (user != null && user.role.isLearner) 'authUid': user.uid,
      if (user != null && user.role.isGuardian)
        'guardianUids': <String>[user.uid],
    };
    values = <String, dynamic>{
      ...values,
      ...selfServiceMetadata,
      if (isSelfService &&
          user.role.isLearner &&
          user.linkedRecordId?.isNotEmpty == true)
        'studentRecordId': user.linkedRecordId,
    };
    if (!isDemoMode && entity.collection != 'students') {
      values = await _enrichStudentRelationship(values);
    }
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

    if (_trustedMutationCollections.contains(entity.collection)) {
      final result = await _functions!
          .httpsCallable('mutateTrustedErpRecord')
          .call(<String, dynamic>{
        'tenantId': _tenantId,
        'collection': entity.collection,
        'operation': 'create',
        'values': values,
        'campusId': state.activeCampusId,
        'academicYearId': state.activeAcademicYearId,
      });
      final data = result.data;
      if (data is Map && data['recordId'] != null) {
        return data['recordId'].toString();
      }
      throw StateError('The trusted backend did not return a record ID.');
    }

    if (_meteredCollections.contains(entity.collection)) {
      final result = await _functions!
          .httpsCallable('createMeteredErpRecord')
          .call(<String, dynamic>{
        'tenantId': _tenantId,
        'collection': entity.collection,
        'values': values,
        'campusId': state.activeCampusId,
        'academicYearId': state.activeAcademicYearId,
      });
      final data = result.data;
      if (data is Map && data['recordId'] != null) {
        return data['recordId'].toString();
      }
      throw StateError('The trusted backend did not return a record ID.');
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

  Future<Map<String, dynamic>> _enrichStudentRelationship(
    Map<String, dynamic> values,
  ) async {
    final explicitRecordId = values['studentRecordId']?.toString().trim();
    final studentReference = values['studentId']?.toString().trim();
    final admissionReference = values['admissionNo']?.toString().trim();
    final lookup = explicitRecordId?.isNotEmpty == true
        ? explicitRecordId!
        : studentReference?.isNotEmpty == true
            ? studentReference!
            : admissionReference?.isNotEmpty == true
                ? admissionReference!
                : '';
    if (lookup.isEmpty) return values;

    DocumentSnapshot<Map<String, dynamic>>? student;
    final direct = await _collection('students').doc(lookup).get();
    if (direct.exists) {
      student = direct;
    } else {
      final byAdmission = await _collection(
        'students',
      ).where('admissionNo', isEqualTo: lookup).limit(2).get();
      if (byAdmission.docs.length == 1) student = byAdmission.docs.first;
    }
    final data = student?.data();
    if (student == null || data == null) return values;

    final authUid = data['authUid']?.toString().trim();
    final rawGuardians = data['guardianUids'];
    final guardianUids = rawGuardians is Iterable
        ? rawGuardians
            .map((dynamic value) => value?.toString().trim() ?? '')
            .where((String value) => value.isNotEmpty)
            .toSet()
            .toList(growable: false)
        : const <String>[];

    return <String, dynamic>{
      ...values,
      'studentRecordId': student.id,
      if (authUid?.isNotEmpty == true) 'authUid': authUid,
      if (guardianUids.isNotEmpty) 'guardianUids': guardianUids,
    };
  }

  Map<String, dynamic> _selfServiceDefaults(String collection) {
    switch (collection) {
      case 'library_reservations':
        return const <String, dynamic>{'status': 'Waiting'};
      case 'event_registrations':
        return const <String, dynamic>{
          'status': 'Registered',
          'feePaid': false,
          'attendanceMarked': false,
        };
      case 'certificate_requests':
        return const <String, dynamic>{'status': 'Requested'};
      case 'student_leave_requests':
      case 'leave_requests':
        return const <String, dynamic>{'status': 'Pending'};
      case 'parent_meetings':
        return const <String, dynamic>{'status': 'Requested'};
      case 'support_tickets':
        return const <String, dynamic>{
          'status': 'Open',
          'assignedTo': '',
          'resolution': '',
        };
      case 'complaints':
        return const <String, dynamic>{'status': 'Received'};
      default:
        return const <String, dynamic>{};
    }
  }

  @override
  Future<void> update(
    ErpEntity entity,
    String recordId,
    Map<String, dynamic> values,
  ) async {
    if (BackendConfig.isSupabasePrimary) {
      if (entity.collection != 'students') {
        final scope = _supabaseScope();
        if (_trustedMutationCollections.contains(entity.collection)) {
          await _supabaseTrusted!.update(
            tenantId: scope.$1,
            collection: entity.collection,
            campusId: scope.$2,
            academicYearId: scope.$3,
            recordId: recordId,
            values: values,
          );
          return;
        }
        await _supabaseRecords!.update(
          tenantId: scope.$1,
          collection: entity.collection,
          campusId: scope.$2,
          academicYearId: scope.$3,
          recordId: recordId,
          values: values,
        );
        return;
      }
      final scope = _supabaseScope();
      final current = await _supabaseStudents!.fetchById(
        tenantId: scope.$1,
        campusId: scope.$2,
        academicYearId: scope.$3,
        studentId: recordId,
      );
      final placement = await _placementFromValues(scope, values);
      await _supabaseStudents.update(
        student: current,
        changes: SupabaseStudentDraft(
          campusId: scope.$2,
          academicYearId: scope.$3,
          admissionNo: values['admissionNo']?.toString() ?? current.admissionNo,
          fullName: values['fullName']?.toString() ?? current.fullName,
          classId: placement?.classId ?? current.classId,
          sectionId: placement?.sectionId ?? current.sectionId,
          dateOfBirth:
              _optionalDate(values['dateOfBirth']) ?? current.dateOfBirth,
          gender: values['gender']?.toString() ?? current.gender,
          status: values.containsKey('status')
              ? _studentStatus(values['status'])
              : current.status,
        ),
      );
      return;
    }
    if (!isDemoMode &&
        entity.collection != 'students' &&
        (values.containsKey('studentId') ||
            values.containsKey('admissionNo') ||
            values.containsKey('studentRecordId'))) {
      values = await _enrichStudentRelationship(values);
    }
    if (isDemoMode) {
      return DemoErpStore.instance.update(
        tenantId: _tenantId,
        entity: entity,
        recordId: recordId,
        values: values,
        actorId: _actorId,
      );
    }

    if (_trustedMutationCollections.contains(entity.collection)) {
      await _functions!
          .httpsCallable('mutateTrustedErpRecord')
          .call(<String, dynamic>{
        'tenantId': _tenantId,
        'collection': entity.collection,
        'operation': 'update',
        'recordId': recordId,
        'values': values,
        'campusId': SessionState.instance.activeCampusId,
        'academicYearId': SessionState.instance.activeAcademicYearId,
      });
      return;
    }

    await _collection(entity.collection).doc(recordId).update(<String, dynamic>{
      ...values,
      'updatedBy': _actorId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> archive(ErpEntity entity, String recordId) async {
    if (BackendConfig.isSupabasePrimary) {
      if (entity.collection != 'students') {
        final scope = _supabaseScope();
        if (_trustedMutationCollections.contains(entity.collection)) {
          await _supabaseTrusted!.archive(
            tenantId: scope.$1,
            collection: entity.collection,
            campusId: scope.$2,
            academicYearId: scope.$3,
            recordId: recordId,
          );
          return;
        }
        await _supabaseRecords!.archive(
          tenantId: scope.$1,
          collection: entity.collection,
          campusId: scope.$2,
          academicYearId: scope.$3,
          recordId: recordId,
        );
        return;
      }
      final scope = _supabaseScope();
      final student = await _supabaseStudents!.fetchById(
        tenantId: scope.$1,
        campusId: scope.$2,
        academicYearId: scope.$3,
        studentId: recordId,
      );
      await _supabaseStudents.archive(student);
      return;
    }
    if (isDemoMode) {
      return DemoErpStore.instance.archive(
        tenantId: _tenantId,
        entity: entity,
        recordId: recordId,
        actorId: _actorId,
      );
    }

    if (_trustedMutationCollections.contains(entity.collection)) {
      await _functions!
          .httpsCallable('mutateTrustedErpRecord')
          .call(<String, dynamic>{
        'tenantId': _tenantId,
        'collection': entity.collection,
        'operation': 'archive',
        'recordId': recordId,
      });
      return;
    }

    if (_meteredCollections.contains(entity.collection)) {
      await _functions!.httpsCallable('archiveMeteredErpRecord').call(
        <String, dynamic>{
          'tenantId': _tenantId,
          'collection': entity.collection,
          'recordId': recordId,
        },
      );
      return;
    }

    await _collection(entity.collection).doc(recordId).update(<String, dynamic>{
      'isArchived': true,
      'archivedBy': _actorId,
      'archivedAt': FieldValue.serverTimestamp(),
      'updatedBy': _actorId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  (String, String, String) _supabaseScope() {
    final state = SessionState.instance;
    final tenantId = state.tenant?.id.trim() ?? '';
    final campusId = state.activeCampusId?.trim() ?? '';
    final academicYearId = state.activeAcademicYearId?.trim() ?? '';
    if (tenantId.isEmpty || campusId.isEmpty || academicYearId.isEmpty) {
      throw StateError('School, campus, and academic year are required.');
    }
    return (tenantId, campusId, academicYearId);
  }

  Future<SupabaseStudentPlacement?> _placementFromValues(
    (String, String, String) scope,
    Map<String, dynamic> values,
  ) async {
    final className = values['className']?.toString().trim() ?? '';
    final sectionName = values['sectionName']?.toString().trim() ?? '';
    if (className.isEmpty && sectionName.isEmpty) return null;
    if (className.isEmpty || sectionName.isEmpty) {
      throw StateError('Both class and section are required.');
    }
    return _supabaseStudents!.resolvePlacement(
      tenantId: scope.$1,
      campusId: scope.$2,
      academicYearId: scope.$3,
      className: className,
      sectionName: sectionName,
    );
  }

  ErpRecord _studentRecord(SupabaseStudentRecord student) {
    return ErpRecord(
      id: student.id,
      data: <String, dynamic>{
        'admissionNo': student.admissionNo,
        'fullName': student.fullName,
        'dateOfBirth': student.dateOfBirth?.toIso8601String().split('T').first,
        'gender': _titleCase(student.gender),
        'className': student.classId ?? '',
        'sectionName': student.sectionId ?? '',
        'status': _titleCase(student.status),
        'updatedAt': student.updatedAt,
        'isArchived': false,
      },
    );
  }

  String _studentStatus(dynamic value) {
    return switch (value?.toString().trim().toLowerCase()) {
      'on leave' => 'inactive',
      'transferred' => 'withdrawn',
      'withdrawn' => 'withdrawn',
      'graduated' => 'graduated',
      'inactive' => 'inactive',
      _ => 'active',
    };
  }

  String _titleCase(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty
        ? ''
        : '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }

  DateTime? _optionalDate(dynamic value) {
    if (value is DateTime) return value;
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : DateTime.tryParse(text);
  }
}
