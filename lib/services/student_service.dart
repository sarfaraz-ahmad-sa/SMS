import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/student.dart';

/// Firestore access for student records.
///
/// Collection: `students` (each doc carries `tenantId` for multi-tenant
/// filtering). Swap to `tenants/{tenantId}/students` if you prefer nested
/// isolation.
class StudentService {
  StudentService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('students');

  /// Save a new student. Returns the created document id.
  Future<String> addStudent(Student student) async {
    final ref = await _col.add(student.toMap());
    return ref.id;
  }

  /// Live stream of students (newest first), optionally filtered by tenant.
  Stream<List<Student>> streamStudents({String? tenantId}) {
    Query<Map<String, dynamic>> q = _col.orderBy('createdAt', descending: true);
    if (tenantId != null && tenantId.isNotEmpty) {
      q = _col.where('tenantId', isEqualTo: tenantId);
    }
    return q.snapshots().map((snap) =>
        snap.docs.map((d) => Student.fromDoc(d.id, d.data())).toList());
  }

  Future<void> deleteStudent(String id) => _col.doc(id).delete();
}
