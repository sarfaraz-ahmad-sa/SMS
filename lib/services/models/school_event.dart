import 'package:cloud_firestore/cloud_firestore.dart';

/// A calendar event. `dateKey` is 'YYYY-MM-DD' for easy day grouping/queries.
class SchoolEvent {
  final String? id;
  final String title;
  final String? description;
  final String type;
  final String dateKey;
  final String tenantId;

  const SchoolEvent({
    this.id,
    required this.title,
    this.description,
    this.type = 'General',
    required this.dateKey,
    this.tenantId = '',
  });

  static String keyFor(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'type': type,
        'dateKey': dateKey,
        'tenantId': tenantId,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory SchoolEvent.fromDoc(String id, Map<String, dynamic> m) {
    return SchoolEvent(
      id: id,
      title: (m['title'] as String?) ?? '',
      description: m['description'] as String?,
      type: (m['type'] as String?) ?? 'General',
      dateKey: (m['dateKey'] as String?) ?? '',
      tenantId: (m['tenantId'] as String?) ?? '',
    );
  }
}
