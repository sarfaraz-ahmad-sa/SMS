import 'package:flutter/material.dart';

import '../../Widgets/PermissionGate.dart';
import '../../Widgets/saas_scaffold.dart';
import '../../core/erp/erp_catalog.dart';
import '../../core/erp/erp_module.dart';
import '../../core/saas/saas_feature.dart';
import '../../services/models/app_permission.dart';
import '../../services/models/saas_usage.dart';
import '../../services/plan_entitlement_service.dart';
import '../../services/saas_admin_service.dart';
import '../../services/saas_usage_service.dart';
import '../../services/session_state.dart';
import '../../theme/app_theme.dart';
import '../Enterprise/ErpEntityListScreen.dart';
import '../Enterprise/ErpModuleScreen.dart';

class SaasControlCenterScreen extends StatelessWidget {
  const SaasControlCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SessionState.instance;
    final tenant = state.tenant;
    final entitlement = PlanEntitlementService();
    final canView = state.hasAnyPermission(const <String>[
      AppPermission.saasAdminView,
      AppPermission.subscriptionManage,
      AppPermission.tenantManage,
    ]);
    if (!canView) {
      return const SaasScaffold(
        title: 'SaaS Control Center',
        activeRoute: '/saas',
        body: PermissionDeniedView(),
      );
    }

