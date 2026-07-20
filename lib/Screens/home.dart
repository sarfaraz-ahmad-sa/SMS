import 'package:flutter/material.dart';

import 'package:school_management/Widgets/FeatureCard.dart';
import 'package:school_management/Widgets/MainDrawer.dart';
import 'package:school_management/services/session_state.dart';
import 'package:school_management/services/models/user_role.dart';
import 'package:school_management/theme/app_theme.dart';

import 'Attendance/Attendance.dart';
import 'Exam/Exam_Rseult.dart';
import 'Leave_Apply/LeaveApply.dart';
import 'Activity.dart';
import 'Fees.dart';
import 'Library.dart';
import 'Notifications.dart';
import 'Profile.dart';
import 'Reports.dart';
import 'TimeTable.dart';
import 'Transport.dart';
import 'Management/StudentManagement.dart';
import 'Management/TeacherManagement.dart';
import 'Management/Admissions.dart';
import 'Management/HR.dart';
import 'Management/Accounting.dart';
import 'Management/Events.dart';
import 'Management/Hostel.dart';
import 'Management/Inventory.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = SessionState.instance.user;
    final name = user?.displayName ?? 'Student';
    final roleLabel = user?.role.label ?? 'Student';

    final features = <_Feature>[
      _Feature('Profile', Icons.person_outline, AppColors.primary,
          (c) => const ProfileScreen()),
      _Feature('Attendance', Icons.fact_check_outlined, AppColors.success,
          (c) => Attendance()),
      _Feature('Exam Results', Icons.assignment_outlined, AppColors.secondary,
          (c) => ExamResult()),
      _Feature('Time Table', Icons.calendar_month_outlined, AppColors.warning,
          (c) => const TimeTableScreen()),
      _Feature('Library', Icons.menu_book_outlined, const Color(0xFF8B5CF6),
          (c) => const LibraryScreen()),
      _Feature('Fees', Icons.payments_outlined, const Color(0xFF0EA5E9),
          (c) => const FeesScreen()),
      _Feature('Transport', Icons.directions_bus_outlined,
          const Color(0xFFF97316), (c) => const TransportScreen()),
      _Feature('Apply Leave', Icons.event_busy_outlined, AppColors.danger,
          (c) => LeaveApply()),
      _Feature('Activities', Icons.emoji_events_outlined,
          const Color(0xFFEC4899), (c) => const ActivityScreen()),
    ];

    final management = <_Feature>[
      _Feature('Admissions', Icons.how_to_reg_outlined, const Color(0xFF10B981),
          (c) => const AdmissionsScreen()),
      _Feature('Students', Icons.groups_outlined, AppColors.primary,
          (c) => const StudentManagementScreen()),
      _Feature('Teachers', Icons.co_present_outlined, AppColors.accent,
          (c) => const TeacherManagementScreen()),
      _Feature('HR & Payroll', Icons.badge_outlined, const Color(0xFF8B5CF6),
          (c) => const HRScreen()),
      _Feature('Accounting', Icons.account_balance_outlined,
          const Color(0xFF0EA5E9), (c) => const AccountingScreen()),
      _Feature('Events', Icons.event_outlined, const Color(0xFFEC4899),
          (c) => const EventsScreen()),
      _Feature('Hostel', Icons.bed_outlined, const Color(0xFFF97316),
          (c) => const HostelScreen()),
      _Feature('Inventory', Icons.inventory_2_outlined,
          const Color(0xFF6366F1), (c) => const InventoryScreen()),
      _Feature('Reports', Icons.bar_chart_rounded, AppColors.secondary,
          (c) => const ReportsScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
      ),
      drawer: const Drawer(child: MainDrawer()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _GreetingCard(name: name, roleLabel: roleLabel),
          const SizedBox(height: 20),
          const Text(
            'Quick Access',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.92,
            children: features.map(_buildCard(context)).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Management',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.92,
            children: management.map(_buildCard(context)).toList(),
          ),
        ],
      ),
    );
  }

  Widget Function(_Feature) _buildCard(BuildContext context) {
    return (f) => FeatureCard(
          title: f.title,
          icon: f.icon,
          color: f.color,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => f.builder(c)),
          ),
        );
  }
}

class _Feature {
  final String title;
  final IconData icon;
  final Color color;
  final Widget Function(BuildContext) builder;
  _Feature(this.title, this.icon, this.color, this.builder);
}

class _GreetingCard extends StatelessWidget {
  final String name;
  final String roleLabel;
  const _GreetingCard(
      {required this.name, required this.roleLabel, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(color: Colors.white.withOpacity(0.85)),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  roleLabel,
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 34),
          ),
        ],
      ),
    );
  }
}
