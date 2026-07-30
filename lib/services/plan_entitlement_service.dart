import '../core/saas/saas_feature.dart';
import 'models/subscription.dart';
import 'models/tenant.dart';
import 'session_state.dart';

class SaasLimitKey {
  SaasLimitKey._();

  static const String students = 'students';
  static const String staffUsers = 'staffUsers';
  static const String campuses = 'campuses';
  static const String storageMb = 'storageMb';
  static const String smsPerMonth = 'smsPerMonth';
  static const String emailPerMonth = 'emailPerMonth';
  static const String aiActionsPerMonth = 'aiActionsPerMonth';
}

class PlanEntitlementService {
  final Tenant? tenant;

  PlanEntitlementService({Tenant? tenant})
      : tenant = tenant ?? SessionState.instance.tenant;

  Subscription? get subscription => tenant?.subscription;

  bool get isSubscriptionUsable => subscription?.isUsable == true;

  bool isFeatureEnabled(String feature) {
    final plan = subscription;
    if (plan == null || !plan.isUsable) return false;
    if (plan.enabledFeatures.isNotEmpty) {
      return plan.enabledFeatures.contains(feature);
    }
    return _defaultFeatures(plan.tier).contains(feature);
  }

  int limit(String key) {
    final plan = subscription;
    if (plan == null) return 0;
    final override = plan.limit(key);
    if (override != null) return override;
    return _defaultLimits(plan.tier)[key] ?? 0;
  }

  bool isWithinLimit(String key, int currentUsage, {int additional = 0}) {
    final maximum = limit(key);
    return maximum == 0 || currentUsage + additional <= maximum;
  }

  EntitlementDecision checkFeature(String feature) {
    if (subscription == null) {
      return const EntitlementDecision.denied(
        'No active subscription is configured for this school.',
      );
    }
    if (!subscription!.isUsable) {
      return const EntitlementDecision.denied(
        'The school subscription is inactive or has expired.',
      );
    }
    if (!isFeatureEnabled(feature)) {
      return EntitlementDecision.denied(
        '${SaasFeature.labelOf(feature)} is not included in the current plan.',
      );
    }
    return const EntitlementDecision.allowed();
  }

  bool canAccessModule(String moduleId) {
    final feature = _moduleFeatures[moduleId];
    return feature == null || isFeatureEnabled(feature);
  }

  static const Map<String, String> _moduleFeatures = <String, String>{
    'school-setup': SaasFeature.coreSchool,
    'admissions': SaasFeature.admissions,
    'students': SaasFeature.coreSchool,
    'parents': SaasFeature.coreSchool,
    'teachers': SaasFeature.coreSchool,
    'hr-payroll': SaasFeature.hrPayroll,
    'attendance': SaasFeature.attendance,
    'academics': SaasFeature.academics,
    'examinations': SaasFeature.examinations,
    'fees': SaasFeature.fees,
    'accounting': SaasFeature.accounting,
    'library': SaasFeature.library,
    'transport': SaasFeature.transport,
    'hostel': SaasFeature.hostel,
    'inventory': SaasFeature.inventory,
    'communication': SaasFeature.communication,
    'events': SaasFeature.coreSchool,
    'documents': SaasFeature.documents,
    'timetable': SaasFeature.academics,
    'reports': SaasFeature.reporting,
    'helpdesk': SaasFeature.helpdesk,
    'student-welfare': SaasFeature.welfare,
    'administration-saas': SaasFeature.advancedAudit,
    'ai-automation': SaasFeature.aiAutomation,
  };

  Set<String> _defaultFeatures(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.trial:
        return const <String>{
          SaasFeature.coreSchool,
          SaasFeature.admissions,
          SaasFeature.attendance,
          SaasFeature.academics,
          SaasFeature.examinations,
          SaasFeature.fees,
          SaasFeature.library,
          SaasFeature.communication,
          SaasFeature.documents,
          SaasFeature.helpdesk,
        };
      case SubscriptionTier.starter:
        return const <String>{
          SaasFeature.coreSchool,
          SaasFeature.admissions,
          SaasFeature.attendance,
          SaasFeature.academics,
          SaasFeature.examinations,
          SaasFeature.fees,
          SaasFeature.library,
          SaasFeature.transport,
          SaasFeature.communication,
          SaasFeature.documents,
          SaasFeature.helpdesk,
          SaasFeature.reporting,
        };
      case SubscriptionTier.pro:
        return const <String>{
          SaasFeature.coreSchool,
          SaasFeature.admissions,
          SaasFeature.attendance,
          SaasFeature.academics,
          SaasFeature.examinations,
          SaasFeature.fees,
          SaasFeature.accounting,
          SaasFeature.hrPayroll,
          SaasFeature.library,
          SaasFeature.transport,
          SaasFeature.hostel,
          SaasFeature.inventory,
          SaasFeature.communication,
          SaasFeature.documents,
          SaasFeature.helpdesk,
          SaasFeature.welfare,
          SaasFeature.reporting,
          SaasFeature.integrations,
          SaasFeature.multiCampus,
          SaasFeature.advancedAudit,
        };
      case SubscriptionTier.enterprise:
      case SubscriptionTier.custom:
        return SaasFeature.all.toSet();
    }
  }

  Map<String, int> _defaultLimits(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.trial:
        return const <String, int>{
          SaasLimitKey.students: 30,
          SaasLimitKey.staffUsers: 10,
          SaasLimitKey.campuses: 1,
          SaasLimitKey.storageMb: 512,
          SaasLimitKey.smsPerMonth: 100,
          SaasLimitKey.emailPerMonth: 500,
          SaasLimitKey.aiActionsPerMonth: 25,
        };
      case SubscriptionTier.starter:
        return const <String, int>{
          SaasLimitKey.students: 250,
          SaasLimitKey.staffUsers: 40,
          SaasLimitKey.campuses: 1,
          SaasLimitKey.storageMb: 5120,
          SaasLimitKey.smsPerMonth: 2000,
          SaasLimitKey.emailPerMonth: 10000,
          SaasLimitKey.aiActionsPerMonth: 250,
        };
      case SubscriptionTier.pro:
        return const <String, int>{
          SaasLimitKey.students: 2000,
          SaasLimitKey.staffUsers: 250,
          SaasLimitKey.campuses: 10,
          SaasLimitKey.storageMb: 51200,
          SaasLimitKey.smsPerMonth: 20000,
          SaasLimitKey.emailPerMonth: 100000,
          SaasLimitKey.aiActionsPerMonth: 5000,
        };
      case SubscriptionTier.enterprise:
      case SubscriptionTier.custom:
        return const <String, int>{
          SaasLimitKey.students: 0,
          SaasLimitKey.staffUsers: 0,
          SaasLimitKey.campuses: 0,
          SaasLimitKey.storageMb: 0,
          SaasLimitKey.smsPerMonth: 0,
          SaasLimitKey.emailPerMonth: 0,
          SaasLimitKey.aiActionsPerMonth: 0,
        };
    }
  }
}

class EntitlementDecision {
  final bool allowed;
  final String? reason;

  const EntitlementDecision.allowed()
      : allowed = true,
        reason = null;

  const EntitlementDecision.denied(this.reason) : allowed = false;
}
