import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolEvent {
  final String? id;
  final String title;
  final String? description;
  final String type;
  final String dateKey;
  final String tenantId;
  final bool isArchived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SchoolEvent({
    this.id,
    required this.title,
    this.description,
    this.type = 'General',
    required this.dateKey,
    required this.tenantId,
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
  });

  static String keyFor(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  SchoolEvent copyWithTenant(String tenantId) => SchoolEvent(
        id: id,
        title: title,
        description: description,
        type: type,
        dateKey: dateKey,
        tenantId: tenantId,
        isArchived: isArchived,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  Map<String, dynamic> toCreateMap({required String createdBy}) =>
      <String, dynamic>{
        'title': title.trim(),
        'description': description?.trim(),
        'type': type,
        'dateKey': dateKey,
        'tenantId': tenantId,
        'isArchived': false,
        'createdBy': createdBy,
        'updatedBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory SchoolEvent.fromDoc(String id, Map<String, dynamic> map) {
    return SchoolEvent(
      id: id,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString(),
      type: map['type']?.toString() ?? 'General',
      dateKey: map['dateKey']?.toString() ?? '',
      tenantId: map['tenantId']?.toString() ?? '',
      isArchived: map['isArchived'] is bool
          ? map['isArchived'] as bool
          : false,
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
    );
  }
}

DateTime? _dateFromValue(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
