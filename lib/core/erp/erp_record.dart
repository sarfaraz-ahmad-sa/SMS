import 'package:cloud_firestore/cloud_firestore.dart';

class ErpRecord {
  final String id;
  final Map<String, dynamic> data;

  const ErpRecord({required this.id, required this.data});

  dynamic operator [](String key) => data[key];

  DateTime? get createdAt => _toDate(data['createdAt']);

  DateTime? get updatedAt => _toDate(data['updatedAt']) ?? createdAt;

  bool get isArchived => data['isArchived'] == true;

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
