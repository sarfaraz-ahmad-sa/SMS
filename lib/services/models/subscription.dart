import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionTier { trial, starter, pro, enterprise }

enum SubscriptionStatus { trialing, active, pastDue, suspended, cancelled }

extension SubscriptionTierX on SubscriptionTier {
  String get label {
    switch (this) {
      case SubscriptionTier.trial:
        return 'Free Trial';
      case SubscriptionTier.starter:
        return 'Starter';
      case SubscriptionTier.pro:
        return 'Pro';
      case SubscriptionTier.enterprise:
        return 'Enterprise';
    }
  }

  String get value => name;

  int get maxStudents {
    switch (this) {
      case SubscriptionTier.trial:
        return 30;
      case SubscriptionTier.starter:
        return 250;
      case SubscriptionTier.pro:
        return 2000;
      case SubscriptionTier.enterprise:
        return 0;
    }
  }
}

SubscriptionTier subscriptionTierFromString(String? value) {
  for (final tier in SubscriptionTier.values) {
    if (tier.value == value?.trim()) return tier;
  }
  return SubscriptionTier.trial;
}

SubscriptionStatus subscriptionStatusFromString(String? value) {
  for (final status in SubscriptionStatus.values) {
    if (status.name == value?.trim()) return status;
  }
  return SubscriptionStatus.trialing;
}

class Subscription {
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final DateTime? currentPeriodEnd;
  final DateTime? trialEndsAt;

  const Subscription({
    required this.tier,
    this.status = SubscriptionStatus.trialing,
    this.currentPeriodEnd,
    this.trialEndsAt,
  });

  bool get isExpired {
    final end = status == SubscriptionStatus.trialing
        ? trialEndsAt ?? currentPeriodEnd
        : currentPeriodEnd;
    return end != null && end.isBefore(DateTime.now());
  }

  bool get isUsable =>
      !isExpired &&
      status != SubscriptionStatus.cancelled &&
      status != SubscriptionStatus.suspended;

  /// Display label exposed directly by the model so callers do not depend on
  /// extension-import resolution.
  String get planLabel => tier.label;

  factory Subscription.fromMap(Map<String, dynamic> map) {
    final legacyActive = map['active'];
    final inferredStatus = legacyActive == false
        ? SubscriptionStatus.suspended
        : subscriptionStatusFromString(map['status']?.toString());

    return Subscription(
      tier: subscriptionTierFromString(map['tier']?.toString()),
      status: inferredStatus,
      currentPeriodEnd: _dateFromValue(map['currentPeriodEnd']),
      trialEndsAt: _dateFromValue(map['trialEndsAt']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'tier': tier.value,
        'status': status.name,
        'active': isUsable,
        'currentPeriodEnd': currentPeriodEnd == null
            ? null
            : Timestamp.fromDate(currentPeriodEnd!),
        'trialEndsAt':
            trialEndsAt == null ? null : Timestamp.fromDate(trialEndsAt!),
      };
}

DateTime? _dateFromValue(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
