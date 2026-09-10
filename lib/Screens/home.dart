import 'package:school_management/config/brand_config.dart';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../Widgets/saas_scaffold.dart';
import '../core/erp/erp_access_policy.dart';
import '../core/erp/erp_catalog.dart';
import '../core/erp/erp_entity.dart';
import '../core/erp/erp_module.dart';
import '../core/erp/tenant_erp_service.dart';
import '../services/plan_entitlement_service.dart';
import '../services/Auth_services.dart';
import '../services/session_state.dart';
import '../services/models/app_permission.dart';
import '../services/models/user_role.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_dashboard_summary_service.dart';
import '../config/backend_config.dart';
import '../theme/app_theme.dart';
import 'Management/AddStudent.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const Duration _dashboardCacheTtl = Duration(minutes: 3);
  static const Duration _dashboardRequestTimeout = Duration(seconds: 12);
  static const int _maxDashboardCacheEntries = 8;
  static final Map<String, _DashboardCacheEntry> _dashboardCache =
      <String, _DashboardCacheEntry>{};
  static final Map<String, Future<_DashboardSummaryData>> _inFlightLoads =
      <String, Future<_DashboardSummaryData>>{};

  late final StreamSubscription<dynamic> _authSubscription;
  _DashboardSummaryData _summary = const _DashboardSummaryData.empty();
  bool _isSummaryLoading = true;
  Object? _summaryError;
  String? _dashboardContextKey;
  Timer? _sessionChangeDebounce;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _dashboardContextKey = _currentDashboardContextKey();
    final cached = _dashboardCache[_dashboardContextKey];
    final hasFreshCache = cached != null &&
        DateTime.now().difference(cached.loadedAt) < _dashboardCacheTtl;
    _summary = hasFreshCache
        ? cached.data
        : _permissionAwareEmptySummary();
    _isSummaryLoading = !hasFreshCache;
    SessionState.instance.addListener(_handleSessionChange);
    _authSubscription = BackendConfig.isSupabasePrimary
        ? SupabaseAuthService().authStateChanges.listen(
              (dynamic state) => _handleAuthSession(state.session != null),
            )
        : AuthService().authStateChanges.listen(
              (User? user) => _handleAuthSession(user != null),
            );

    // Do not block the first dashboard frame with network aggregates. The
    // workspace is immediately interactive and live values hydrate after paint.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !hasFreshCache) _refreshDashboard();
    });
  }

  @override
  void dispose() {
    _sessionChangeDebounce?.cancel();
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
    final user = state.user;
    final roles = user?.roles.map((role) => role.name).join(',') ?? '';
    final permissions = user == null
        ? <String>[]
        : (user.effectivePermissions.toList(growable: false)..sort());
    return <String?>[
      state.tenant?.id,
      state.tenant?.name,
      user?.uid,
      user?.displayName,
      roles,
      permissions.join(','),
      state.activeCampusId,
      state.activeAcademicYearId,
    ].join('|');
  }

  _DashboardSummaryData _permissionAwareEmptySummary() {
    final state = SessionState.instance;
    final user = state.user;
    final tenant = state.tenant;
    if (user == null || tenant == null) {
      return const _DashboardSummaryData.empty();
    }

    final entitlement = PlanEntitlementService(tenant: tenant);
    bool canViewCollection(String collection, String moduleId) {
      final entity = ErpCatalog.entityByCollection(collection);
      return entity != null &&
          entitlement.canAccessModule(moduleId) &&
          ErpAccessPolicy.canViewEntity(entity, user, state.hasPermission);
    }

    return _DashboardSummaryData(
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
      canViewStudents: canViewCollection('students', 'students'),
      canViewAdmissions:
          canViewCollection('admission_applications', 'admissions'),
      canViewEmployees: canViewCollection('employees', 'hr-payroll'),
      canViewAttendance:
          canViewCollection('attendance_sessions', 'attendance'),
      canViewFees: canViewCollection('fee_invoices', 'fees'),
      canViewExams: canViewCollection('exams', 'examinations'),
      canViewAccounting: canViewCollection('expenses', 'accounting'),
    );
  }

  void _handleSessionChange() {
    final nextKey = _currentDashboardContextKey();
    if (!mounted || nextKey == _dashboardContextKey) return;
    _dashboardContextKey = nextKey;

    // Session hydration can notify several times in one burst. Debouncing avoids
    // rebuilding and re-querying the whole dashboard for intermediate states.
    _sessionChangeDebounce?.cancel();
    _sessionChangeDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() {
        _summary = _permissionAwareEmptySummary();
        _isSummaryLoading = true;
        _summaryError = null;
      });
      _refreshDashboard();
    });
  }

  Future<void> _refreshDashboard({bool force = false}) async {
    final generation = ++_loadGeneration;
    if (mounted && (!_isSummaryLoading || force)) {
      setState(() {
        _isSummaryLoading = true;
        _summaryError = null;
      });
    }

    try {
      final data = await _loadSummaryCached(force: force)
          .timeout(_dashboardRequestTimeout);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _summary = data;
        _isSummaryLoading = false;
        _summaryError = null;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _isSummaryLoading = false;
        _summaryError = error;
      });
    }
  }

  Future<_DashboardSummaryData> _loadSummaryCached({bool force = false}) {
    final key = _currentDashboardContextKey();
    final cached = _dashboardCache[key];
    final now = DateTime.now();
    if (!force &&
        cached != null &&
        now.difference(cached.loadedAt) < _dashboardCacheTtl) {
      return SynchronousFuture<_DashboardSummaryData>(cached.data);
    }

    if (!force) {
      final inFlight = _inFlightLoads[key];
      if (inFlight != null) return inFlight;
    }

    final load = _loadSummary().then((_DashboardSummaryData data) {
      _pruneDashboardCache();
      _dashboardCache[key] =
          _DashboardCacheEntry(data: data, loadedAt: DateTime.now());
      return data;
    }).whenComplete(() {
      _inFlightLoads.remove(key);
    });
    _inFlightLoads[key] = load;
    return load;
  }

  void _pruneDashboardCache() {
    final now = DateTime.now();
    _dashboardCache.removeWhere(
      (_, _DashboardCacheEntry entry) =>
          now.difference(entry.loadedAt) >= _dashboardCacheTtl,
    );
    if (_dashboardCache.length < _maxDashboardCacheEntries) return;
    final oldestKey = _dashboardCache.entries
        .reduce((a, b) => a.value.loadedAt.isBefore(b.value.loadedAt) ? a : b)
        .key;
    _dashboardCache.remove(oldestKey);
  }

  Future<_DashboardSummaryData> _loadSummary() async {
    final state = SessionState.instance;
    final user = state.user;
    final tenant = state.tenant;
    if (user == null || tenant == null) {
      return const _DashboardSummaryData.empty();
    }

    final service = TenantErpService();
    final usesSupabase = BackendConfig.isSupabasePrimary;
    final entitlement = PlanEntitlementService(tenant: tenant);
    final campusId = state.activeCampusId?.trim();
    final academicYearId = state.activeAcademicYearId?.trim();
    if (usesSupabase &&
        (campusId == null ||
            campusId.isEmpty ||
            academicYearId == null ||
            academicYearId.isEmpty)) {
      return _permissionAwareEmptySummary();
    }

    Map<String, dynamic> dashboardSummary = const <String, dynamic>{};
    try {
      dashboardSummary = usesSupabase
          ? await SupabaseDashboardSummaryService()
              .load(
                tenantId: tenant.id,
                campusId: campusId!,
                academicYearId: academicYearId!,
              )
              .timeout(const Duration(seconds: 4))
          : await service
              .loadDashboardSummary()
              .timeout(const Duration(seconds: 4));
    } catch (_) {
      // A stale/missing aggregate must never stop navigation or freeze the UI.
      // Bounded count fallbacks below will fill the permitted metrics.
      dashboardSummary = const <String, dynamic>{};
    }
    final summaryCounts = dashboardSummary['counts'];
    final summaryStatuses = dashboardSummary['statusCounts'];

    int? summarizedCount(String collection) {
      if (summaryCounts is! Map || !summaryCounts.containsKey(collection)) {
        return null;
      }
      return (summaryCounts[collection] as num?)?.toInt();
    }

    bool canViewCollection(String collection, String moduleId) {
      final entity = ErpCatalog.entityByCollection(collection);
      return entity != null &&
          entitlement.canAccessModule(moduleId) &&
          ErpAccessPolicy.canViewEntity(entity, user, state.hasPermission);
    }

    final studentEntity = ErpCatalog.entityByCollection('students');
    final admissionEntity =
        ErpCatalog.entityByCollection('admission_applications');
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

    Future<int> loadCount({
      required String collection,
      required bool allowed,
      ErpEntity? visibleEntity,
    }) async {
      if (!allowed) return 0;
      final summarized = summarizedCount(collection);
      final requiresPersonalScope = visibleEntity != null &&
          (user.role.isLearner || user.role.isGuardian);
      if (summarized != null && !requiresPersonalScope) return summarized;
      if (usesSupabase) return summarized ?? 0;
      try {
        final count = visibleEntity != null
            ? service.countVisible(visibleEntity)
            : service.count(collection);
        return await count.timeout(const Duration(seconds: 5));
      } catch (_) {
        return summarized ?? 0;
      }
    }

    Future<_AdmissionSummary> loadAdmissions() async {
      if (!canViewAdmissions) return const _AdmissionSummary.empty();
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

      final summarizedStatuses = <int?>[
        summarizedStatus('Draft'),
        summarizedStatus('Submitted'),
        summarizedStatus('Under Review'),
        summarizedStatus('Assessment'),
        summarizedStatus('Waitlisted'),
        summarizedStatus('Approved'),
        summarizedStatus('Enrolled'),
        summarizedStatus('Rejected'),
      ];
      final statusesComplete =
          summarizedStatuses.every((int? value) => value != null);
      final counts =
          summarizedStatuses.map((int? value) => value ?? 0).toList();
      final summarizedTotal = summarizedCount('admission_applications');
      int total = summarizedTotal ??
          counts.fold<int>(0, (int sum, int value) => sum + value);
      // Missing aggregate status data previously triggered eight Firestore
      // queries on every cold dashboard. One bounded total query is enough for
      // the overview; detailed status counts belong on the Admissions screen.
      if (!usesSupabase && !statusesComplete && summarizedTotal == null) {
        try {
          total = await service
              .count('admission_applications')
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          // Keep any partial aggregate values without blocking the dashboard.
        }
      }
      return _AdmissionSummary(
        total: total,
        pending: counts[0] + counts[1] + counts[2] + counts[3] + counts[4],
        approved: counts[5] + counts[6],
        rejected: counts[7],
      );
    }

    // All independent aggregates are resolved together. This removes the
    // sequential network waterfall that previously made the dashboard feel
    // frozen on mobile and web.
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      loadCount(
        collection: 'students',
        allowed: canViewStudents,
        visibleEntity: studentEntity,
      ),
      loadCount(collection: 'employees', allowed: canViewEmployees),
      loadCount(
        collection: 'attendance_sessions',
        allowed: canViewAttendance,
      ),
      loadCount(collection: 'fee_invoices', allowed: canViewFees),
      loadCount(collection: 'payments', allowed: canViewFees),
      loadCount(collection: 'exams', allowed: canViewExams),
      loadCount(collection: 'expenses', allowed: canViewAccounting),
      loadAdmissions(),
    ]);
    final admissions = results[7] as _AdmissionSummary;

    return _DashboardSummaryData(
      students: results[0] as int,
      employees: results[1] as int,
      attendanceSessions: results[2] as int,
      feeInvoices: results[3] as int,
      payments: results[4] as int,
      exams: results[5] as int,
      expenses: results[6] as int,
      totalAdmissions: admissions.total,
      pendingAdmissions: admissions.pending,
      approvedAdmissions: admissions.approved,
      rejectedAdmissions: admissions.rejected,
      canViewStudents: canViewStudents,
      canViewAdmissions: canViewAdmissions,
      canViewEmployees: canViewEmployees,
      canViewAttendance: canViewAttendance,
      canViewFees: canViewFees,
      canViewExams: canViewExams,
      canViewAccounting: canViewAccounting,
      updatedAt: DateTime.tryParse(
        dashboardSummary['updatedAt']?.toString() ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = SessionState.instance;
    final user = state.user;
    final tenant = state.tenant;
    if (user == null || tenant == null) {
      return const Scaffold(
        body: Center(child: Text('No active school session.')),
      );
    }

    final compactViewport = MediaQuery.sizeOf(context).width < 720;
    final canAddStudent = _summary.canViewStudents &&
        state.hasAnyPermission(const <String>[
          AppPermission.studentsCreate,
          AppPermission.studentsManage,
        ]);

    return SaasScaffold(
      title: 'Dashboard',
      activeRoute: '/home',
      floatingActionButton: canAddStudent
          ? compactViewport
              ? FloatingActionButton(
                  tooltip: 'Add student',
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AddStudentScreen(),
                    ),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded),
                )
              : FloatingActionButton.extended(
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AddStudentScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add student'),
                )
          : null,
      body: RefreshIndicator(
        onRefresh: () => _refreshDashboard(force: true),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final mobile = constraints.maxWidth < 720;
            return ListView(
              key: const PageStorageKey<String>('main-dashboard-scroll'),
              cacheExtent: mobile ? 160 : 240,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                mobile ? 16 : 24,
                mobile ? 10 : 22,
                mobile ? 16 : 24,
                mobile ? 26 : 38,
              ),
              children: <Widget>[
                RepaintBoundary(
                  child: _LiteDashboard(
                    summary: _summary,
                    state: state,
                    compact: mobile,
                    loading: _isSummaryLoading,
                    hasError: _summaryError != null,
                    onRefresh: () => _refreshDashboard(force: true),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A deliberately small dashboard tree. It avoids nested shrink-wrapped grids,
/// delayed timers, charts and decorative panels so the first frame and scroll
/// remain smooth on low-end phones and Flutter web.
class _LiteDashboard extends StatelessWidget {
  final _DashboardSummaryData summary;
  final SessionState state;
  final bool compact;
  final bool loading;
  final bool hasError;
  final VoidCallback onRefresh;

  const _LiteDashboard({
    required this.summary,
    required this.state,
    required this.compact,
    required this.loading,
    required this.hasError,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final modules = _visiblePrimaryModules(state);
    final moduleIds = modules.map((ErpModule item) => item.id).toSet();
    final metrics = <_MetricData>[
      if (summary.canViewStudents)
        _MetricData('Students', summary.students, Icons.school_outlined,
            AppColors.pastelBlue, const Color(0xFF4E68D8), 'students'),
      if (summary.canViewAttendance)
        _MetricData(
            'Attendance',
            summary.attendanceSessions,
            Icons.fact_check_outlined,
            AppColors.pastelGreen,
            const Color(0xFF27936B),
            'attendance'),
      if (summary.canViewFees)
        _MetricData('Fee invoices', summary.feeInvoices,
            Icons.receipt_long_outlined, AppColors.pastelGold,
            const Color(0xFFD89614), 'fees'),
      if (summary.canViewAdmissions)
        _MetricData('Admissions', summary.totalAdmissions,
            Icons.how_to_reg_outlined, AppColors.pastelCyan,
            const Color(0xFF22949A), 'admissions'),
      if (summary.canViewEmployees)
        _MetricData('Employees', summary.employees, Icons.badge_outlined,
            AppColors.pastelPurple, const Color(0xFF7B5DC7), 'hr-payroll'),
      if (summary.canViewExams)
        _MetricData('Exams', summary.exams,
            Icons.assignment_turned_in_outlined, AppColors.pastelRose,
            const Color(0xFFE05D65), 'examinations'),
    ];
    const quickIds = <String>[
      'students',
      'attendance',
      'fees',
      'examinations',
    ];
    final quickModules = quickIds
        .where(moduleIds.contains)
        .map(ErpCatalog.byId)
        .whereType<ErpModule>()
        .toList(growable: false);
    final shownModules = modules.take(compact ? 6 : 8).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _LiteWelcomeCard(
          state: state,
          compact: compact,
          loading: loading,
          onRefresh: onRefresh,
        ),
        if (loading) ...<Widget>[
          const SizedBox(height: 10),
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(99)),
            child: LinearProgressIndicator(minHeight: 3),
          ),
        ] else if (hasError) ...<Widget>[
          const SizedBox(height: 10),
          _LiteErrorBanner(onRetry: onRefresh),
        ],
        if (metrics.isNotEmpty) ...<Widget>[
          const SizedBox(height: 22),
          _LiteSectionHeader(
            title: 'Overview',
            subtitle: summary.updatedAt == null
                ? 'Current school totals'
                : 'Updated ${_relativeTime(summary.updatedAt!)}',
          ),
          const SizedBox(height: 11),
          _LiteMetricGrid(metrics: metrics, compact: compact),
        ],
        if (quickModules.isNotEmpty) ...<Widget>[
          const SizedBox(height: 24),
          const _LiteSectionHeader(
            title: 'Quick actions',
            subtitle: 'Your most-used school tasks',
          ),
          const SizedBox(height: 11),
          _LiteModuleGrid(
            modules: quickModules,
            compact: compact,
            actionStyle: true,
          ),
        ],
        if (shownModules.isNotEmpty) ...<Widget>[
          const SizedBox(height: 24),
          _LiteSectionHeader(
            title: 'Modules',
            subtitle: '${modules.length} available for your role',
            action: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/modules'),
              child: const Text('View all'),
            ),
          ),
          const SizedBox(height: 11),
          _LiteModuleGrid(modules: shownModules, compact: compact),
        ],
        if (summary.canViewAdmissions) ...<Widget>[
          const SizedBox(height: 24),
          _LiteAdmissionOverview(summary: summary),
        ],
      ],
    );
  }
}

class _LiteWelcomeCard extends StatelessWidget {
  final SessionState state;
  final bool compact;
  final bool loading;
  final VoidCallback onRefresh;

  const _LiteWelcomeCard({
    required this.state,
    required this.compact,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final displayName = state.user?.displayName?.trim();
    final name = displayName?.isNotEmpty == true ? displayName! : 'User';
    final firstName = name.split(RegExp(r'\s+')).first;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: compact ? 46 : 52,
            height: compact ? 46 : 52,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.school_rounded, color: scheme.primary, size: 25),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Good day, $firstName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: compact ? 18 : 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${state.tenant?.name ?? BrandConfig.companyName} · ${_todayLabel()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Refresh dashboard',
            onPressed: loading ? null : onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _LiteSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;

  const _LiteSectionHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _LiteMetricGrid extends StatelessWidget {
  final List<_MetricData> metrics;
  final bool compact;

  const _LiteMetricGrid({required this.metrics, required this.compact});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final columns = compact
            ? 2
            : constraints.maxWidth >= 1180
                ? 4
                : constraints.maxWidth >= 760
                    ? 3
                    : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map((_MetricData metric) => SizedBox(
                    width: width,
                    child: _LiteMetricCard(metric: metric),
                  ))
              .toList(growable: false),
        );
      },
    );
  }
}

