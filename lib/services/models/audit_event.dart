import 'package:cloud_firestore/cloud_firestore.dart';

class AuditEvent {
  final String id;
  final String tenantId;
  final String actorUid;
  final String action;
  final String module;
  final String recordId;
  final Map<String, dynamic> before;
  final Map<String, dynamic> after;
  final String? reason;
  final String? approvalId;
  final DateTime occurredAt;

  const AuditEvent({
    required this.id,
    required this.tenantId,
    required this.actorUid,
    required this.action,
    required this.module,
    required this.recordId,
    required this.occurredAt,
    this.before = const <String, dynamic>{},
    this.after = const <String, dynamic>{},
    this.reason,
    this.approvalId,
  });

  factory AuditEvent.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    Map<String, dynamic> readMap(dynamic value) => value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};

    return AuditEvent(
      id: id,
      tenantId: map['tenantId']?.toString() ?? '',
      actorUid: map['actorUid']?.toString() ?? '',
      action: map['action']?.toString() ?? '',
      module: map['module']?.toString() ?? '',
      recordId: map['recordId']?.toString() ?? '',
      before: readMap(map['before']),
      after: readMap(map['after']),
      reason: map['reason']?.toString(),
      approvalId: map['approvalId']?.toString(),
      occurredAt: parseDate(map['occurredAt']),
    );
  }
}
