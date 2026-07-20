import 'package:flutter/material.dart';

import '../Widgets/FeatureCard.dart';
import '../Widgets/MainDrawer.dart';
import '../Widgets/TenantSwitcher.dart';
import '../services/models/app_permission.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';
import 'Activity.dart';
import 'Attendance/Attendance.dart';
import 'Exam/Exam_Rseult.dart';
import 'Fees.dart';
import 'Leave_Apply/LeaveApply.dart';
import 'Library.dart';
import 'Management/Accounting.dart';
import 'Management/Admissions.dart';
import 'Management/Events.dart';
import 'Management/HR.dart';
import 'Management/Hostel.dart';
import 'Management/Inventory.dart';
import 'Management/StudentManagement.dart';
import 'Management/TeacherManagement.dart';
import 'Notifications.dart';
import 'Profile.dart';
import 'Reports.dart';
import 'TimeTable.dart';
import 'Transport.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

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

        final quickAccess = <_Feature>[
          _Feature(
            title: 'Profile',
            icon: Icons.person_outline,
            color: AppColors.primary,
            permission: AppPermission.profileView,
            builder: (_) => const ProfileScreen(),
          ),
          _Feature(
            title: 'Attendance',
            icon: Icons.fact_check_outlined,
            color: AppColors.success,
            permission: AppPermission.attendanceView,
            builder: (_) => Attendance(),
          ),
          _Feature(
            title: 'Exam Results',
            icon: Icons.assignment_outlined,
            color: AppColors.secondary,
            permission: AppPermission.examsView,
            builder: (_) => ExamResult(),
          ),
          _Feature(
            title: 'Time Table',
            icon: Icons.calendar_month_outlined,
            color: AppColors.warning,
            permission: AppPermission.timetableView,
            builder: (_) => const TimeTableScreen(),
          ),
          _Feature(
            title: 'Library',
            icon: Icons.menu_book_outlined,
            color: const Color(0xFF8B5CF6),
            permission: AppPermission.libraryView,
            builder: (_) => const LibraryScreen(),
          ),
          _Feature(
            title: 'Fees',
            icon: Icons.payments_outlined,
            color: const Color(0xFF0EA5E9),
            permission: AppPermission.feesView,
            builder: (_) => const FeesScreen(),
          ),
          _Feature(
            title: 'Transport',
            icon: Icons.directions_bus_outlined,
            color: const Color(0xFFF97316),
            permission: AppPermission.transportView,
            builder: (_) => const TransportScreen(),
          ),
          _Feature(
            title: 'Apply Leave',
            icon: Icons.event_busy_outlined,
            color: AppColors.danger,
            permission: AppPermission.leaveView,
            builder: (_) => LeaveApply(),
          ),
          _Feature(
            title: 'Activities',
            icon: Icons.emoji_events_outlined,
            color: const Color(0xFFEC4899),
            permission: AppPermission.activitiesView,
            builder: (_) => const ActivityScreen(),
          ),
        ].where((item) => state.hasPermission(item.permission)).toList();

        final management = <_Feature>[
          _Feature(
            title: 'Admissions',
            icon: Icons.how_to_reg_outlined,
            color: const Color(0xFF10B981),
            permission: AppPermission.admissionsView,
            builder: (_) => const AdmissionsScreen(),
          ),
          _Feature(
            title: 'Students',
            icon: Icons.groups_outlined,
            color: AppColors.primary,
            permission: AppPermission.studentsView,
            builder: (_) => const StudentManagementScreen(),
          ),
          _Feature(
            title: 'Teachers',
            icon: Icons.co_present_outlined,
            color: AppColors.accent,
            permission: AppPermission.teachersView,
            builder: (_) => const TeacherManagementScreen(),
          ),
          _Feature(
            title: 'HR & Payroll',
            icon: Icons.badge_outlined,
            color: const Color(0xFF8B5CF6),
            permission: AppPermission.hrView,
            builder: (_) => const HRScreen(),
          ),
          _Feature(
            title: 'Accounting',
            icon: Icons.account_balance_outlined,
            color: const Color(0xFF0EA5E9),
            permission: AppPermission.accountingView,
            builder: (_) => const AccountingScreen(),
          ),
          _Feature(
            title: 'Events',
            icon: Icons.event_outlined,
            color: const Color(0xFFEC4899),
            permission: AppPermission.eventsView,
            builder: (_) => const EventsScreen(),
          ),
          _Feature(
            title: 'Hostel',
            icon: Icons.bed_outlined,
            color: const Color(0xFFF97316),
            permission: AppPermission.hostelView,
            builder: (_) => const HostelScreen(),
          ),
          _Feature(
            title: 'Inventory',
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFF6366F1),
            permission: AppPermission.inventoryView,
            builder: (_) => const InventoryScreen(),
          ),
          _Feature(
            title: 'Reports',
            icon: Icons.bar_chart_rounded,
            color: AppColors.secondary,
            permission: AppPermission.reportsView,
            builder: (_) => const ReportsScreen(),
          ),
        ].where((item) => state.hasPermission(item.permission)).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: <Widget>[
              const TenantSwitcher(compact: true),
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
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: <Widget>[
                  _GreetingCard(
                    name: user.displayName?.trim().isNotEmpty == true
                        ? user.displayName!.trim()
                        : 'User',
                    roleLabel: user.roleLabel,
                    tenantName: tenant.name,
                    planLabel: tenant.subscription.tier.label,
                    academicYearId: state.activeAcademicYearId,
                  ),
                  const SizedBox(height: 20),
                  _ContextStrip(
                    currency: tenant.currency,
                    timezone: tenant.timezone,
                    campusId: state.activeCampusId,
                  ),
                  if (quickAccess.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 24),
                    const _SectionTitle(
                      title: 'Quick Access',
                      subtitle: 'Your daily school tasks',
                    ),
                    const SizedBox(height: 12),
                    _FeatureGrid(items: quickAccess),
                  ],
                  if (management.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 28),
                    const _SectionTitle(
                      title: 'Management',
                      subtitle: 'Authorized administration modules',
                    ),
                    const SizedBox(height: 12),
                    _FeatureGrid(items: management),
                  ],
                  if (quickAccess.isEmpty && management.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: _NoModulesCard(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final List<_Feature> items;

  const _FeatureGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      maxCrossAxisExtent: 180,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1,
      children: items
          .map(
            (_Feature feature) => FeatureCard(
              title: feature.title,
              icon: feature.icon,
              color: feature.color,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => feature.builder(context),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Feature {
  final String title;
  final IconData icon;
  final Color color;
  final String permission;
  final Widget Function(BuildContext) builder;

  const _Feature({
    required this.title,
    required this.icon,
    required this.color,
    required this.permission,
    required this.builder,
  });
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
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
  final String planLabel;
  final String? academicYearId;

  const _GreetingCard({
    required this.name,
    required this.roleLabel,
    required this.tenantName,
    required this.planLabel,
    required this.academicYearId,
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
                Text(
                  tenantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontWeight: FontWeight.w600,
                  ),
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
                    _WhitePill(label: planLabel),
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

class _ContextStrip extends StatelessWidget {
  final String currency;
  final String timezone;
  final String? campusId;

  const _ContextStrip({
    required this.currency,
    required this.timezone,
    required this.campusId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Wrap(
          spacing: 18,
          runSpacing: 10,
          children: <Widget>[
            _ContextItem(icon: Icons.payments_outlined, label: currency),
            _ContextItem(icon: Icons.schedule_outlined, label: timezone),
            _ContextItem(
              icon: Icons.location_city_outlined,
              label: campusId?.isNotEmpty == true
                  ? 'Campus: $campusId'
                  : 'All campuses',
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ContextItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _NoModulesCard extends StatelessWidget {
  const _NoModulesCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          children: <Widget>[
            Icon(Icons.lock_outline_rounded, size: 48),
            SizedBox(height: 12),
            Text(
              'No modules assigned',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 6),
            Text(
              'Ask your school administrator to assign a role or permissions.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
