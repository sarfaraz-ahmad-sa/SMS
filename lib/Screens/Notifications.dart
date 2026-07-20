import 'package:flutter/material.dart';

import 'package:school_management/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  static const _items = [
    ['Fee reminder', 'Monthly fee is due by the 10th.', '2h ago', Icons.payments_outlined],
    ['Exam schedule', 'Mid-term exams start May 5th.', '1d ago', Icons.assignment_outlined],
    ['Holiday notice', 'School closed on Friday for a public holiday.', '2d ago', Icons.event_outlined],
    ['PTM', 'Parent-teacher meeting on Saturday 10 AM.', '3d ago', Icons.groups_outlined],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final n = _items[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.secondary.withOpacity(0.12),
              child: Icon(n[3] as IconData, color: AppColors.secondary),
            ),
            title: Text(n[0] as String,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(n[1] as String),
            trailing: Text(n[2] as String,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          );
        },
      ),
    );
  }
}
