import 'package:flutter/material.dart';

import '../../Widgets/jinn_ui.dart';
import '../../theme/app_theme.dart';

class TodayAttendance extends StatelessWidget {
  const TodayAttendance({super.key});

  static const List<_ClassAttendance> _classes = <_ClassAttendance>[
    _ClassAttendance('English', 'Mr. Deepak', '09:00 AM', '09:45 AM', true),
    _ClassAttendance('Mathematics', 'Mr. Khan', '09:45 AM', '10:30 AM', true),
    _ClassAttendance('Physics', 'Ms. Ali', '10:45 AM', '11:30 AM', false),
    _ClassAttendance('Computer Science', 'Mr. Bilal', '11:30 AM', '12:15 PM', true),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: _classes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final item = _classes[index];
        return JinnCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              JinnIconBadge(
                icon: item.present ? Icons.check_rounded : Icons.close_rounded,
                color: item.present ? AppColors.success : AppColors.danger,
                background: item.present ? AppColors.pastelGreen : AppColors.pastelRose,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(item.subject, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('${item.teacher}  ·  ${item.start}–${item.end}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              JinnStatusPill(
                label: item.present ? 'Present' : 'Absent',
                color: item.present ? AppColors.success : AppColors.danger,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClassAttendance {
  final String subject;
  final String teacher;
  final String start;
  final String end;
  final bool present;
  const _ClassAttendance(this.subject, this.teacher, this.start, this.end, this.present);
}
