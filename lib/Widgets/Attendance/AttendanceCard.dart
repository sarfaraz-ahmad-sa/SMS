import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../jinn_ui.dart';

class AttendanceCard extends StatelessWidget {
  final String starttime;
  final String endtime;
  final String subject;
  final String staff;
  final bool attendance;

  const AttendanceCard({
    super.key,
    required this.starttime,
    required this.endtime,
    required this.subject,
    required this.staff,
    required this.attendance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = attendance ? AppColors.success : AppColors.danger;
    final statusLabel = attendance ? 'Present' : 'Absent';

    return Semantics(
      container: true,
      label: '$subject with $staff, $starttime to $endtime, $statusLabel',
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: JinnCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(starttime, style: theme.textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(endtime, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      staff,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              JinnStatusPill(
                label: statusLabel,
                color: statusColor,
                icon: attendance ? Icons.check_rounded : Icons.close_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
