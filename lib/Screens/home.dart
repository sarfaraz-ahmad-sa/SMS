import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Widgets/FeatureCard.dart';
import '../Widgets/saas_scaffold.dart';
import '../core/erp/erp_access_policy.dart';
import '../core/erp/erp_catalog.dart';
import '../core/erp/tenant_erp_service.dart';
import '../services/models/app_permission.dart';
import '../services/models/user_role.dart';
import '../services/models/tenant.dart';
import '../services/plan_entitlement_service.dart';
import '../services/Auth_services.dart';
import '../services/session_state.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_dashboard_summary_service.dart';
import '../config/backend_config.dart';
import '../theme/app_theme.dart';
import 'Enterprise/ErpEntityListScreen.dart';
import 'Enterprise/ErpModuleScreen.dart';
import 'Profile.dart';
import 'Saas/saas_control_center_screen.dart';
import 'Saas/tenant_onboarding_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<_DashboardSummaryData> _summaryFuture;
  late final StreamSubscription<dynamic> _authSubscription;
  String? _dashboardContextKey;

  @override
  void initState() {
    super.initState();
    _dashboardContextKey = _currentDashboardContextKey();
    _refreshDashboard();
    SessionState.instance.addListener(_handleSessionChange);
    _authSubscription = BackendConfig.isSupabasePrimary
        ? SupabaseAuthService().authStateChanges.listen(
              (dynamic state) => _handleAuthSession(state.session != null),
            )
        : AuthService().authStateChanges.listen(
              (User? user) => _handleAuthSession(user != null),
            );
  }

  @override
  void dispose() {
    SessionState.instance.removeListener(_handleSessionChange);
    _authSubscription.cancel();
    super.dispose();
  }

  void _handleAuthSession(bool isSignedIn) {
    if (isSignedIn || !mounted) return;
    final sessionUser = SessionState.instance.user;
    if (sessionUser?.uid == 'debug-school-owner') return;

    SessionState.instance.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (Route<dynamic> route) => false,
      );
    });
  }

  String _currentDashboardContextKey() {
    final state = SessionState.instance;
    final roles = state.user?.roles.map((role) => role.name).join(',') ?? '';
    return <String?>[
      state.tenant?.id,
      state.user?.uid,
      roles,
      state.activeCampusId,
      state.activeAcademicYearId,
    ].join('|');
  }

  void _handleSessionChange() {
    final nextKey = _currentDashboardContextKey();
    if (!mounted || nextKey == _dashboardContextKey) return;
    setState(() {
      _dashboardContextKey = nextKey;
      _refreshDashboard();
    });
  }

  void _refreshDashboard() {
    _summaryFuture = _loadSummary();
  }

  Future<_DashboardSummaryData> _loadSummary() async {
    final state = SessionState.instance;
    final user = state.user;
    if (user == null || state.tenant == null) {
      return const _DashboardSummaryData(
        students: 0,
        employees: 0,
        attendanceSessions: 0,
        feeInvoices: 0,
        payments: 0,
        exams: 0,
        expenses: 0,
        totalAdmissions: 0,
        pendingAdmissions: 0,
        approvedAdmissions: 0,
        rejectedAdmissions: 0,
        canViewStudents: false,
        canViewAdmissions: false,
        canViewEmployees: false,
        canViewAttendance: false,
        canViewFees: false,
        canViewExams: false,
        canViewAccounting: false,
      );
    }
    final service = TenantErpService();
    final usesSupabase = BackendConfig.isSupabasePrimary;
    final entitlement = PlanEntitlementService(tenant: state.tenant);
    final campusId = state.activeCampusId;
    final academicYearId = state.activeAcademicYearId;
    final dashboardSummary =
        usesSupabase && campusId != null && academicYearId != null
            ? await SupabaseDashboardSummaryService().load(
                tenantId: state.tenant!.id,
                campusId: campusId,
                academicYearId: academicYearId,
              )
            : await service.loadDashboardSummary();
    final summaryCounts = dashboardSummary['counts'];
    final summaryStatuses = dashboardSummary['statusCounts'];

    var students = 0;
    var totalAdmissions = 0;
    var pendingAdmissions = 0;
    var approvedAdmissions = 0;
    var rejectedAdmissions = 0;

    int summaryCount(String collection) {
      if (summaryCounts is! Map) return 0;
      return (summaryCounts[collection] as num?)?.toInt() ?? 0;
    }

    final studentEntity = ErpCatalog.entityByCollection('students');
    final admissionEntity = ErpCatalog.entityByCollection(
      'admission_applications',
    );

    bool canViewCollection(String collection, String moduleId) {
      final entity = ErpCatalog.entityByCollection(collection);
      return entity != null &&
          entitlement.canAccessModule(moduleId) &&
          ErpAccessPolicy.canViewEntity(entity, user, state.hasPermission);
    }

    final canViewStudents = canViewCollection('students', 'students');
    final canViewAdmissions = admissionEntity != null &&
        entitlement.canAccessModule('admissions') &&
        ErpAccessPolicy.canViewEntity(
          admissionEntity,
          user,
          state.hasPermission,
        );
    final canViewEmployees = canViewCollection('employees', 'hr-payroll');
    final canViewAttendance =
        canViewCollection('attendance_sessions', 'attendance');
    final canViewFees = canViewCollection('fee_invoices', 'fees');
    final canViewExams = canViewCollection('exams', 'examinations');
    final canViewAccounting = canViewCollection('expenses', 'accounting');

    if (canViewStudents) {
      final personalScope = user.role.isLearner || user.role.isGuardian;
      final summarized = summaryCounts is Map
          ? (summaryCounts['students'] as num?)?.toInt()
          : null;
      students = personalScope
          ? await service.countVisible(studentEntity!)
          : summarized ?? await service.count('students');
    }

    if (canViewAdmissions) {
      final admissionCounts = summaryStatuses is Map
          ? summaryStatuses['admission_applications']
          : null;
      int? summarizedStatus(String status) {
        if (admissionCounts is! Map) return null;
        final candidates = <String>{
          status,
          status.toLowerCase(),
          Uri.encodeComponent(status),
          Uri.encodeComponent(status).toLowerCase(),
        };
        for (final key in candidates) {
          final value = admissionCounts[key];
          if (value is num) return value.toInt();
        }
        return null;
      }

      final summarizedTotal = summaryCounts is Map
          ? (summaryCounts['admission_applications'] as num?)?.toInt()
          : null;
      totalAdmissions =
          summarizedTotal ?? await service.count('admission_applications');

      final summarizedCounts = <int?>[
        summarizedStatus('Draft'),
        summarizedStatus('Submitted'),
        summarizedStatus('Under Review'),
        summarizedStatus('Assessment'),
        summarizedStatus('Waitlisted'),
        summarizedStatus('Approved'),
        summarizedStatus('Enrolled'),
        summarizedStatus('Rejected'),
      ];
      final counts = usesSupabase
          ? summarizedCounts.map((int? value) => value ?? 0).toList()
          : summarizedCounts.every((int? value) => value != null)
              ? summarizedCounts.cast<int>()
              : await Future.wait<int>(<Future<int>>[
                  service.countWhere(
                      'admission_applications', 'status', 'Draft'),
                  service.countWhere(
                    'admission_applications',
                    'status',
                    'Submitted',
                  ),
                  service.countWhere(
                    'admission_applications',
                    'status',
                    'Under Review',
                  ),
                  service.countWhere(
                    'admission_applications',
                    'status',
                    'Assessment',
                  ),
                  service.countWhere(
                    'admission_applications',
                    'status',
                    'Waitlisted',
                  ),
                  service.countWhere(
                    'admission_applications',
                    'status',
                    'Approved',
                  ),
                  service.countWhere(
                    'admission_applications',
                    'status',
                    'Enrolled',
                  ),
                  service.countWhere(
                    'admission_applications',
                    'status',
                    'Rejected',
                  ),
                ]);

      pendingAdmissions =
          counts[0] + counts[1] + counts[2] + counts[3] + counts[4];
      approvedAdmissions = counts[5] + counts[6];
      rejectedAdmissions = counts[7];
    }

    return _DashboardSummaryData(
      students: students,
      employees: summaryCount('employees'),
      attendanceSessions: summaryCount('attendance_sessions'),
      feeInvoices: summaryCount('fee_invoices'),
      payments: summaryCount('payments'),
      exams: summaryCount('exams'),
      expenses: summaryCount('expenses'),
      totalAdmissions: totalAdmissions,
      pendingAdmissions: pendingAdmissions,
      approvedAdmissions: approvedAdmissions,
      rejectedAdmissions: rejectedAdmissions,
      canViewStudents: canViewStudents,
      canViewAdmissions: canViewAdmissions,
      canViewEmployees: canViewEmployees,
      canViewAttendance: canViewAttendance,
      canViewFees: canViewFees,
      canViewExams: canViewExams,
      canViewAccounting: canViewAccounting,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionState.instance,
      builder: (BuildContext context, Widget? child) {
        final state = SessionState.instance;
        final user = state.user;
        final tenant = state.tenant;
        final compact = MediaQuery.sizeOf(context).width < 600;

        if (user == null || tenant == null) {
          return const Scaffold(
            body: Center(child: Text('No active school session.')),
          );
        }

        return SaasScaffold(
          title: 'Dashboard',
          activeRoute: '/home',
          body: RefreshIndicator(
            onRefresh: () async {
              setState(_refreshDashboard);
              await _summaryFuture;
            },
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    compact ? AppSpacing.page : 20,
                    compact ? 14 : 20,
                    compact ? AppSpacing.page : 20,
                    40,
                  ),
                  children: <Widget>[
                    _GreetingCard(
                      name: user.displayName?.trim().isNotEmpty == true
                          ? user.displayName!.trim()
                          : 'User',
                      roleLabel: user.roleLabel,
                      tenantName: tenant.name,
                      academicYearId: state.activeAcademicYearId,
                      demoMode: TenantErpService().isDemoMode,
                      tenant: tenant,
                    ),
                    const SizedBox(height: 14),
                    _SubscriptionNotice(state: state),
                    const SizedBox(height: 18),
                    _DashboardSummary(
                      future: _summaryFuture,
                      onRetry: () => setState(_refreshDashboard),
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle(
                      title: 'Quick Access',
                      subtitle:
                          'Role-based shortcuts for daily school operations',
                    ),
                    const SizedBox(height: 12),
                    _OldQuickAccess(state: state),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SubscriptionNotice extends StatelessWidget {
  final SessionState state;

  const _SubscriptionNotice({required this.state});

  @override
  Widget build(BuildContext context) {
    final tenant = state.tenant;
    if (tenant == null) return const SizedBox.shrink();
    final subscription = tenant.subscription;
    final canOpenSaas = state.hasAnyPermission(const <String>[
      AppPermission.saasAdminView,
      AppPermission.subscriptionManage,
      AppPermission.tenantManage,
    ]);
    if (!canOpenSaas &&
        (state.user?.role.isLearner == true ||
            state.user?.role.isGuardian == true)) {
      return const SizedBox.shrink();
    }
    final color =
        subscription.requiresAttention ? AppColors.warning : AppColors.success;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                subscription.requiresAttention
                    ? Icons.warning_amber_rounded
                    : Icons.verified_outlined,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${subscription.planLabel} plan • ${subscription.status.name}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subscription.requiresAttention
                        ? 'Subscription needs attention. Some SaaS features may be restricted.'
                        : 'Tenant services and plan entitlements are active.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (canOpenSaas)
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/saas'),
                child: const Text('Manage'),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSummaryData {
  final int students;
  final int employees;
  final int attendanceSessions;
  final int feeInvoices;
  final int payments;
  final int exams;
  final int expenses;
  final int totalAdmissions;
  final int pendingAdmissions;
  final int approvedAdmissions;
  final int rejectedAdmissions;
  final bool canViewStudents;
  final bool canViewAdmissions;
  final bool canViewEmployees;
  final bool canViewAttendance;
  final bool canViewFees;
  final bool canViewExams;
  final bool canViewAccounting;

  const _DashboardSummaryData({
    required this.students,
    required this.employees,
    required this.attendanceSessions,
    required this.feeInvoices,
    required this.payments,
    required this.exams,
    required this.expenses,
    required this.totalAdmissions,
    required this.pendingAdmissions,
    required this.approvedAdmissions,
    required this.rejectedAdmissions,
    required this.canViewStudents,
    required this.canViewAdmissions,
    required this.canViewEmployees,
    required this.canViewAttendance,
    required this.canViewFees,
    required this.canViewExams,
    required this.canViewAccounting,
  });
}

class _DashboardSummary extends StatelessWidget {
  final Future<_DashboardSummaryData> future;
  final VoidCallback onRetry;

  const _DashboardSummary({required this.future, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardSummaryData>(
      future: future,
      builder: (
        BuildContext context,
        AsyncSnapshot<_DashboardSummaryData> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _DashboardLoading();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(
                Icons.cloud_off_outlined,
                color: AppColors.danger,
              ),
              title: const Text('Dashboard summary unavailable'),
              subtitle: Text(snapshot.error?.toString() ?? 'Try again.'),
              trailing: IconButton(
                tooltip: 'Retry',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final metrics = <_DashboardMetric>[
          if (data.canViewStudents)
            _DashboardMetric(
              label: 'Students',
              supporting: 'Active enrolment',
              value: data.students,
              icon: Icons.groups_rounded,
              color: AppColors.primary,
              collection: 'students',
            ),
          if (data.canViewEmployees)
            _DashboardMetric(
              label: 'Employees',
              supporting: 'Faculty and staff',
              value: data.employees,
              icon: Icons.badge_rounded,
              color: const Color(0xFF7B1FA2),
              collection: 'employees',
            ),
          if (data.canViewAttendance)
            _DashboardMetric(
              label: 'Attendance',
              supporting: 'Recorded sessions',
              value: data.attendanceSessions,
              icon: Icons.fact_check_rounded,
              color: AppColors.success,
              collection: 'attendance_sessions',
            ),
          if (data.canViewFees)
            _DashboardMetric(
              label: 'Fee invoices',
              supporting: '${data.payments} payments',
              value: data.feeInvoices,
              icon: Icons.receipt_long_rounded,
              color: AppColors.secondary,
              collection: 'fee_invoices',
            ),
          if (data.canViewExams)
            _DashboardMetric(
              label: 'Exams',
              supporting: 'Current academic year',
              value: data.exams,
              icon: Icons.assignment_rounded,
              color: const Color(0xFFB06000),
              collection: 'exams',
            ),
          if (data.canViewAccounting)
            _DashboardMetric(
              label: 'Expenses',
              supporting: 'Recorded entries',
              value: data.expenses,
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.danger,
              collection: 'expenses',
            ),
        ];

        if (metrics.isEmpty && !data.canViewAdmissions) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (metrics.isNotEmpty) ...<Widget>[
                  const _SectionTitle(
                    title: 'Overview',
                    subtitle: 'Live summary for the selected school context',
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: constraints.maxWidth >= 1000
                          ? 4
                          : constraints.maxWidth >= 620
                              ? 3
                              : 2,
                      mainAxisExtent: constraints.maxWidth < 430 ? 142 : 150,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: metrics.length,
                    itemBuilder: (BuildContext context, int index) =>
                        _DashboardMetricCard(metric: metrics[index]),
                  ),
                ],
                if (metrics.isNotEmpty && data.canViewAdmissions)
                  const SizedBox(height: 16),
                if (data.canViewAdmissions) _AdmissionSummaryCard(data: data),
              ],
            );
          },
        );
      },
    );
  }
}

class _DashboardMetric {
  final String label;
  final String supporting;
  final int value;
  final IconData icon;
  final Color color;
  final String collection;

  const _DashboardMetric({
    required this.label,
    required this.supporting,
    required this.value,
    required this.icon,
    required this.color,
    required this.collection,
  });
}

class _DashboardMetricCard extends StatelessWidget {
  final _DashboardMetric metric;

  const _DashboardMetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.72)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final entity = ErpCatalog.entityByCollection(metric.collection);
          if (entity == null) return;
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ErpEntityListScreen(entity: entity),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: metric.color.withOpacity(0.11),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(metric.icon, color: metric.color, size: 21),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${metric.value}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
              ),
              Text(
                metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                metric.supporting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: List<Widget>.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
      ),
    );
  }
}

class _AdmissionSummaryCard extends StatelessWidget {
  final _DashboardSummaryData data;

  const _AdmissionSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final module = ErpCatalog.byId('admissions');
          if (module == null) return;
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ErpModuleScreen(module: module),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.how_to_reg_outlined,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Admission Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Current application pipeline',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${data.totalAdmissions}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final items = <Widget>[
                    _AdmissionStatus(
                      label: 'Pending',
                      value: data.pendingAdmissions,
                      color: AppColors.warning,
                    ),
                    _AdmissionStatus(
                      label: 'Approved',
                      value: data.approvedAdmissions,
                      color: AppColors.success,
                    ),
                    _AdmissionStatus(
                      label: 'Rejected',
                      value: data.rejectedAdmissions,
                      color: AppColors.danger,
                    ),
                  ];

                  if (constraints.maxWidth < 410) {
                    return Wrap(spacing: 8, runSpacing: 8, children: items);
                  }

                  return Row(
                    children: <Widget>[
                      for (var index = 0; index < items.length; index++) ...[
                        Expanded(child: items[index]),
                        if (index != items.length - 1) const SizedBox(width: 8),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdmissionStatus extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _AdmissionStatus({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OldQuickAccess extends StatelessWidget {
  final SessionState state;

  const _OldQuickAccess({required this.state});

  @override
  Widget build(BuildContext context) {
    final items = <_QuickAccessItem>[
      _QuickAccessItem(
        title: 'SaaS Center',
        icon: Icons.grid_view_rounded,
        color: AppColors.primary,
        moduleId: 'administration-saas',
        permissions: const <String>[
          AppPermission.saasAdminView,
          AppPermission.subscriptionManage,
          AppPermission.tenantManage,
        ],
        builder: (_) => const SaasControlCenterScreen(),
      ),
      _QuickAccessItem(
        title: 'Onboarding',
        icon: Icons.rocket_launch_outlined,
        color: AppColors.accent,
        moduleId: 'school-setup',
        permissions: const <String>[
          AppPermission.schoolSetupView,
          AppPermission.schoolSetupManage,
          AppPermission.saasAdminView,
        ],
        builder: (_) => const TenantOnboardingScreen(),
      ),
      _QuickAccessItem(
        title: 'Profile',
        icon: Icons.person_outline,
        color: AppColors.primary,
        permissions: const <String>[AppPermission.profileView],
        builder: (_) => const ProfileScreen(),
      ),
      _QuickAccessItem(
        title: 'Attendance',
        icon: Icons.fact_check_outlined,
        color: AppColors.success,
        moduleId: 'attendance',
        permissions: const <String>[AppPermission.attendanceView],
        builder: (_) => ErpEntityListScreen(
          entity: ErpCatalog.entityByCollection('student_attendance')!,
        ),
      ),
      _QuickAccessItem(
        title: 'Exam Results',
        icon: Icons.assignment_outlined,
        color: AppColors.secondary,
        moduleId: 'examinations',
        permissions: const <String>[AppPermission.examsView],
        builder: (_) => ErpEntityListScreen(
          entity: ErpCatalog.entityByCollection('exam_results')!,
        ),
      ),
      _QuickAccessItem(
        title: 'Time Table',
        icon: Icons.calendar_month_outlined,
        color: AppColors.warning,
        moduleId: 'timetable',
        permissions: const <String>[AppPermission.timetableView],
        builder: (_) => ErpEntityListScreen(
          entity: ErpCatalog.entityByCollection('timetable_entries')!,
        ),
      ),
      _QuickAccessItem(
        title: 'Library',
        icon: Icons.menu_book_outlined,
        color: const Color(0xFF8B5CF6),
        moduleId: 'library',
        permissions: const <String>[AppPermission.libraryView],
        builder: (_) => ErpModuleScreen(module: ErpCatalog.byId('library')!),
      ),
      _QuickAccessItem(
        title: 'Fees',
        icon: Icons.payments_outlined,
        color: const Color(0xFF0EA5E9),
        moduleId: 'fees',
        permissions: const <String>[AppPermission.feesView],
        builder: (_) => ErpEntityListScreen(
          entity: ErpCatalog.entityByCollection('fee_invoices')!,
        ),
      ),
      _QuickAccessItem(
        title: 'Transport',
        icon: Icons.directions_bus_outlined,
        color: const Color(0xFFF97316),
        moduleId: 'transport',
        permissions: const <String>[AppPermission.transportView],
        builder: (_) => ErpEntityListScreen(
          entity: ErpCatalog.entityByCollection('transport_assignments')!,
        ),
      ),
      _QuickAccessItem(
        title: 'Apply Leave',
        icon: Icons.event_busy_outlined,
        color: AppColors.danger,
        moduleId:
            state.user?.role.isLearner == true ? 'attendance' : 'hr-payroll',
        permissions: const <String>[
          AppPermission.leaveApply,
          AppPermission.leaveView,
        ],
        builder: (_) => ErpEntityListScreen(
          entity: ErpCatalog.entityByCollection(
            state.user?.role.isLearner == true
                ? 'student_leave_requests'
                : 'leave_requests',
          )!,
        ),
      ),
      _QuickAccessItem(
        title: 'Activities',
        icon: Icons.emoji_events_outlined,
        color: const Color(0xFFEC4899),
        moduleId: 'events',
        permissions: const <String>[AppPermission.activitiesView],
        builder: (_) => ErpModuleScreen(module: ErpCatalog.byId('events')!),
      ),
    ];
    final entitlement = PlanEntitlementService(tenant: state.tenant);
    final visibleItems = items.where((_QuickAccessItem item) {
      final moduleAllowed =
          item.moduleId == null || entitlement.canAccessModule(item.moduleId!);
      return moduleAllowed && state.hasAnyPermission(item.permissions);
    }).toList(growable: false);

    if (visibleItems.isEmpty) {
      return const Card(
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text('No quick access options are assigned to your role.'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final scaledLabelHeight =
            MediaQuery.textScalerOf(context).scale(14.5) - 14.5;
        final maxTileWidth = constraints.maxWidth < 420 ? 178.0 : 220.0;
        final baseTileHeight = constraints.maxWidth < 420 ? 136.0 : 150.0;
        final tileHeight = baseTileHeight + scaledLabelHeight.clamp(0.0, 32.0);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxTileWidth,
            mainAxisExtent: tileHeight,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: visibleItems.length,
          itemBuilder: (BuildContext context, int index) {
            final item = visibleItems[index];
            return FeatureCard(
              title: item.title,
              icon: item.icon,
              color: item.color,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: item.builder),
              ),
            );
          },
        );
      },
    );
  }
}

class _QuickAccessItem {
  final String title;
  final IconData icon;
  final Color color;
  final String? moduleId;
  final List<String> permissions;
  final WidgetBuilder builder;

  const _QuickAccessItem({
    required this.title,
    required this.icon,
    required this.color,
    this.moduleId,
    required this.permissions,
    required this.builder,
  });
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final String name;
  final String roleLabel;
  final String tenantName;
  final String? academicYearId;
  final bool demoMode;
  final Tenant tenant;

  const _GreetingCard({
    required this.name,
    required this.roleLabel,
    required this.tenantName,
    required this.academicYearId,
    required this.demoMode,
    required this.tenant,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final compact = constraints.maxWidth < 430;
        final scheme = Theme.of(context).colorScheme;
        final tenantPrimary = AppColors.tenantPrimary(tenant);
        return Material(
          color: scheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.hero),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.all(compact ? 18 : 22),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.school_rounded,
                            size: 18,
                            color: scheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tenantName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (demoMode) const _WhitePill(label: 'Demo'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Welcome, $name',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                  fontSize: compact ? 22 : 25,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _WhitePill(label: roleLabel),
                          if (academicYearId?.isNotEmpty == true)
                            _WhitePill(label: academicYearId!),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: compact ? 10 : 18),
                CircleAvatar(
                  radius: compact ? 26 : 31,
                  backgroundColor: tenantPrimary,
                  foregroundColor: scheme.onPrimary,
                  child: Text(
                    name.trim().substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: compact ? 20 : 23,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WhitePill extends StatelessWidget {
  final String label;

  const _WhitePill({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
