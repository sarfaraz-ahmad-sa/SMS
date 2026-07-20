import 'package:flutter/material.dart';

import 'package:school_management/theme/app_theme.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  static const _activities = [
    ['Annual Sports Day', 'Apr 25, 2026', 'Sports', Icons.sports_soccer],
    ['Science Exhibition', 'May 02, 2026', 'Academic', Icons.science_outlined],
    ['Debate Competition', 'May 10, 2026', 'Co-curricular', Icons.record_voice_over_outlined],
    ['Art & Craft Fair', 'May 18, 2026', 'Creative', Icons.brush_outlined],
    ['Music Concert', 'May 24, 2026', 'Creative', Icons.music_note_outlined],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activities')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _activities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final a = _activities[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Icon(a[3] as IconData, color: AppColors.primary),
              ),
              title: Text(a[0] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${a[2]}  ·  ${a[1]}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Registered interest in ${a[0]}')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
