import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../jinn_ui.dart';

class LeaveHistoryCard extends StatelessWidget {
  final String status;
  final String adate;
  final String startdate;
  final String enddate;
  final String reason;

  const LeaveHistoryCard({
    super.key,
    required this.status,
    required this.adate,
    required this.startdate,
    required this.enddate,
    required this.reason,
  });

  Color _statusColor() {
    switch (status.trim().toLowerCase()) {
      case 'approved':
      case 'accepted':
        return AppColors.success;
      case 'rejected':
      case 'declined':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor();
    return Semantics(
      container: true,
      label: 'Leave $status, $startdate to $enddate. $reason',
      child: JinnCard(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                JinnStatusPill(
                  label: status,
                  color: statusColor,
                  icon: statusColor == AppColors.success
                      ? Icons.check_circle_outline_rounded
                      : statusColor == AppColors.danger
                          ? Icons.cancel_outlined
                          : Icons.schedule_rounded,
                ),
                const Spacer(),
                Icon(Icons.history_rounded, size: 15, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Applied $adate',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Icon(Icons.date_range_rounded, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$startdate – $enddate',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(reason, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
