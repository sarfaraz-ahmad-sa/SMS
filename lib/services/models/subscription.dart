import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionTier { trial, starter, standard, pro, enterprise, custom }

enum SubscriptionStatus { trialing, active, pastDue, suspended, cancelled }

extension SubscriptionTierX on SubscriptionTier {
  String get label {
    switch (this) {
      case SubscriptionTier.trial:
        return 'Free Trial';
      case SubscriptionTier.starter:
        return 'Starter';
      case SubscriptionTier.standard:
        return 'Standard';
      case SubscriptionTier.pro:
        return 'Professional';
      case SubscriptionTier.enterprise:
        return 'Enterprise';
      case SubscriptionTier.custom:
        return 'Custom';
    }
  }

  String get value => name;

  int get monthlyPricePkr {
    switch (this) {
      case SubscriptionTier.trial:
        return 0;
      case SubscriptionTier.starter:
        return 3000;
      case SubscriptionTier.standard:
        return 6000;
      case SubscriptionTier.pro:
        return 10000;
      case SubscriptionTier.enterprise:
      case SubscriptionTier.custom:
        return 0;
    }
  }

  int get maxStudents {
    switch (this) {
      case SubscriptionTier.trial:
        return 30;
      case SubscriptionTier.starter:
        return 200;
      case SubscriptionTier.standard:
        return 500;
      case SubscriptionTier.pro:
        return 1000;
      case SubscriptionTier.enterprise:
      case SubscriptionTier.custom:
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
  final DateTime? gracePeriodEndsAt;
  final bool cancelAtPeriodEnd;
  final Set<String> enabledFeatures;
  final Map<String, int> limits;

  const Subscription({
    required this.tier,
    this.status = SubscriptionStatus.trialing,
    this.currentPeriodEnd,
    this.trialEndsAt,
    this.gracePeriodEndsAt,
    this.cancelAtPeriodEnd = false,
    this.enabledFeatures = const <String>{},
    this.limits = const <String, int>{},
  });

  bool get isExpired {
    final now = DateTime.now();
    final end = status == SubscriptionStatus.trialing
        ? trialEndsAt ?? currentPeriodEnd
        : currentPeriodEnd;
    if (end == null || !end.isBefore(now)) return false;
    return gracePeriodEndsAt == null || gracePeriodEndsAt!.isBefore(now);
  }

  bool get isUsable =>
      !isExpired &&
      status != SubscriptionStatus.cancelled &&
      status != SubscriptionStatus.suspended;

  bool get requiresAttention =>
      status == SubscriptionStatus.pastDue ||
      status == SubscriptionStatus.suspended ||
      status == SubscriptionStatus.cancelled ||
      isExpired;

  String get planLabel => tier.label;

  int? limit(String key) => limits[key];

  factory Subscription.fromMap(Map<String, dynamic> map) {
    final legacyActive = map['active'];
    final inferredStatus = legacyActive == false
        ? SubscriptionStatus.suspended
        : subscriptionStatusFromString(map['status']?.toString());

    Set<String> parseFeatures(dynamic value) {
      if (value is! Iterable) return <String>{};
      return value
          .map((dynamic item) => item?.toString().trim() ?? '')
          .where((String item) => item.isNotEmpty)
          .toSet();
    }

    Map<String, int> parseLimits(dynamic value) {
      if (value is! Map) return <String, int>{};
      final result = <String, int>{};
      value.forEach((dynamic key, dynamic rawValue) {
        final parsed = rawValue is num
            ? rawValue.toInt()
            : int.tryParse(rawValue?.toString() ?? '');
        if (parsed != null) result[key.toString()] = parsed;
      });
      return result;
    }

    return Subscription(
      tier: subscriptionTierFromString(map['tier']?.toString()),
      status: inferredStatus,
      currentPeriodEnd: _dateFromValue(map['currentPeriodEnd']),
      trialEndsAt: _dateFromValue(map['trialEndsAt']),
      gracePeriodEndsAt: _dateFromValue(map['gracePeriodEndsAt']),
      cancelAtPeriodEnd: map['cancelAtPeriodEnd'] == true,
      enabledFeatures: parseFeatures(map['enabledFeatures']),
      limits: parseLimits(map['limits']),
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
        'gracePeriodEndsAt': gracePeriodEndsAt == null
            ? null
            : Timestamp.fromDate(gracePeriodEndsAt!),
        'cancelAtPeriodEnd': cancelAtPeriodEnd,
        'enabledFeatures': enabledFeatures.toList()..sort(),
        'limits': limits,
      };
}

DateTime? _dateFromValue(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
