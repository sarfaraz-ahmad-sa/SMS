import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/app_permission.dart';
import 'models/student.dart';
import 'session_state.dart';

class StudentService {
  StudentService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _collection(String tenantId) =>
      _db.collection('tenants').doc(tenantId).collection('students');

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

  Future<String> addStudent(Student student) async {
    _requirePermission(AppPermission.studentsCreate);
    final tenantId = _requireTenant();
    final userId = SessionState.instance.user?.uid;
    if (userId == null) throw StateError('No authenticated user.');

    final normalizedStudent = student.copyWithTenant(tenantId);
    final reference = await _collection(tenantId).add(
      normalizedStudent.toCreateMap(createdBy: userId),
    );
    return reference.id;
  }

  Stream<List<Student>> streamStudents() {
    _requirePermission(AppPermission.studentsView);
    final tenantId = _requireTenant();

    return _collection(tenantId)
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> document) =>
                    Student.fromDoc(document.id, document.data()),
              )
              .where((Student student) => !student.isArchived)
              .toList(),
        );
  }

  Future<void> archiveStudent(String id) async {
    _requirePermission(AppPermission.studentsArchive);
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

  Future<void> deleteStudent(String id) => archiveStudent(id);
}
