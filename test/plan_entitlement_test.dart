import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/core/saas/saas_feature.dart';
import 'package:school_management/services/models/subscription.dart';
import 'package:school_management/services/models/tenant.dart';
import 'package:school_management/services/plan_entitlement_service.dart';

Tenant tenantWith(Subscription subscription) => Tenant(
      id: 'tenant-test',
      name: 'Test School',
      subscription: subscription,
    );

void main() {
  test('trial plan enables core workflows and applies limits', () {
    final service = PlanEntitlementService(
      tenant: tenantWith(
        const Subscription(
          tier: SubscriptionTier.trial,
          status: SubscriptionStatus.active,
        ),
      ),
    );

    expect(service.isFeatureEnabled(SaasFeature.attendance), isTrue);
    expect(service.isFeatureEnabled(SaasFeature.accounting), isFalse);
    expect(service.limit(SaasLimitKey.students), 30);
    expect(service.isWithinLimit(SaasLimitKey.students, 29, additional: 1), isTrue);
    expect(service.isWithinLimit(SaasLimitKey.students, 30, additional: 1), isFalse);
  });

  test('tenant feature and limit overrides replace plan defaults', () {
    final service = PlanEntitlementService(
      tenant: tenantWith(
        const Subscription(
          tier: SubscriptionTier.starter,
          status: SubscriptionStatus.active,
          enabledFeatures: <String>{SaasFeature.coreSchool, SaasFeature.hostel},
          limits: <String, int>{SaasLimitKey.students: 700},
        ),
      ),
    );

    expect(service.isFeatureEnabled(SaasFeature.hostel), isTrue);
    expect(service.isFeatureEnabled(SaasFeature.fees), isFalse);
    expect(service.limit(SaasLimitKey.students), 700);
  });

  test('suspended subscription denies every feature', () {
    final service = PlanEntitlementService(
      tenant: tenantWith(
        const Subscription(
          tier: SubscriptionTier.enterprise,
          status: SubscriptionStatus.suspended,
        ),
      ),
    );

    expect(service.isSubscriptionUsable, isFalse);
    expect(service.isFeatureEnabled(SaasFeature.coreSchool), isFalse);
    expect(service.checkFeature(SaasFeature.coreSchool).allowed, isFalse);
  });
}
