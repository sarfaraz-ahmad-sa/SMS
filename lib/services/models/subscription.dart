/// Subscription tiers for the SaaS billing model.
///
/// Plain enum + extension (no "enhanced enum" members) for maximum Dart
/// version compatibility.
enum SubscriptionTier {
  trial,
  starter,
  pro,
  enterprise,
}

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

  /// Stable string used for storage/serialization.
  String get value {
    switch (this) {
      case SubscriptionTier.trial:
        return 'trial';
      case SubscriptionTier.starter:
        return 'starter';
      case SubscriptionTier.pro:
        return 'pro';
      case SubscriptionTier.enterprise:
        return 'enterprise';
    }
  }

  /// Seat / student caps per plan (0 = unlimited). Tune to your pricing.
  int get maxStudents {
    switch (this) {
      case SubscriptionTier.trial:
        return 30;
      case SubscriptionTier.starter:
        return 250;
      case SubscriptionTier.pro:
        return 2000;
      case SubscriptionTier.enterprise:
        return 0; // unlimited
    }
  }
}

SubscriptionTier subscriptionTierFromString(String? value) {
  switch (value) {
    case 'starter':
      return SubscriptionTier.starter;
    case 'pro':
      return SubscriptionTier.pro;
    case 'enterprise':
      return SubscriptionTier.enterprise;
    case 'trial':
    default:
      return SubscriptionTier.trial;
  }
}

/// The subscription state attached to a tenant.
class Subscription {
  final SubscriptionTier tier;
  final DateTime? currentPeriodEnd;
  final bool active;

  const Subscription({
    required this.tier,
    this.currentPeriodEnd,
    this.active = true,
  });

  bool get isExpired =>
      currentPeriodEnd != null && currentPeriodEnd!.isBefore(DateTime.now());

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      tier: subscriptionTierFromString(map['tier'] as String?),
      active: (map['active'] as bool?) ?? true,
      currentPeriodEnd: map['currentPeriodEnd'] != null
          ? DateTime.tryParse(map['currentPeriodEnd'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'tier': tier.value,
        'active': active,
        'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
      };
}
