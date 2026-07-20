import 'package:cloud_firestore/cloud_firestore.dart';

class AccessRequestService {
  AccessRequestService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<String> submit({
    required String schoolCode,
    required String name,
    required String rollNumber,
    required String className,
    required String email,
    required String phone,
  }) async {
    final reference = await _db.collection('accessRequests').add({
      'schoolCode': schoolCode.trim().toUpperCase(),
      'name': name.trim(),
      'rollNumber': rollNumber.trim(),
      'className': className.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  }
}