class _LiteMetricCard extends StatelessWidget {
  final _MetricData metric;

  const _LiteMetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: () => _openModule(context, metric.moduleId),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        metric.foreground.withOpacity(0.12),
                        scheme.surface,
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(metric.icon, color: metric.foreground, size: 19),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_outward_rounded,
                      size: 16, color: scheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _compactNumber(metric.value),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiteModuleGrid extends StatelessWidget {
  final List<ErpModule> modules;
  final bool compact;
  final bool actionStyle;

  const _LiteModuleGrid({
    required this.modules,
    required this.compact,
    this.actionStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final columns = compact
            ? 2
            : constraints.maxWidth >= 1180
                ? 4
                : constraints.maxWidth >= 760
                    ? 3
                    : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: modules
              .map((ErpModule module) => SizedBox(
                    width: width,
                    child: _LiteModuleTile(
                      module: module,
                      actionStyle: actionStyle,
                    ),
                  ))
              .toList(growable: false),
        );
      },
    );
  }
}

class _LiteModuleTile extends StatelessWidget {
  final ErpModule module;
  final bool actionStyle;

  const _LiteModuleTile({required this.module, required this.actionStyle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tone = _toneForModule(module.id);
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: () => _openModule(context, module.id),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          constraints: BoxConstraints(minHeight: actionStyle ? 74 : 68),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    tone.foreground.withOpacity(0.11),
                    scheme.surface,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(module.icon, color: tone.foreground, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _shortModuleTitle(module.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge,
                    ),
                    if (actionStyle) ...<Widget>[
                      const SizedBox(height: 2),
                      Text('Open workspace', style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiteAdmissionOverview extends StatelessWidget {
  final _DashboardSummaryData summary;

  const _LiteAdmissionOverview({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: () => _openModule(context, 'admissions'),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.how_to_reg_rounded,
                    color: scheme.secondary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Admissions', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 3),
                    Text(
                      summary.pendingAdmissions > 0
                          ? '${summary.pendingAdmissions} awaiting review · ${summary.approvedAdmissions} approved'
                          : '${summary.totalAdmissions} applications in this school',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiteErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const _LiteErrorBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.cloud_off_outlined, color: scheme.onErrorContainer, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Live totals unavailable. Modules still work.',
              style: TextStyle(color: scheme.onErrorContainer, fontSize: 11.5),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _MobileDashboardHeader extends StatelessWidget {
  final String name;
  final SessionState state;

  const _MobileDashboardHeader({required this.name, required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final firstName = name.split(RegExp(r'\s+')).first;
    final visibleIds = _visiblePrimaryModules(state)
        .map((ErpModule module) => module.id)
        .toSet();
    final chips = <_MobileFilterAction>[
      const _MobileFilterAction('Today', Icons.today_rounded, null),
      if (visibleIds.contains('attendance'))
        const _MobileFilterAction(
          'Attendance',
          Icons.fact_check_outlined,
          'attendance',
        ),
      if (visibleIds.contains('fees'))
        const _MobileFilterAction(
          'Fees',
          Icons.payments_outlined,
          'fees',
        ),
      if (state.hasAnyPermission(const <String>[
        AppPermission.studentsManage,
        AppPermission.feesManage,
        AppPermission.accountingManage,
        AppPermission.examsManage,
      ]))
        const _MobileFilterAction(
          'Approvals',
          Icons.approval_outlined,
          '/approvals',
          route: true,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                scheme.primaryContainer,
                Color.alphaBlend(
                  scheme.primary.withOpacity(0.04),
                  scheme.surface,
                ),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Color.alphaBlend(
                scheme.primary.withOpacity(0.14),
                scheme.outlineVariant,
              ),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: scheme.shadow.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'TODAY AT SCHOOL',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Good day, $firstName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.55,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_todayLabel()} · Everything is ready in one place.',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: scheme.surface.withOpacity(0.74),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: scheme.primary,
                  size: 29,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (BuildContext context, int index) {
              final chip = chips[index];
              return ActionChip(
                avatar: Icon(
                  chip.icon,
                  size: 16,
                  color: index == 0 ? scheme.primary : scheme.onSurfaceVariant,
                ),
                label: Text(chip.label),
                backgroundColor:
                    index == 0 ? scheme.primaryContainer : scheme.surface,
                side: BorderSide(
                  color: index == 0
                      ? scheme.primary.withOpacity(0.24)
                      : scheme.outlineVariant,
                ),
                onPressed: chip.target == null
                    ? () {}
                    : chip.route
                        ? () => Navigator.pushNamed(context, chip.target!)
                        : () => _openModule(context, chip.target!),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MobileFilterAction {
  final String label;
  final IconData icon;
  final String? target;
  final bool route;

  const _MobileFilterAction(
    this.label,
    this.icon,
    this.target, {
    this.route = false,
  });
}

class _DesktopDashboardHeader extends StatelessWidget {
  final String name;
  final String role;
  final String school;
  final VoidCallback onRefresh;

  const _DesktopDashboardHeader({
    required this.name,
    required this.role,
    required this.school,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Good day, ${name.split(RegExp(r'\s+')).first}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                '$school • $role',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton.outlined(
          tooltip: 'Refresh dashboard',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded, size: 18),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/modules'),
          icon: const Icon(Icons.grid_view_rounded, size: 17),
          label: const Text('All modules'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(44, 42),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.navigation),
              const SizedBox(width: 8),
              Text(_todayLabel(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileDashboard extends StatelessWidget {
  final _DashboardSummaryData summary;
  final SessionState state;

  const _MobileDashboard({required this.summary, required this.state});

  @override
  Widget build(BuildContext context) {
    final modules = _visiblePrimaryModules(state);
    final visibleIds = modules.map((ErpModule module) => module.id).toSet();
    final metrics = <_MetricData>[
      if (summary.canViewStudents)
        _MetricData(
          'Students',
          summary.students,
          Icons.school_outlined,
          AppColors.pastelBlue,
          const Color(0xFF4E68D8),
          'students',
        ),
      if (summary.canViewAttendance)
        _MetricData(
          'Attendance',
          summary.attendanceSessions,
          Icons.fact_check_outlined,
          AppColors.pastelCyan,
          const Color(0xFF22949A),
          'attendance',
        ),
      if (summary.canViewFees)
        _MetricData(
          'Fee invoices',
          summary.feeInvoices,
          Icons.receipt_long_outlined,
          AppColors.pastelGold,
          const Color(0xFFD89614),
          'fees',
        ),
      if (summary.canViewExams)
        _MetricData(
          'Exams',
          summary.exams,
          Icons.assignment_turned_in_outlined,
          AppColors.pastelRose,
          const Color(0xFFE05D65),
          'examinations',
        ),
      if (summary.canViewAdmissions)
        _MetricData(
          'Admissions',
          summary.totalAdmissions,
          Icons.how_to_reg_outlined,
          AppColors.pastelGreen,
          const Color(0xFF27936B),
          'admissions',
        ),
      if (summary.canViewEmployees)
        _MetricData(
          'Employees',
          summary.employees,
          Icons.badge_outlined,
          AppColors.pastelPurple,
          const Color(0xFF7B5DC7),
          'hr-payroll',
        ),
    ];
    final quickActions = <_DashboardAction>[
      const _DashboardAction(
        label: 'Students',
        detail: 'Open records',
        icon: Icons.person_add_alt_1_outlined,
        moduleId: 'students',
        color: Color(0xFF4E68D8),
      ),
      const _DashboardAction(
        label: 'Attendance',
        detail: 'Mark today',
        icon: Icons.fact_check_outlined,
        moduleId: 'attendance',
        color: Color(0xFF27936B),
      ),
      const _DashboardAction(
        label: 'Fees',
        detail: 'Collect payment',
        icon: Icons.payments_outlined,
        moduleId: 'fees',
        color: Color(0xFFD89614),
      ),
      const _DashboardAction(
        label: 'Exams',
        detail: 'Open exams',
        icon: Icons.assignment_turned_in_outlined,
        moduleId: 'examinations',
        color: Color(0xFF7B5DC7),
      ),
    ].where((_DashboardAction item) => visibleIds.contains(item.moduleId)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (metrics.isNotEmpty) ...<Widget>[
          const _DashboardSectionTitle(title: 'Today at a glance'),
          const SizedBox(height: 11),
          SizedBox(
            height: 130,
            child: ListView.separated(
              key: const PageStorageKey<String>('mobile-dashboard-metrics'),
              scrollDirection: Axis.horizontal,
              cacheExtent: 420,
              itemCount: metrics.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (BuildContext context, int index) {
                return _MobileMetricCard(data: metrics[index]);
              },
            ),
          ),
        ],
        if (quickActions.isNotEmpty) ...<Widget>[
          const SizedBox(height: 22),
          const _DashboardSectionTitle(title: 'Quick actions'),
          const SizedBox(height: 11),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.05,
            ),
            itemCount: quickActions.length,
            itemBuilder: (BuildContext context, int index) {
              return _MobileQuickAction(action: quickActions[index]);
            },
          ),
        ],
        if (modules.isNotEmpty) ...<Widget>[
          const SizedBox(height: 22),
          Row(
            children: <Widget>[
              const Expanded(
                child: _DashboardSectionTitle(title: 'Academics & operations'),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/modules'),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 11,
              crossAxisSpacing: 11,
              childAspectRatio: 0.94,
            ),
            itemCount: modules.length > 9 ? 9 : modules.length,
            itemBuilder: (BuildContext context, int index) {
              return _MobileModuleTile(module: modules[index]);
            },
          ),
        ],
        if (metrics.isNotEmpty) ...<Widget>[
          const SizedBox(height: 22),
          const _DashboardSectionTitle(title: 'Operational analysis'),
          const SizedBox(height: 12),
          _DeferredDashboardSection(
            minHeight: 220,
            delay: const Duration(milliseconds: 45),
            child: _ExecutiveAnalysisPanel(summary: summary, compact: true),
          ),
        ],
        if (visibleIds.contains('events')) ...<Widget>[
          const SizedBox(height: 22),
          _DeferredDashboardSection(
            minHeight: 190,
            delay: const Duration(milliseconds: 110),
            child: _MobileEventCard(),
          ),
        ],
        if (visibleIds.contains('academics')) ...<Widget>[
          const SizedBox(height: 12),
          _DeferredDashboardSection(
            minHeight: 82,
            delay: const Duration(milliseconds: 140),
            child: _MobileLearningCard(),
          ),
        ],
      ],
    );
  }
}

class _MobileMetricCard extends StatelessWidget {
  final _MetricData data;

  const _MobileMetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 226,
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _openModule(context, data.moduleId),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          data.foreground.withOpacity(0.12),
                          scheme.surface,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(data.icon, color: data.foreground, size: 21),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: scheme.onSurfaceVariant,
                      size: 17,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  _compactNumber(data.value),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileQuickAction extends StatelessWidget {
  final _DashboardAction action;

  const _MobileQuickAction({required this.action});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _openModule(context, action.moduleId),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(action.icon, color: action.color, size: 19),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      action.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopDashboard extends StatelessWidget {
  final _DashboardSummaryData summary;
  final SessionState state;

  const _DesktopDashboard({required this.summary, required this.state});

  @override
  Widget build(BuildContext context) {
    final metrics = <_MetricData>[
      if (summary.canViewStudents)
        _MetricData(
          'Students',
          summary.students,
          Icons.school_outlined,
          AppColors.pastelBlue,
          const Color(0xFF4E68D8),
          'students',
        ),
      if (summary.canViewEmployees)
        _MetricData(
          'Employees',
          summary.employees,
          Icons.co_present_outlined,
          AppColors.pastelRose,
          const Color(0xFFE05D65),
          'hr-payroll',
        ),
      if (summary.canViewAdmissions)
        _MetricData(
          'Admissions',
          summary.totalAdmissions,
          Icons.how_to_reg_outlined,
          AppColors.pastelCyan,
          const Color(0xFF22949A),
          'admissions',
        ),
      if (summary.canViewFees)
        _MetricData(
          'Fee Invoices',
          summary.feeInvoices,
          Icons.account_balance_wallet_outlined,
          AppColors.pastelGold,
          const Color(0xFFD89614),
          'fees',
        ),
      if (summary.canViewAttendance)
        _MetricData(
          'Attendance',
          summary.attendanceSessions,
          Icons.fact_check_outlined,
          AppColors.pastelGreen,
          const Color(0xFF27936B),
          'attendance',
        ),
      if (summary.canViewExams)
        _MetricData(
          'Exams',
          summary.exams,
          Icons.assignment_turned_in_outlined,
          AppColors.pastelPurple,
          const Color(0xFF7B5DC7),
          'examinations',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _DashboardCommandCenter(state: state, summary: summary),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final columns = constraints.maxWidth >= 1320
                ? 4
                : constraints.maxWidth >= 900
                    ? 3
                    : 2;
            final spacing = 14.0;
            final itemWidth =
                (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: metrics
                  .map(
                    (_MetricData data) => SizedBox(
                      width: itemWidth,
                      child: _DesktopMetricCard(data: data),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
        const SizedBox(height: 16),
        _ExecutiveAnalysisPanel(summary: summary, compact: false),
        const SizedBox(height: 16),
        _DeferredDashboardSection(
          minHeight: 330,
          delay: const Duration(milliseconds: 35),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final stacked = constraints.maxWidth < 1100;
              final overview = RepaintBoundary(
                child: _OperationsOverview(summary: summary),
              );
              final calendar = const RepaintBoundary(
                child: _EventsCalendar(),
              );
              if (stacked) {
                return Column(
                  children: <Widget>[
                    overview,
                    const SizedBox(height: 14),
                    calendar,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 7, child: overview),
                  const SizedBox(width: 14),
                  Expanded(flex: 3, child: calendar),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        _DeferredDashboardSection(
          minHeight: 260,
          delay: const Duration(milliseconds: 95),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final stacked = constraints.maxWidth < 980;
              final access = _QuickAccessPanel(state: state);
              final admissions = _AdmissionsPanel(summary: summary);
              final attendance = _AttendancePanel(summary: summary);
              if (stacked) {
                return Column(
                  children: <Widget>[
                    access,
                    if (summary.canViewAdmissions) ...<Widget>[
                      const SizedBox(height: 14),
                      admissions,
                    ],
                    if (summary.canViewAttendance) ...<Widget>[
                      const SizedBox(height: 14),
                      attendance,
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(flex: 4, child: access),
                  if (summary.canViewAdmissions) ...<Widget>[
                    const SizedBox(width: 14),
                    Expanded(flex: 4, child: admissions),
                  ],
                  if (summary.canViewAttendance) ...<Widget>[
                    const SizedBox(width: 14),
                    Expanded(flex: 3, child: attendance),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DashboardCommandCenter extends StatelessWidget {
  final SessionState state;
  final _DashboardSummaryData summary;

  const _DashboardCommandCenter({required this.state, required this.summary});

  @override
  Widget build(BuildContext context) {
    final visibleIds = _visiblePrimaryModules(state)
        .map((ErpModule module) => module.id)
        .toSet();
    final actions = <_DashboardAction>[
      const _DashboardAction(
        label: 'Students',
        detail: 'Profiles & enrollment',
        icon: Icons.person_add_alt_1_outlined,
        moduleId: 'students',
        color: Color(0xFF4E68D8),
      ),
      const _DashboardAction(
        label: 'Attendance',
        detail: 'Mark today',
        icon: Icons.fact_check_outlined,
        moduleId: 'attendance',
        color: Color(0xFF27936B),
      ),
      const _DashboardAction(
        label: 'Collect fees',
        detail: 'Invoices & payments',
        icon: Icons.payments_outlined,
        moduleId: 'fees',
        color: Color(0xFFD89614),
      ),
      const _DashboardAction(
        label: 'Examinations',
        detail: 'Schedule & results',
        icon: Icons.assignment_turned_in_outlined,
        moduleId: 'examinations',
        color: Color(0xFF7B5DC7),
      ),
      const _DashboardAction(
        label: 'Reports',
        detail: 'School analytics',
        icon: Icons.query_stats_outlined,
        moduleId: 'reports',
        color: Color(0xFF22949A),
      ),
    ].where((_DashboardAction item) => visibleIds.contains(item.moduleId)).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navigation,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1D263D52),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final compact = constraints.maxWidth < 980;
          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Text(
                    'COMMAND CENTER',
                    style: TextStyle(
                      color: Color(0xFFBFD0DE),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16B36B).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.bolt_rounded,
                          color: Color(0xFF7DE0A9),
                          size: 11,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'FAST MODE',
                          style: TextStyle(
                            color: Color(0xFF9DEABB),
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              const Text(
                'Run your school from one screen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                summary.updatedAt == null
                    ? 'Live operational shortcuts with permission-aware access.'
                    : 'Live summary synced ${_relativeTime(summary.updatedAt!)}.',
                style: const TextStyle(
                  color: Color(0xFFD6E1E9),
                  fontSize: 10.5,
                ),
              ),
            ],
          );
          final actionStrip = Wrap(
            spacing: 9,
            runSpacing: 9,
            children: actions
                .map(
                  (_DashboardAction action) => _CommandActionButton(
                    action: action,
                  ),
                )
                .toList(growable: false),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                heading,
                const SizedBox(height: 16),
                actionStrip,
              ],
            );
          }
          return Row(
            children: <Widget>[
              SizedBox(width: 300, child: heading),
              const SizedBox(width: 22),
              Expanded(child: actionStrip),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardAction {
  final String label;
  final String detail;
  final IconData icon;
  final String moduleId;
  final Color color;

  const _DashboardAction({
    required this.label,
    required this.detail,
    required this.icon,
    required this.moduleId,
    required this.color,
  });
}

class _CommandActionButton extends StatelessWidget {
  final _DashboardAction action;

  const _CommandActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: () => _openModule(context, action.moduleId),
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 145,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(action.icon, color: Colors.white, size: 17),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      action.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFBFD0DE),
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSectionTitle extends StatelessWidget {
  final String title;
  const _DashboardSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17));
  }
}

class _MobileModuleTile extends StatelessWidget {
  final ErpModule module;
  const _MobileModuleTile({required this.module});

  @override
  Widget build(BuildContext context) {
    final tone = _toneForModule(module.id);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pushNamed(context, '/erp-module', arguments: module),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    tone.foreground.withOpacity(0.11),
                    scheme.surface,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(module.icon, color: tone.foreground, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                _shortModuleTitle(module.title),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 10.3,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopMetricCard extends StatelessWidget {
  final _MetricData data;
  const _DesktopMetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: () => _openModule(context, data.moduleId),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          height: 98,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: data.background,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(data.icon, color: data.foreground, size: 24),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      data.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _compactNumber(data.value),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.navigation,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationsOverview extends StatelessWidget {
  final _DashboardSummaryData summary;
  const _OperationsOverview({required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = <_OperationPulse>[
      if (summary.canViewStudents)
        _OperationPulse(
          'Students',
          summary.students,
          'students',
          const Color(0xFF4E68D8),
        ),
      if (summary.canViewEmployees)
        _OperationPulse(
          'Employees',
          summary.employees,
          'hr-payroll',
          const Color(0xFFE05D65),
        ),
      if (summary.canViewAdmissions)
        _OperationPulse(
          'Admissions',
          summary.totalAdmissions,
          'admissions',
          const Color(0xFF22949A),
        ),
      if (summary.canViewFees)
        _OperationPulse(
          'Fee invoices',
          summary.feeInvoices,
          'fees',
          const Color(0xFFD89614),
        ),
      if (summary.canViewAttendance)
        _OperationPulse(
          'Attendance sessions',
          summary.attendanceSessions,
          'attendance',
          const Color(0xFF27936B),
        ),
      if (summary.canViewExams)
        _OperationPulse(
          'Examinations',
          summary.exams,
          'examinations',
          const Color(0xFF7B5DC7),
        ),
    ];
    final maxValue = items.fold<int>(
      1,
      (int current, _OperationPulse item) =>
          item.value > current ? item.value : current,
    );

    return Container(
      height: 330,
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Operations Overview',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Live totals from your active campus and academic year',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/modules'),
                icon: const Icon(Icons.grid_view_rounded, size: 15),
                label: const Text('All modules'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No operational metrics are available for this role.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  final item = items[index];
                  final ratio = (item.value / maxValue).clamp(0.04, 1.0).toDouble();
                  return InkWell(
                    onTap: () => _openModule(context, item.moduleId),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 112,
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 10,
                                backgroundColor: item.color.withOpacity(0.10),
                                color: item.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 44,
                            child: Text(
                              _compactNumber(item.value),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 9),
          Row(
            children: <Widget>[
              _SummaryChip(
                label: 'Payments',
                value: summary.payments,
                icon: Icons.south_west_rounded,
                color: const Color(0xFF27936B),
                onTap: summary.canViewFees
                    ? () => _openModule(context, 'fees')
                    : null,
              ),
              const SizedBox(width: 8),
              _SummaryChip(
                label: 'Expenses',
                value: summary.expenses,
                icon: Icons.north_east_rounded,
                color: const Color(0xFFE05D65),
                onTap: summary.canViewAccounting
                    ? () => _openModule(context, 'accounting')
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OperationPulse {
  final String label;
  final int value;
  final String moduleId;
  final Color color;

  const _OperationPulse(this.label, this.value, this.moduleId, this.color);
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: <Widget>[
                Icon(icon, color: color, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _compactNumber(value),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventsCalendar extends StatelessWidget {
  const _EventsCalendar();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, 1);
    final leading = first.weekday % 7;
    final days = DateTime(now.year, now.month + 1, 0).day;

    return Container(
      height: 330,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Calendar workspace',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Open live events or timetable records',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _openModule(context, 'events'),
                child: const Text('Open events'),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: <Widget>[
              Expanded(
                child: _CalendarAction(
                  label: 'Events',
                  detail: 'School calendar',
                  icon: Icons.event_outlined,
                  color: const Color(0xFF4E68D8),
                  onTap: () => _openModule(context, 'events'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CalendarAction(
                  label: 'Timetable',
                  detail: 'Classes & periods',
                  icon: Icons.calendar_view_week_outlined,
                  color: const Color(0xFF22949A),
                  onTap: () => _openModule(context, 'timetable'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.today_outlined,
                  size: 17,
                  color: AppColors.navigation,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _monthLabel(now),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  _todayLabel(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: <Widget>[
              _WeekLabel('S'),
              _WeekLabel('M'),
              _WeekLabel('T'),
              _WeekLabel('W'),
              _WeekLabel('T'),
              _WeekLabel('F'),
              _WeekLabel('S'),
            ],
          ),
          const SizedBox(height: 3),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.35,
              ),
              itemCount: 42,
              itemBuilder: (BuildContext context, int index) {
                final day = index - leading + 1;
                final valid = day >= 1 && day <= days;
                final today = valid && day == now.day;
                return Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: today ? AppColors.navigation : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      valid ? '$day' : '',
                      style: TextStyle(
                        fontSize: 9.2,
                        fontWeight: today ? FontWeight.w800 : FontWeight.w500,
                        color: today ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarAction extends StatelessWidget {
  final String label;
  final String detail;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CalendarAction({
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Row(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessPanel extends StatelessWidget {
  final SessionState state;
  const _QuickAccessPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final modules = _visiblePrimaryModules(state).take(6).toList(growable: false);
    return Container(
      constraints: const BoxConstraints(minHeight: 260),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Quick Access', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: modules.map((ErpModule module) {
              final tone = _toneForModule(module.id);
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.pushNamed(context, '/erp-module', arguments: module),
                child: Container(
                  width: 118,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                  decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                  child: Row(
                    children: <Widget>[
                      Container(width: 30, height: 30, decoration: BoxDecoration(color: tone.background, borderRadius: BorderRadius.circular(8)), child: Icon(module.icon, color: tone.foreground, size: 16)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_shortModuleTitle(module.title), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700))),
                    ],
                  ),
                ),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _AdmissionsPanel extends StatelessWidget {
  final _DashboardSummaryData summary;
  const _AdmissionsPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    final total = summary.totalAdmissions == 0 ? 1 : summary.totalAdmissions;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: () => _openModule(context, 'admissions'),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          constraints: const BoxConstraints(minHeight: 260),
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Admissions Pipeline',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 17,
                    color: AppColors.navigation,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _progressRow(
                'Pending',
                summary.pendingAdmissions,
                total,
                const Color(0xFFF0B429),
              ),
              const SizedBox(height: 14),
              _progressRow(
                'Approved',
                summary.approvedAdmissions,
                total,
                const Color(0xFF16B36B),
              ),
              const SizedBox(height: 14),
              _progressRow(
                'Rejected',
                summary.rejectedAdmissions,
                total,
                const Color(0xFFF25F62),
              ),
              const Spacer(),
              Row(
                children: <Widget>[
                  Text(
                    '${summary.totalAdmissions}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      'total applications',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Text(
                    'Manage',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navigation,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendancePanel extends StatelessWidget {
  final _DashboardSummaryData summary;
  const _AttendancePanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    final progress = summary.students == 0
        ? 0.0
        : (summary.attendanceSessions / summary.students)
            .clamp(0.0, 1.0)
            .toDouble();
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: () => _openModule(context, 'attendance'),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          constraints: const BoxConstraints(minHeight: 260),
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Attendance Activity',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 17,
                    color: AppColors.navigation,
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: SizedBox(
                  width: 126,
                  height: 126,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: 112,
                        height: 112,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          backgroundColor: AppColors.pastelGold,
                          color: const Color(0xFF4E68D8),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            _compactNumber(summary.attendanceSessions),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'sessions logged',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.touch_app_outlined,
                    size: 14,
                    color: AppColors.navigation,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Open attendance workspace',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navigation,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileEventCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: () => _openModule(context, 'events'),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.pastelRose,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.event_available_outlined,
                  color: Color(0xFFE05D65),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Events & calendar',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_monthLabel(now)} · open live school events',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: AppColors.navigation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileLearningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.pastelCyan,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: () => _openModule(context, 'academics'),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: const Color(0xFFD5EDEE)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Color(0xFF22949A),
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'E-Learning',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Continue lessons and assignments.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: AppColors.navigation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeferredDashboardSection extends StatefulWidget {
  final Widget child;
  final double minHeight;
  final Duration delay;

  const _DeferredDashboardSection({
    required this.child,
    required this.minHeight,
    required this.delay,
  });

  @override
  State<_DeferredDashboardSection> createState() =>
      _DeferredDashboardSectionState();
}

class _DeferredDashboardSectionState
    extends State<_DeferredDashboardSection> {
  Timer? _timer;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _timer = Timer(widget.delay, () {
        if (mounted) setState(() => _ready = true);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return RepaintBoundary(child: widget.child);
    return SizedBox(
      height: widget.minHeight,
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _DashboardHydrationBar extends StatelessWidget {
  const _DashboardHydrationBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: <Widget>[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dashboard is ready. Live analysis is updating in the background…',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardInlineError extends StatelessWidget {
  final VoidCallback onRetry;

  const _DashboardInlineError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.pastelGold,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE7D39A)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: Color(0xFF9A7014),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'Live totals are temporarily unavailable. Navigation remains active.',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ExecutiveAnalysisPanel extends StatelessWidget {
  final _DashboardSummaryData summary;
  final bool compact;

  const _ExecutiveAnalysisPanel({
    required this.summary,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final approvalRate = summary.totalAdmissions == 0
        ? 0.0
        : summary.approvedAdmissions / summary.totalAdmissions;
    final attendanceActivity = summary.students == 0
        ? 0.0
        : summary.attendanceSessions / summary.students;
    final paymentActivity = summary.feeInvoices == 0
        ? 0.0
        : summary.payments / summary.feeInvoices;
    final studentStaffRatio = summary.employees == 0
        ? 0.0
        : summary.students / summary.employees;

    final insights = <_AnalysisInsight>[
      if (summary.canViewAdmissions)
        _AnalysisInsight(
          label: 'Admission approval',
          value: _percentLabel(approvalRate),
          detail: summary.totalAdmissions == 0
              ? 'No applications in this scope'
              : '${summary.approvedAdmissions} approved of ${summary.totalAdmissions}',
          progress: approvalRate,
          icon: Icons.how_to_reg_outlined,
          color: const Color(0xFF22949A),
          moduleId: 'admissions',
        ),
      if (summary.canViewAttendance)
        _AnalysisInsight(
          label: 'Attendance activity',
          value: _ratioLabel(attendanceActivity),
          detail: '${summary.attendanceSessions} sessions for ${summary.students} students',
          progress: attendanceActivity,
          icon: Icons.fact_check_outlined,
          color: const Color(0xFF27936B),
          moduleId: 'attendance',
        ),
      if (summary.canViewFees)
        _AnalysisInsight(
          label: 'Payment activity',
          value: _ratioLabel(paymentActivity),
          detail: '${summary.payments} payment records vs ${summary.feeInvoices} invoices',
          progress: paymentActivity,
          icon: Icons.payments_outlined,
          color: const Color(0xFFD89614),
          moduleId: 'fees',
        ),
      if (summary.canViewStudents && summary.canViewEmployees)
        _AnalysisInsight(
          label: 'Student–staff ratio',
          value: studentStaffRatio == 0
              ? '—'
              : '${studentStaffRatio.toStringAsFixed(1)} : 1',
          detail: '${summary.students} students · ${summary.employees} employees',
          progress: studentStaffRatio == 0 ? 0 : 1 / studentStaffRatio,
          icon: Icons.groups_2_outlined,
          color: const Color(0xFF7B5DC7),
          moduleId: 'hr-payroll',
        ),
    ];

    if (insights.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.pastelBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.navigation,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Executive analysis',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Calculated from the active campus and academic-year totals',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _openModule(context, 'reports'),
                icon: const Icon(Icons.query_stats_outlined, size: 15),
                label: const Text('Reports'),
              ),
            ],
          ),
          const SizedBox(height: 13),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final columns = compact
                  ? (constraints.maxWidth >= 520 ? 2 : 1)
                  : constraints.maxWidth >= 1180
                      ? 4
                      : constraints.maxWidth >= 720
                          ? 2
                          : 1;
              const spacing = 10.0;
              final width =
                  (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: insights
                    .map(
                      (_AnalysisInsight insight) => SizedBox(
                        width: width,
                        child: _AnalysisInsightCard(insight: insight),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnalysisInsight {
  final String label;
  final String value;
  final String detail;
  final double progress;
  final IconData icon;
  final Color color;
  final String moduleId;

  const _AnalysisInsight({
    required this.label,
    required this.value,
    required this.detail,
    required this.progress,
    required this.icon,
    required this.color,
    required this.moduleId,
  });
}

class _AnalysisInsightCard extends StatelessWidget {
  final _AnalysisInsight insight;

  const _AnalysisInsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: () => _openModule(context, insight.moduleId),
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                      color: insight.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(insight.icon, color: insight.color, size: 17),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                insight.value,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                insight.label,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                insight.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 8.8,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: insight.progress.clamp(0.0, 1.0).toDouble(),
                  minHeight: 5,
                  backgroundColor: insight.color.withOpacity(0.10),
                  color: insight.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _percentLabel(double value) {
  if (!value.isFinite || value <= 0) return '0%';
  return '${(value * 100).round()}%';
}

String _ratioLabel(double value) {
  if (!value.isFinite || value <= 0) return '0.0x';
  return '${value.toStringAsFixed(1)}x';
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(4, (int index) => Container(
        height: index == 3 ? 240 : 82,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card), border: Border.all(color: AppColors.border)),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      )),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final VoidCallback onRetry;
  const _DashboardError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card), border: Border.all(color: AppColors.border)),
      child: Column(
        children: <Widget>[
          const Icon(Icons.cloud_off_rounded, color: AppColors.danger, size: 38),
          const SizedBox(height: 10),
          const Text('Dashboard data could not be loaded.', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
        ],
      ),
    );
  }
}

class _DashboardCacheEntry {
  final _DashboardSummaryData data;
  final DateTime loadedAt;

  const _DashboardCacheEntry({required this.data, required this.loadedAt});
}

class _AdmissionSummary {
  final int total;
  final int pending;
  final int approved;
  final int rejected;

  const _AdmissionSummary({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  const _AdmissionSummary.empty()
      : total = 0,
        pending = 0,
        approved = 0,
        rejected = 0;
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
  final DateTime? updatedAt;

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
    this.updatedAt,
  });

  const _DashboardSummaryData.empty()
      : students = 0,
        employees = 0,
        attendanceSessions = 0,
        feeInvoices = 0,
        payments = 0,
        exams = 0,
        expenses = 0,
        totalAdmissions = 0,
        pendingAdmissions = 0,
        approvedAdmissions = 0,
        rejectedAdmissions = 0,
        canViewStudents = false,
        canViewAdmissions = false,
        canViewEmployees = false,
        canViewAttendance = false,
        canViewFees = false,
        canViewExams = false,
        canViewAccounting = false,
        updatedAt = null;
}

class _MetricData {
  final String label;
  final int value;
  final IconData icon;
  final Color background;
  final Color foreground;
  final String moduleId;

  const _MetricData(
    this.label,
    this.value,
    this.icon,
    this.background,
    this.foreground,
    this.moduleId,
  );
}

class _ModuleTone {
  final Color background;
  final Color foreground;
  const _ModuleTone(this.background, this.foreground);
}

List<ErpModule> _visiblePrimaryModules(SessionState state) {
  final entitlement = PlanEntitlementService(tenant: state.tenant);
  return ErpCatalog.modules
      .where((ErpModule module) => entitlement.canAccessModule(module.id))
      .where((ErpModule module) => ErpAccessPolicy.canViewModule(module, state.user, state.hasPermission))
      .toList(growable: false);
}

_ModuleTone _toneForModule(String id) {
  const tones = <_ModuleTone>[
    _ModuleTone(AppColors.pastelGold, Color(0xFFD89614)),
    _ModuleTone(AppColors.pastelRose, Color(0xFFE05D65)),
    _ModuleTone(AppColors.pastelBlue, Color(0xFF4E68D8)),
    _ModuleTone(AppColors.pastelCyan, Color(0xFF22949A)),
    _ModuleTone(AppColors.pastelGreen, Color(0xFF27936B)),
    _ModuleTone(AppColors.pastelPurple, Color(0xFF7B5DC7)),
  ];
  final index = id.codeUnits.fold<int>(0, (int value, int item) => value + item) % tones.length;
  return tones[index];
}

String _shortModuleTitle(String value) {
  const map = <String, String>{
    'School Setup': 'School',
    'HR & Payroll': 'Teachers',
    'Examinations': 'Exams',
    'Communication': 'Inbox',
    'Timetable & Scheduling': 'Time Table',
    'Student Welfare': 'Welfare',
    'AI & Automation': 'AI Tools',
  };
  return map[value] ?? value;
}

String _compactNumber(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}m';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}k';
  return value.toString();
}

String _todayLabel() {
  final now = DateTime.now();
  const months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${now.day} ${months[now.month - 1]} ${now.year}';
}

String _monthLabel(DateTime date) {
  const months = <String>['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  return '${months[date.month - 1]} ${date.year}';
}

String _relativeTime(DateTime date) {
  final difference = DateTime.now().difference(date.toLocal());
  if (difference.inSeconds < 60) return 'just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  return '${difference.inDays}d ago';
}

Widget _legendDot(Color color, String label) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
    ],
  );
}

Widget _miniEvent(String title, String time, Color color) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(height: 5),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700)),
          Text(time, style: const TextStyle(fontSize: 8.5, color: AppColors.textSecondary)),
        ],
      ),
    ),
  );
}

Widget _progressRow(String label, int value, int total, Color color) {
  final ratio = (value / total).clamp(0.0, 1.0).toDouble();
  return Column(
    children: <Widget>[
      Row(
        children: <Widget>[
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
          Text('$value', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
        ],
      ),
      const SizedBox(height: 7),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(value: ratio, minHeight: 7, backgroundColor: color.withOpacity(0.12), color: color),
      ),
    ],
  );
}

Widget _eventRow(String day, String month, String title, String time, Color color) {
  return Row(
    children: <Widget>[
      SizedBox(
        width: 38,
        child: Column(
          children: <Widget>[
            Text(day, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text(month, style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
      Container(width: 3, height: 48, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(children: <Widget>[const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textSecondary), const SizedBox(width: 5), Text(time, style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary))]),
          ],
        ),
      ),
    ],
  );
}

void _openModule(BuildContext context, String id) {
  final module = ErpCatalog.byId(id);
  if (module != null) Navigator.pushNamed(context, '/erp-module', arguments: module);
}

class _WeekLabel extends StatelessWidget {
  final String text;
  const _WeekLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8.5, color: AppColors.textSecondary, fontWeight: FontWeight.w700)));
  }
}
