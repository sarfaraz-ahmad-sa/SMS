import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../jinn_ui.dart';

class OverallAttendanceCard extends StatelessWidget {
  final String date;
  final String day;
  final bool firsthalf;
  final bool secondhalf;

  const OverallAttendanceCard({
    super.key,
    required this.date,
    required this.day,
    required this.firsthalf,
    required this.secondhalf,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '$day $date. Morning ${firsthalf ? 'present' : 'absent'}, '
          'afternoon ${secondhalf ? 'present' : 'absent'}',
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: JinnCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              JinnIconBadge(
                icon: Icons.calendar_today_rounded,
                color: theme.colorScheme.primary,
                background: theme.colorScheme.primaryContainer,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(day, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(date, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              _HalfStatus(label: 'AM', present: firsthalf),
              const SizedBox(width: 8),
              _HalfStatus(label: 'PM', present: secondhalf),
            ],
          ),
        ),
      ),
    );
  }
}

class _HalfStatus extends StatelessWidget {
  final String label;
  final bool present;

  const _HalfStatus({required this.label, required this.present});

  @override
  Widget build(BuildContext context) {
    final color = present ? AppColors.success : AppColors.danger;
    return Tooltip(
      message: '$label: ${present ? 'Present' : 'Absent'}',
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
