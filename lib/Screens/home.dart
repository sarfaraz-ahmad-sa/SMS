import 'package:flutter/material.dart';

import '../Widgets/FeatureCard.dart';
import '../Widgets/MainDrawer.dart';
import '../Widgets/TenantSwitcher.dart';
import '../core/erp/erp_access_policy.dart';
import '../core/erp/erp_catalog.dart';
import '../core/erp/erp_entity.dart';
import '../core/erp/tenant_erp_service.dart';
import '../services/models/app_permission.dart';
import '../services/models/user_role.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';
import 'Activity.dart';
import 'Attendance/Attendance.dart';
import 'Enterprise/ErpEntityListScreen.dart';
import 'Enterprise/ErpModuleScreen.dart';
import 'Exam/Exam_Rseult.dart';
import 'Fees.dart';
import 'GlobalSearch.dart';
import 'Leave_Apply/LeaveApply.dart';
import 'Library.dart';
import 'Notifications.dart';
import 'Profile.dart';
import 'TimeTable.dart';
import 'Transport.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<_DashboardSummaryData> _summaryFuture;
  String? _dashboardContextKey;

  @override
  void initState() {
    super.initState();
    _dashboardContextKey = _currentDashboardContextKey();
    _refreshDashboard();
    SessionState.instance.addListener(_handleSessionChange);
  }

  @override
  void dispose() {
    SessionState.instance.removeListener(_handleSessionChange);
    super.dispose();
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
    final service = TenantErpService();

    var students = 0;
    var totalAdmissions = 0;
    var pendingAdmissions = 0;
    var approvedAdmissions = 0;
    var rejectedAdmissions = 0;

    final studentEntity = ErpCatalog.entityByCollection('students');
    final admissionEntity =
        ErpCatalog.entityByCollection('admission_applications');

    final canViewStudents = studentEntity != null &&
        ErpAccessPolicy.canViewEntity(
          studentEntity,
          user,
          state.hasPermission,
        );
    final canViewAdmissions = admissionEntity != null &&
        ErpAccessPolicy.canViewEntity(
          admissionEntity,
          user,
          state.hasPermission,
        );

    if (canViewStudents) {
      final personalScope = user != null &&
          (user.role.isLearner || user.role.isGuardian);
      students = personalScope
          ? await service.countVisible(studentEntity!)
          : await service.count('students');
    }

    if (canViewAdmissions) {
      totalAdmissions = await service.count('admission_applications');

      final counts = await Future.wait<int>(<Future<int>>[
        service.countWhere('admission_applications', 'status', 'Draft'),
        service.countWhere('admission_applications', 'status', 'Submitted'),
        service.countWhere(
          'admission_applications',
          'status',
          'Under Review',
        ),
        service.countWhere('admission_applications', 'status', 'Assessment'),
        service.countWhere('admission_applications', 'status', 'Waitlisted'),
        service.countWhere('admission_applications', 'status', 'Approved'),
        service.countWhere('admission_applications', 'status', 'Enrolled'),
        service.countWhere('admission_applications', 'status', 'Rejected'),
      ]);

      pendingAdmissions =
          counts[0] + counts[1] + counts[2] + counts[3] + counts[4];
      approvedAdmissions = counts[5] + counts[6];
      rejectedAdmissions = counts[7];
    }

    return _DashboardSummaryData(
      students: students,
      totalAdmissions: totalAdmissions,
      pendingAdmissions: pendingAdmissions,
      approvedAdmissions: approvedAdmissions,
      rejectedAdmissions: rejectedAdmissions,
      canViewStudents: canViewStudents,
      canViewAdmissions: canViewAdmissions,
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

        if (user == null || tenant == null) {
          return const Scaffold(
            body: Center(child: Text('No active school session.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: <Widget>[
              const TenantSwitcher(compact: true),
              IconButton(
                tooltip: 'Global Search',
                icon: const Icon(Icons.search_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const GlobalSearchScreen(),
                  ),
                ),
              ),
              if (state.hasPermission(AppPermission.notificationsView))
                IconButton(
                  tooltip: 'Notifications',
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                ),
            ],
          ),
          drawer: const Drawer(child: MainDrawer()),
          body: RefreshIndicator(
            onRefresh: () async {
              setState(_refreshDashboard);
              await _summaryFuture;
            },
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                  children: <Widget>[
                    _GreetingCard(
                      name: user.displayName?.trim().isNotEmpty == true
                          ? user.displayName!.trim()
                          : 'User',
                      roleLabel: user.roleLabel,
                      tenantName: tenant.name,
                      academicYearId: state.activeAcademicYearId,
                      demoMode: TenantErpService().isDemoMode,
                    ),
                    const SizedBox(height: 18),
                    _DashboardSummary(
                      future: _summaryFuture,
                      onRetry: () => setState(_refreshDashboard),
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle(
                      title: 'Quick Access',
                      subtitle: 'Your frequently used school services',
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

class _DashboardSummaryData {
  final int students;
  final int totalAdmissions;
  final int pendingAdmissions;
  final int approvedAdmissions;
  final int rejectedAdmissions;
  final bool canViewStudents;
  final bool canViewAdmissions;

  const _DashboardSummaryData({
    required this.students,
    required this.totalAdmissions,
    required this.pendingAdmissions,
    required this.approvedAdmissions,
    required this.rejectedAdmissions,
    required this.canViewStudents,
    required this.canViewAdmissions,
  });
}

class _DashboardSummary extends StatelessWidget {
  final Future<_DashboardSummaryData> future;
  final VoidCallback onRetry;

  const _DashboardSummary({
    required this.future,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardSummaryData>(
      future: future,
      builder: (
        BuildContext context,
        AsyncSnapshot<_DashboardSummaryData> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 170,
            child: Center(child: CircularProgressIndicator()),
          );
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
        final cards = <Widget>[
          if (data.canViewStudents)
            _StudentCountCard(count: data.students),
          if (data.canViewAdmissions)
            _AdmissionSummaryCard(data: data),
        ];

        if (cards.isEmpty) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth >= 760 && cards.length == 2) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 2, child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: cards[1]),
                ],
              );
            }

            return Column(
              children: <Widget>[
                for (var index = 0; index < cards.length; index++) ...<Widget>[
                  cards[index],
                  if (index != cards.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _StudentCountCard extends StatelessWidget {
  final int count;

  const _StudentCountCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final entity = ErpCatalog.entityByCollection('students');
          if (entity == null) return;
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ErpEntityListScreen(entity: entity),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: <Widget>[
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.groups_outlined,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Active Students',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
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
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: items,
                    );
                  }

                  return Row(
                    children: <Widget>[
                      for (var index = 0; index < items.length; index++) ...[
                        Expanded(child: items[index]),
                        if (index != items.length - 1)
                          const SizedBox(width: 8),
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
        permissions: const <String>[AppPermission.attendanceView],
        builder: (_) => Attendance(),
      ),
      _QuickAccessItem(
        title: 'Exam Results',
        icon: Icons.assignment_outlined,
        color: AppColors.secondary,
        permissions: const <String>[AppPermission.examsView],
        builder: (_) => const ExamResult(),
      ),
      _QuickAccessItem(
        title: 'Time Table',
        icon: Icons.calendar_month_outlined,
        color: AppColors.warning,
        permissions: const <String>[AppPermission.timetableView],
        builder: (_) => const TimeTableScreen(),
      ),
      _QuickAccessItem(
        title: 'Library',
        icon: Icons.menu_book_outlined,
        color: const Color(0xFF8B5CF6),
        permissions: const <String>[AppPermission.libraryView],
        builder: (_) => const LibraryScreen(),
      ),
      _QuickAccessItem(
        title: 'Fees',
        icon: Icons.payments_outlined,
        color: const Color(0xFF0EA5E9),
        permissions: const <String>[AppPermission.feesView],
        builder: (_) => const FeesScreen(),
      ),
      _QuickAccessItem(
        title: 'Transport',
        icon: Icons.directions_bus_outlined,
        color: const Color(0xFFF97316),
        permissions: const <String>[AppPermission.transportView],
        builder: (_) => const TransportScreen(),
      ),
      _QuickAccessItem(
        title: 'Apply Leave',
        icon: Icons.event_busy_outlined,
        color: AppColors.danger,
        permissions: const <String>[
          AppPermission.leaveApply,
          AppPermission.leaveView,
        ],
        builder: (_) => const LeaveApply(),
      ),
      _QuickAccessItem(
        title: 'Activities',
        icon: Icons.emoji_events_outlined,
        color: const Color(0xFFEC4899),
        permissions: const <String>[AppPermission.activitiesView],
        builder: (_) => const ActivityScreen(),
      ),
    ].where((_QuickAccessItem item) {
      return state.hasAnyPermission(item.permissions);
    }).toList(growable: false);

    if (items.isEmpty) {
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
        final columns = constraints.maxWidth >= 1000
            ? 5
            : constraints.maxWidth >= 720
                ? 4
                : constraints.maxWidth >= 480
                    ? 3
                    : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columns == 2 ? 0.96 : 1.02,
          ),
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            final item = items[index];
            return FeatureCard(
              title: item.title,
              icon: item.icon,
              color: item.color,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: item.builder,
                ),
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
  final List<String> permissions;
  final WidgetBuilder builder;

  const _QuickAccessItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.permissions,
    required this.builder,
  });
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
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

  const _GreetingCard({
    required this.name,
    required this.roleLabel,
    required this.tenantName,
    required this.academicYearId,
    required this.demoMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        tenantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.88),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (demoMode) const _WhitePill(label: 'Local Demo'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome back, $name',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
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
          const SizedBox(width: 16),
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }
}

class _WhitePill extends StatelessWidget {
  final String label;

  const _WhitePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}
