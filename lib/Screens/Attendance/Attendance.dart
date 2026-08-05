import 'package:flutter/material.dart';

import '../../Widgets/jinn_ui.dart';
import '../../Widgets/saas_scaffold.dart';
import '../../theme/app_theme.dart';
import 'OverallAttendance.dart';
import 'TodayAttendance.dart';

class Attendance extends StatelessWidget {
  const Attendance({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SaasScaffold(
        title: 'Attendance',
        activeRoute: '/modules',
        activeModuleId: 'attendance',
        body: JinnPage(
          maxWidth: 1180,
          scrollable: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _AttendanceSummary(),
              const SizedBox(height: 16),
              JinnCard(
                padding: const EdgeInsets.all(6),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.navigation,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const <Widget>[
                    Tab(text: 'Today'),
                    Tab(text: 'Overall'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Expanded(
                child: TabBarView(
                  children: <Widget>[
                    TodayAttendance(),
                    OverallAttendance(),
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

class _AttendanceSummary extends StatelessWidget {
  const _AttendanceSummary();

  @override
  Widget build(BuildContext context) {
    return JinnResponsiveGrid(
      minItemWidth: 170,
      childAspectRatio: 2.4,
      children: const <Widget>[
        _SummaryTile('Present', '22', Icons.check_circle_rounded, AppColors.pastelGreen, Color(0xFF27936B)),
        _SummaryTile('Absent', '2', Icons.cancel_rounded, AppColors.pastelRose, Color(0xFFE05D65)),
        _SummaryTile('Late', '1', Icons.schedule_rounded, AppColors.pastelGold, Color(0xFFD89614)),
        _SummaryTile('Attendance', '91.6%', Icons.donut_large_rounded, AppColors.pastelBlue, Color(0xFF4E68D8)),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color background;
  final Color foreground;

  const _SummaryTile(this.label, this.value, this.icon, this.background, this.foreground);

  @override
  Widget build(BuildContext context) {
    return JinnCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          JinnIconBadge(icon: icon, color: foreground, background: background, size: 42),
          const SizedBox(width: 11),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
