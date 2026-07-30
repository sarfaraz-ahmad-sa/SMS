import 'package:cloud_firestore/cloud_firestore.dart';

enum ApprovalStatus {
  draft,
  submitted,
  underReview,
  approved,
  rejected,
  completed,
  cancelled,
}

class ApprovalRequest {
  final String id;
  final String tenantId;
  final String type;
  final String title;
  final String requesterUid;
  final String? assignedToUid;
  final ApprovalStatus status;
  final String recordCollection;
  final String recordId;
  final int currentStep;
  final int totalSteps;
  final DateTime createdAt;
  final DateTime? decidedAt;

  const ApprovalRequest({
    required this.id,
    required this.tenantId,
    required this.type,
    required this.title,
    required this.requesterUid,
    required this.status,
    required this.recordCollection,
    required this.recordId,
    required this.createdAt,
    this.assignedToUid,
    this.currentStep = 1,
    this.totalSteps = 1,
    this.decidedAt,
  });

  factory ApprovalRequest.fromMap(String id, Map<String, dynamic> map) {
    ApprovalStatus parseStatus(dynamic value) {
      final raw = value?.toString();
      return ApprovalStatus.values.firstWhere(
        (ApprovalStatus status) => status.name == raw,
        orElse: () => ApprovalStatus.draft,
      );
    }

    DateTime parseDate(dynamic value, {bool required = false}) {
      if (value is Timestamp) return value.toDate();
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      return parsed ?? (required ? DateTime.now() : DateTime.now());
    }

    return ApprovalRequest(
      id: id,
      tenantId: map['tenantId']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      requesterUid: map['requesterUid']?.toString() ?? '',
      assignedToUid: map['assignedToUid']?.toString(),
      status: parseStatus(map['status']),
      recordCollection: map['recordCollection']?.toString() ?? '',
      recordId: map['recordId']?.toString() ?? '',
      currentStep: (map['currentStep'] as num?)?.toInt() ?? 1,
      totalSteps: (map['totalSteps'] as num?)?.toInt() ?? 1,
      createdAt: parseDate(map['createdAt'], required: true),
      decidedAt: map['decidedAt'] == null ? null : parseDate(map['decidedAt']),
    );
  }
}
