import 'package:flutter/material.dart';

import 'package:school_management/Screens/Activity.dart';
import 'package:school_management/Screens/Attendance/Attendance.dart';
import 'package:school_management/Screens/Exam/Exam_Rseult.dart';
import 'package:school_management/Screens/Fees.dart';
import 'package:school_management/Screens/Leave_Apply/LeaveApply.dart';
import 'package:school_management/Screens/Library.dart';
import 'package:school_management/Screens/LoginPage.dart';
import 'package:school_management/Screens/Management/Accounting.dart';
import 'package:school_management/Screens/Management/Admissions.dart';
import 'package:school_management/Screens/Management/Events.dart';
import 'package:school_management/Screens/Management/HR.dart';
import 'package:school_management/Screens/Management/Hostel.dart';
import 'package:school_management/Screens/Management/Inventory.dart';
import 'package:school_management/Screens/Management/StudentManagement.dart';
import 'package:school_management/Screens/Management/TeacherManagement.dart';
import 'package:school_management/Screens/Notifications.dart';
import 'package:school_management/Screens/Profile.dart';
import 'package:school_management/Screens/Reports.dart';
import 'package:school_management/Screens/Settings.dart';
import 'package:school_management/Screens/TimeTable.dart';
import 'package:school_management/Screens/Transport.dart';
import 'package:school_management/Screens/home.dart';
import 'package:school_management/services/session_state.dart';
import 'package:school_management/theme/app_theme.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({Key? key}) : super(key: key);

  void _go(BuildContext context, Widget screen) {
    Navigator.pop(context); // close drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final name = SessionState.instance.user?.displayName ?? 'Student';
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 12),
              Text(name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text('CARTZ Link SMS',
                  style: TextStyle(color: Colors.white.withOpacity(0.85))),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _tile(context, Icons.home_outlined, 'Home',
                  () => _go(context, const Home())),
              _tile(context, Icons.person_outline, 'Profile',
                  () => _go(context, const ProfileScreen())),
              _tile(context, Icons.fact_check_outlined, 'Attendance',
                  () => _go(context, Attendance())),
              _tile(context, Icons.assignment_outlined, 'Examination',
                  () => _go(context, ExamResult())),
              _tile(context, Icons.calendar_month_outlined, 'Time Table',
                  () => _go(context, const TimeTableScreen())),
              _tile(context, Icons.menu_book_outlined, 'Library',
                  () => _go(context, const LibraryScreen())),
              _tile(context, Icons.payments_outlined, 'Fees',
                  () => _go(context, const FeesScreen())),
              _tile(context, Icons.directions_bus_outlined, 'Transport',
                  () => _go(context, const TransportScreen())),
              _tile(context, Icons.event_busy_outlined, 'Leave Apply',
                  () => _go(context, LeaveApply())),
              _tile(context, Icons.emoji_events_outlined, 'Activities',
                  () => _go(context, const ActivityScreen())),
              _tile(context, Icons.notifications_none_rounded, 'Notifications',
                  () => _go(context, const NotificationsScreen())),
              const Divider(),
              _section('Management'),
              _tile(context, Icons.how_to_reg_outlined, 'Admissions',
                  () => _go(context, const AdmissionsScreen())),
              _tile(context, Icons.groups_outlined, 'Students',
                  () => _go(context, const StudentManagementScreen())),
              _tile(context, Icons.co_present_outlined, 'Teachers',
                  () => _go(context, const TeacherManagementScreen())),
              _tile(context, Icons.badge_outlined, 'HR & Payroll',
                  () => _go(context, const HRScreen())),
              _tile(context, Icons.account_balance_outlined, 'Accounting',
                  () => _go(context, const AccountingScreen())),
              _tile(context, Icons.event_outlined, 'Events',
                  () => _go(context, const EventsScreen())),
              _tile(context, Icons.bed_outlined, 'Hostel',
                  () => _go(context, const HostelScreen())),
              _tile(context, Icons.inventory_2_outlined, 'Inventory',
                  () => _go(context, const InventoryScreen())),
              _tile(context, Icons.bar_chart_rounded, 'Reports',
                  () => _go(context, const ReportsScreen())),
              const Divider(),
              _tile(context, Icons.settings_outlined, 'Settings',
                  () => _go(context, const SettingsScreen())),
              _tile(context, Icons.logout, 'Logout', () {
                SessionState.instance.clear();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MyHomePage(title: 'CARTZ Link SMS')),
                  (route) => false,
                );
              }),
            ],
          ),
        ),
      ],
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
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}