    return SaasScaffold(
      title: 'SaaS Control Center',
      activeRoute: '/saas',
      actions: <Widget>[
        IconButton(
          tooltip: 'Refresh usage',
          onPressed: () => _refreshUsage(context),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: StreamBuilder<SaasUsage>(
            stream: SaasUsageService().watchCurrent(),
            builder: (
              BuildContext context,
              AsyncSnapshot<SaasUsage> snapshot,
            ) {
              final usage = snapshot.data ?? const SaasUsage();
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: <Widget>[
                  _PlanHero(
                    schoolName: tenant?.name ?? 'School',
                    planName: tenant?.subscription.planLabel ?? 'No plan',
                    status: tenant?.subscription.status.name ?? 'unknown',
                    usable: tenant?.subscription.isUsable == true,
                    periodEnd: tenant?.subscription.currentPeriodEnd,
                    onOnboarding: () =>
                        Navigator.pushNamed(context, '/onboarding'),
                  ),
                  const SizedBox(height: 20),
                  const _SectionHeader(
                    title: 'Usage and plan limits',
                    subtitle:
                        'Live tenant consumption against the current subscription.',
                  ),
                  const SizedBox(height: 12),
                  _UsageGrid(usage: usage, entitlement: entitlement),
                  const SizedBox(height: 24),
                  const _SectionHeader(
                    title: 'Feature entitlements',
                    subtitle:
                        'Modules are enabled by plan and can be overridden per tenant.',
                  ),
                  const SizedBox(height: 12),
                  _FeatureGrid(entitlement: entitlement),
                  const SizedBox(height: 24),
                  const _SectionHeader(
                    title: 'SaaS operations',
                    subtitle:
                        'Trusted administration, compliance and operational controls.',
                  ),
                  const SizedBox(height: 12),
                  _OperationsGrid(
                    canManage: state.hasAnyPermission(const <String>[
                      AppPermission.saasAdminManage,
                      AppPermission.subscriptionManage,
                      AppPermission.usersManage,
                      AppPermission.auditView,
                    ]),
                  ),
                  const SizedBox(height: 20),
                  _ProductionBoundary(
                    hasIntegrations: entitlement.isFeatureEnabled(
                      SaasFeature.integrations,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _refreshUsage(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SaasAdminService().refreshUsage();
      messenger.showSnackBar(
        const SnackBar(content: Text('Subscription usage refreshed.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not refresh usage: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

class _PlanHero extends StatelessWidget {
  final String schoolName;
  final String planName;
  final String status;
  final bool usable;
  final DateTime? periodEnd;
  final VoidCallback onOnboarding;

  const _PlanHero({
    required this.schoolName,
    required this.planName,
    required this.status,
    required this.usable,
    required this.periodEnd,
    required this.onOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    final tenant = SessionState.instance.tenant;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.tenantGradient(tenant),
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.tenantPrimary(tenant).withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final compact = constraints.maxWidth < 700;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'SCHOOL SAAS WORKSPACE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                schoolName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _HeroPill(label: planName),
                  _HeroPill(label: status.toUpperCase()),
                  _HeroPill(
                    label: usable ? 'SERVICE ACTIVE' : 'ACTION REQUIRED',
                    icon: usable ? Icons.check_circle : Icons.warning_amber,
                  ),
                ],
              ),
              if (periodEnd != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  'Current period ends ${_formatDate(periodEnd!)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ],
          );

          final action = FilledButton.icon(
            onPressed: onOnboarding,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.navigation,
            ),
            icon: const Icon(Icons.rocket_launch_outlined),
            label: const Text('Open onboarding'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                details,
                const SizedBox(height: 20),
                action,
              ],
            );
          }
          return Row(
            children: <Widget>[
              Expanded(child: details),
              action,
            ],
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _HeroPill({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageGrid extends StatelessWidget {
  final SaasUsage usage;
  final PlanEntitlementService entitlement;

  const _UsageGrid({required this.usage, required this.entitlement});

  @override
  Widget build(BuildContext context) {
    final items = <_UsageItem>[
      _UsageItem(
        label: 'Students',
        current: usage.students,
        limit: entitlement.limit(SaasLimitKey.students),
        icon: Icons.school_outlined,
      ),
      _UsageItem(
        label: 'Staff users',
        current: usage.staffUsers,
        limit: entitlement.limit(SaasLimitKey.staffUsers),
        icon: Icons.groups_outlined,
      ),
      _UsageItem(
        label: 'Campuses',
        current: usage.campuses,
        limit: entitlement.limit(SaasLimitKey.campuses),
        icon: Icons.location_city_outlined,
      ),
      _UsageItem(
        label: 'Storage (MB)',
        current: usage.storageMb,
        limit: entitlement.limit(SaasLimitKey.storageMb),
        icon: Icons.cloud_outlined,
      ),
      _UsageItem(
        label: 'SMS this month',
        current: usage.smsThisMonth,
        limit: entitlement.limit(SaasLimitKey.smsPerMonth),
        icon: Icons.sms_outlined,
      ),
      _UsageItem(
        label: 'Email this month',
        current: usage.emailThisMonth,
        limit: entitlement.limit(SaasLimitKey.emailPerMonth),
        icon: Icons.mail_outline,
      ),
      _UsageItem(
        label: 'AI actions',
        current: usage.aiActionsThisMonth,
        limit: entitlement.limit(SaasLimitKey.aiActionsPerMonth),
        icon: Icons.auto_awesome_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 720
                ? 3
                : constraints.maxWidth >= 460
                    ? 2
                    : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 2.9 : 1.65,
          ),
          itemBuilder: (BuildContext context, int index) =>
              _UsageCard(item: items[index]),
        );
      },
    );
  }
}

class _UsageItem {
  final String label;
  final int current;
  final int limit;
  final IconData icon;

  const _UsageItem({
    required this.label,
    required this.current,
    required this.limit,
    required this.icon,
  });
}

class _UsageCard extends StatelessWidget {
  final _UsageItem item;

  const _UsageCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final unlimited = item.limit == 0;
    final ratio = unlimited || item.limit <= 0
        ? 0.0
        : (item.current / item.limit).clamp(0.0, 1.0).toDouble();
    final warning = !unlimited && ratio >= 0.8;
    final color = warning ? AppColors.warning : Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: color),
                ),
                const Spacer(),
                Text(
                  unlimited ? 'Unlimited' : '${item.current} / ${item.limit}',
                  style: TextStyle(
                    color: warning ? AppColors.warning : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${item.current}',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            Text(
              item.label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!unlimited) ...<Widget>[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: ratio,
                minHeight: 7,
                borderRadius: BorderRadius.circular(99),
                color: color,
                backgroundColor: color.withOpacity(0.1),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final PlanEntitlementService entitlement;

  const _FeatureGrid({required this.entitlement});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: SaasFeature.all.map((String feature) {
        final enabled = entitlement.isFeatureEnabled(feature);
        return Container(
          width: 230,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.success.withOpacity(0.07)
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled
                  ? AppColors.success.withOpacity(0.25)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                enabled ? Icons.check_circle : Icons.lock_outline,
                size: 18,
                color: enabled ? AppColors.success : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  SaasFeature.labelOf(feature),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _OperationsGrid extends StatelessWidget {
  final bool canManage;

  const _OperationsGrid({required this.canManage});

  @override
  Widget build(BuildContext context) {
    final adminModule = ErpCatalog.byId('administration-saas');
    final items = <_OperationItem>[
      const _OperationItem(
        title: 'Tenant onboarding',
        subtitle: 'Complete launch checklist and master setup.',
        icon: Icons.rocket_launch_outlined,
        route: '/onboarding',
      ),
      const _OperationItem(
        title: 'Approval inbox',
        subtitle: 'Review finance, payroll and academic decisions.',
        icon: Icons.approval_outlined,
        route: '/approvals',
      ),
      const _OperationItem(
        title: 'Subscription billing',
        subtitle: 'Plans, limits, periods and payment status.',
        icon: Icons.workspace_premium_outlined,
        entityCollection: 'subscription_billing',
      ),
      const _OperationItem(
        title: 'Users and access',
        subtitle: 'Accounts, roles, campus scope and status.',
        icon: Icons.manage_accounts_outlined,
        entityCollection: 'user_access',
      ),
      const _OperationItem(
        title: 'Integrations',
        subtitle: 'Payment, SMS, email, WhatsApp and SSO.',
        icon: Icons.hub_outlined,
        entityCollection: 'integration_connections',
      ),
      const _OperationItem(
        title: 'Audit and compliance',
        subtitle: 'Control reviews, findings and remediation.',
        icon: Icons.fact_check_outlined,
        entityCollection: 'audit_reviews',
      ),
      const _OperationItem(
        title: 'Backup and restore',
        subtitle: 'Recovery jobs, retention and restore tests.',
        icon: Icons.settings_backup_restore_outlined,
        entityCollection: 'backup_jobs',
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 3.25 : 2.1,
          ),
          itemBuilder: (BuildContext context, int index) {
            final item = items[index];
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: !canManage
                    ? null
                    : () {
                        if (item.route != null) {
                          Navigator.pushNamed(context, item.route!);
                          return;
                        }
                        if (adminModule == null) return;
                        _openAdminWorkflow(
                          context,
                          adminModule,
                          item.entityCollection,
                        );
                      },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        child: Icon(
                          item.icon,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.title,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        canManage ? Icons.chevron_right : Icons.lock_outline,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openAdminWorkflow(
    BuildContext context,
    ErpModule module,
    String? collection,
  ) {
    if (collection == null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ErpModuleScreen(module: module),
        ),
      );
      return;
    }
    final entity = ErpCatalog.entityByCollection(collection);
    if (entity == null) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ErpEntityListScreen(entity: entity),
      ),
    );
  }
}

class _OperationItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? route;
  final String? entityCollection;

  const _OperationItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.route,
    this.entityCollection,
  });
}

class _ProductionBoundary extends StatelessWidget {
  final bool hasIntegrations;

  const _ProductionBoundary({required this.hasIntegrations});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.verified_user_outlined, color: AppColors.info),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Trusted backend boundary',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasIntegrations
                        ? 'Integration entitlement is active. Payment callbacks, financial posting, payroll approval, final result publication and immutable audit events must still execute through Cloud Functions or the trusted API.'
                        : 'External integrations are not enabled in the current plan. High-risk operations remain read-only until a trusted provider and backend workflow are configured.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
