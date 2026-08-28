import 'package:cloud_firestore/cloud_firestore.dart';

class SaasUsage {
  final int students;
  final int staffUsers;
  final int campuses;
  final int storageMb;
  final int smsThisMonth;
  final int emailThisMonth;
  final int aiActionsThisMonth;
  final DateTime? updatedAt;

  const SaasUsage({
    this.students = 0,
    this.staffUsers = 0,
    this.campuses = 0,
    this.storageMb = 0,
    this.smsThisMonth = 0,
    this.emailThisMonth = 0,
    this.aiActionsThisMonth = 0,
    this.updatedAt,
  });

  factory SaasUsage.fromMap(Map<String, dynamic> map) {
    int readInt(String key, [String? alternate]) {
      final value = map[key] ?? (alternate == null ? null : map[alternate]);
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final rawUpdatedAt = map['updatedAt'] ?? map['updated_at'];
    final updatedAt = rawUpdatedAt is Timestamp
        ? rawUpdatedAt.toDate()
        : DateTime.tryParse(rawUpdatedAt?.toString() ?? '');

    return SaasUsage(
      students: readInt('students'),
      staffUsers: readInt('staffUsers', 'staff_users'),
      campuses: readInt('campuses'),
      storageMb: readInt('storageMb', 'storage_mb'),
      smsThisMonth: readInt('smsThisMonth', 'sms_this_month'),
      emailThisMonth: readInt('emailThisMonth', 'email_this_month'),
      aiActionsThisMonth: readInt('aiActionsThisMonth', 'ai_actions_this_month'),
      updatedAt: updatedAt,
    );
  }
}
