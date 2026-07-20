import 'package:flutter/material.dart';

import '../Screens/Activity.dart';
import '../Screens/Attendance/Attendance.dart';
import '../Screens/Exam/Exam_Rseult.dart';
import '../Screens/Fees.dart';
import '../Screens/Leave_Apply/LeaveApply.dart';
import '../Screens/Library.dart';
import '../Screens/LoginPage.dart';
import '../Screens/Management/Accounting.dart';
import '../Screens/Management/Admissions.dart';
import '../Screens/Management/Events.dart';
import '../Screens/Management/HR.dart';
import '../Screens/Management/Hostel.dart';
import '../Screens/Management/Inventory.dart';
import '../Screens/Management/StudentManagement.dart';
import '../Screens/Management/TeacherManagement.dart';
import '../Screens/Notifications.dart';
import '../Screens/Profile.dart';
import '../Screens/Reports.dart';
import '../Screens/Settings.dart';
import '../Screens/TimeTable.dart';
import '../Screens/Transport.dart';
import '../Screens/home.dart';
import '../services/Auth_services.dart';
import '../services/models/app_permission.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';
import 'TenantSwitcher.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({Key? key}) : super(key: key);

  void _go(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.pop(context);
    await AuthService().signOut();
    SessionState.instance.clear();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const MyHomePage(title: 'CARTZ Link SMS'),
      ),
      (Route<dynamic> route) => false,
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

        final quickItems = <_DrawerItem>[
          _DrawerItem(
            icon: Icons.home_outlined,
            label: 'Home',
            permission: AppPermission.profileView,
            screen: const Home(),
          ),
          _DrawerItem(
            icon: Icons.person_outline,
            label: 'Profile',
            permission: AppPermission.profileView,
            screen: const ProfileScreen(),
          ),
          _DrawerItem(
            icon: Icons.fact_check_outlined,
            label: 'Attendance',
            permission: AppPermission.attendanceView,
            screen: Attendance(),
          ),
          _DrawerItem(
            icon: Icons.assignment_outlined,
            label: 'Examination',
            permission: AppPermission.examsView,
            screen: ExamResult(),
          ),
          _DrawerItem(
            icon: Icons.calendar_month_outlined,
            label: 'Time Table',
            permission: AppPermission.timetableView,
            screen: const TimeTableScreen(),
          ),
          _DrawerItem(
            icon: Icons.menu_book_outlined,
            label: 'Library',
            permission: AppPermission.libraryView,
            screen: const LibraryScreen(),
          ),
          _DrawerItem(
            icon: Icons.payments_outlined,
            label: 'Fees',
            permission: AppPermission.feesView,
            screen: const FeesScreen(),
          ),
          _DrawerItem(
            icon: Icons.directions_bus_outlined,
            label: 'Transport',
            permission: AppPermission.transportView,
            screen: const TransportScreen(),
          ),
          _DrawerItem(
            icon: Icons.event_busy_outlined,
            label: 'Leave Apply',
            permission: AppPermission.leaveView,
            screen: LeaveApply(),
          ),
          _DrawerItem(
            icon: Icons.emoji_events_outlined,
            label: 'Activities',
            permission: AppPermission.activitiesView,
            screen: const ActivityScreen(),
          ),
          _DrawerItem(
            icon: Icons.notifications_none_rounded,
            label: 'Notifications',
            permission: AppPermission.notificationsView,
            screen: const NotificationsScreen(),
          ),
        ].where((item) => state.hasPermission(item.permission)).toList();

        final managementItems = <_DrawerItem>[
          _DrawerItem(
            icon: Icons.how_to_reg_outlined,
            label: 'Admissions',
            permission: AppPermission.admissionsView,
            screen: const AdmissionsScreen(),
          ),
          _DrawerItem(
            icon: Icons.groups_outlined,
            label: 'Students',
            permission: AppPermission.studentsView,
            screen: const StudentManagementScreen(),
          ),
          _DrawerItem(
            icon: Icons.co_present_outlined,
            label: 'Teachers',
            permission: AppPermission.teachersView,
            screen: const TeacherManagementScreen(),
          ),
          _DrawerItem(
            icon: Icons.badge_outlined,
            label: 'HR & Payroll',
            permission: AppPermission.hrView,
            screen: const HRScreen(),
          ),
          _DrawerItem(
            icon: Icons.account_balance_outlined,
            label: 'Accounting',
            permission: AppPermission.accountingView,
            screen: const AccountingScreen(),
          ),
          _DrawerItem(
            icon: Icons.event_outlined,
            label: 'Events',
            permission: AppPermission.eventsView,
            screen: const EventsScreen(),
          ),
          _DrawerItem(
            icon: Icons.bed_outlined,
            label: 'Hostel',
            permission: AppPermission.hostelView,
            screen: const HostelScreen(),
          ),
          _DrawerItem(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            permission: AppPermission.inventoryView,
            screen: const InventoryScreen(),
          ),
          _DrawerItem(
            icon: Icons.bar_chart_rounded,
            label: 'Reports',
            permission: AppPermission.reportsView,
            screen: const ReportsScreen(),
          ),
        ].where((item) => state.hasPermission(item.permission)).toList();

        return Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 54, 20, 20),
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName?.trim().isNotEmpty == true
                        ? user!.displayName!.trim()
                        : 'User',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tenant?.name ?? 'CARTZ Link SMS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.88)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.roleLabel ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 12,
                    ),
                  ),
                  if (state.canSwitchTenant) ...<Widget>[
                    const SizedBox(height: 12),
                    const TenantSwitcher(),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  ...quickItems.map(
                    (_DrawerItem item) => _tile(
                      context,
                      item.icon,
                      item.label,
                      () => _go(context, item.screen),
                    ),
                  ),
                  if (managementItems.isNotEmpty) ...<Widget>[
                    const Divider(),
                    _section('Management'),
                    ...managementItems.map(
                      (_DrawerItem item) => _tile(
                        context,
                        item.icon,
                        item.label,
                        () => _go(context, item.screen),
                      ),
                    ),
                  ],
                  const Divider(),
                  if (state.hasPermission(AppPermission.settingsView))
                    _tile(
                      context,
                      Icons.settings_outlined,
                      'Settings',
                      () => _go(context, const SettingsScreen()),
                    ),
                  _tile(
                    context,
                    Icons.logout,
                    'Logout',
                    () => _logout(context),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _section(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }
}

class _DrawerItem {
  final IconData icon;
  final String label;
  final String permission;
  final Widget screen;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.permission,
    required this.screen,
  });
}
