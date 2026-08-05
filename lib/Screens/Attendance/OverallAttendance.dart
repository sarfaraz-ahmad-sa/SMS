import 'package:flutter/material.dart';

import '../../Widgets/jinn_ui.dart';
import '../../theme/app_theme.dart';

class OverallAttendance extends StatelessWidget {
  const OverallAttendance({super.key});

  static const List<_DayAttendance> _days = <_DayAttendance>[
    _DayAttendance('23 May 2026', 'Saturday', 'Present'),
    _DayAttendance('22 May 2026', 'Friday', 'Present'),
    _DayAttendance('21 May 2026', 'Thursday', 'Late'),
    _DayAttendance('20 May 2026', 'Wednesday', 'Present'),
    _DayAttendance('19 May 2026', 'Tuesday', 'Absent'),
    _DayAttendance('18 May 2026', 'Monday', 'Present'),
    _DayAttendance('16 May 2026', 'Saturday', 'Present'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: _days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 9),
      itemBuilder: (BuildContext context, int index) {
        final item = _days[index];
        final color = item.status == 'Present'
            ? AppColors.success
            : item.status == 'Late'
                ? AppColors.warning
                : AppColors.danger;
        return JinnCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: <Widget>[
              JinnIconBadge(
                icon: Icons.calendar_today_rounded,
                color: AppColors.primary,
                background: AppColors.pastelBlue,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(item.date, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(item.day, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              JinnStatusPill(label: item.status, color: color),
            ],
          ),
        );
      },
    );
  }
}

class _DayAttendance {
  final String date;
  final String day;
  final String status;
  const _DayAttendance(this.date, this.day, this.status);
}
