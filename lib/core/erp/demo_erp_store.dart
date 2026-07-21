import 'dart:async';

import 'erp_catalog.dart';
import 'erp_entity.dart';
import 'erp_record.dart';

class DemoErpStore {
  DemoErpStore._();

  static final DemoErpStore instance = DemoErpStore._();

  final Map<String, Map<String, ErpRecord>> _records =
      <String, Map<String, ErpRecord>>{};
  final Map<String, StreamController<List<ErpRecord>>> _controllers =
      <String, StreamController<List<ErpRecord>>>{};
  final Set<String> _seededTenants = <String>{};

  void ensureSeeded(String tenantId) {
    if (_seededTenants.contains(tenantId)) return;
    _seededTenants.add(tenantId);

    final now = DateTime.now().toIso8601String();
    for (final module in ErpCatalog.modules) {
      for (final entity in module.entities) {
        final bucket = _bucket(tenantId, entity.collection);
        for (var index = 0; index < entity.demoRecords.length; index++) {
          final id = 'demo_${entity.collection}_${index + 1}';
          bucket[id] = ErpRecord(
            id: id,
            data: <String, dynamic>{
              ...entity.demoRecords[index],
              'tenantId': tenantId,
              'campusId': 'main_campus',
              'academicYearId': '2026-2027',
              'authUid': 'debug-school-owner',
              'studentAuthUid': 'debug-school-owner',
              'guardianUids': const <String>['debug-school-owner'],
              'requesterUid': 'debug-school-owner',
              'createdBy': 'debug-school-owner',
              'createdAt': now,
              'updatedBy': 'debug-school-owner',
              'updatedAt': now,
              'isArchived': false,
            },
          );
        }
      }
    }
  }

  Stream<List<ErpRecord>> watch(String tenantId, ErpEntity entity) async* {
    ensureSeeded(tenantId);
    yield _snapshot(tenantId, entity.collection);
    yield* _controller(tenantId, entity.collection).stream;
  }

  Future<int> count(String tenantId, String collection) async {
    ensureSeeded(tenantId);
    return _snapshot(tenantId, collection).length;
  }


  Future<int> countWhere(
    String tenantId,
    String collection,
    String field,
    dynamic value,
  ) async {
    ensureSeeded(tenantId);
    return _snapshot(tenantId, collection)
        .where((ErpRecord record) => record.data[field] == value)
        .length;
  }

  Future<String> create({
    required String tenantId,
    required ErpEntity entity,
    required Map<String, dynamic> values,
    required String actorId,
    String? campusId,
    String? academicYearId,
  }) async {
    ensureSeeded(tenantId);
    final id = 'demo_${entity.collection}_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();
    _bucket(tenantId, entity.collection)[id] = ErpRecord(
      id: id,
      data: <String, dynamic>{
        ...values,
        'tenantId': tenantId,
        'campusId': campusId,
        'academicYearId': academicYearId,
        'createdBy': actorId,
        'createdAt': now,
        'updatedBy': actorId,
        'updatedAt': now,
        'isArchived': false,
      },
    );
    _emit(tenantId, entity.collection);
    return id;
  }

  Future<void> update({
    required String tenantId,
    required ErpEntity entity,
    required String recordId,
    required Map<String, dynamic> values,
    required String actorId,
  }) async {
    ensureSeeded(tenantId);
    final bucket = _bucket(tenantId, entity.collection);
    final existing = bucket[recordId];
    if (existing == null) throw StateError('Record not found.');
    bucket[recordId] = ErpRecord(
      id: recordId,
      data: <String, dynamic>{
        ...existing.data,
        ...values,
        'updatedBy': actorId,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
    _emit(tenantId, entity.collection);
  }

  Future<void> archive({
    required String tenantId,
    required ErpEntity entity,
    required String recordId,
    required String actorId,
  }) async {
    ensureSeeded(tenantId);
    final bucket = _bucket(tenantId, entity.collection);
    final existing = bucket[recordId];
    if (existing == null) throw StateError('Record not found.');
    final now = DateTime.now().toIso8601String();
    bucket[recordId] = ErpRecord(
      id: recordId,
      data: <String, dynamic>{
        ...existing.data,
        'isArchived': true,
        'archivedBy': actorId,
        'archivedAt': now,
        'updatedBy': actorId,
        'updatedAt': now,
      },
    );
    _emit(tenantId, entity.collection);
  }

  Map<String, ErpRecord> _bucket(String tenantId, String collection) {
    return _records.putIfAbsent(
      '$tenantId/$collection',
      () => <String, ErpRecord>{},
    );
  }

  StreamController<List<ErpRecord>> _controller(
    String tenantId,
    String collection,
  ) {
    return _controllers.putIfAbsent(
      '$tenantId/$collection',
      () => StreamController<List<ErpRecord>>.broadcast(),
    );
  }

  List<ErpRecord> _snapshot(String tenantId, String collection) {
    final values = _bucket(tenantId, collection)
        .values
        .where((ErpRecord record) => !record.isArchived)
        .toList();
    values.sort((ErpRecord a, ErpRecord b) {
      final left = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
    return List<ErpRecord>.unmodifiable(values);
  }

  void _emit(String tenantId, String collection) {
    _controller(tenantId, collection).add(_snapshot(tenantId, collection));
  }
}
