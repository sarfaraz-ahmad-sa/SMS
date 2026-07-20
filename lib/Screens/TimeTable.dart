import 'package:flutter/material.dart';

import 'package:school_management/theme/app_theme.dart';

class TimeTableScreen extends StatelessWidget {
  const TimeTableScreen({Key? key}) : super(key: key);

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  static const Map<String, List<List<String>>> _schedule = {
    'Mon': [
      ['08:00 - 08:45', 'Mathematics', 'Mr. Khan'],
      ['08:45 - 09:30', 'Physics', 'Ms. Ali'],
      ['09:45 - 10:30', 'English', 'Mr. Ahmed'],
      ['10:30 - 11:15', 'Chemistry', 'Dr. Fatima'],
    ],
    'Tue': [
      ['08:00 - 08:45', 'Biology', 'Ms. Sara'],
      ['08:45 - 09:30', 'Mathematics', 'Mr. Khan'],
      ['09:45 - 10:30', 'Computer', 'Mr. Bilal'],
      ['10:30 - 11:15', 'Urdu', 'Ms. Nadia'],
    ],
    'Wed': [
      ['08:00 - 08:45', 'Physics', 'Ms. Ali'],
      ['08:45 - 09:30', 'English', 'Mr. Ahmed'],
      ['09:45 - 10:30', 'Mathematics', 'Mr. Khan'],
      ['10:30 - 11:15', 'P.E.', 'Coach Omar'],
    ],
    'Thu': [
      ['08:00 - 08:45', 'Chemistry', 'Dr. Fatima'],
      ['08:45 - 09:30', 'Biology', 'Ms. Sara'],
      ['09:45 - 10:30', 'Computer', 'Mr. Bilal'],
      ['10:30 - 11:15', 'English', 'Mr. Ahmed'],
    ],
    'Fri': [
      ['08:00 - 08:45', 'Mathematics', 'Mr. Khan'],
      ['08:45 - 09:30', 'Islamiat', 'Mr. Yusuf'],
      ['09:45 - 10:30', 'Physics', 'Ms. Ali'],
    ],
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _days.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Time Table'),
          bottom: TabBar(
            isScrollable: true,
            tabs: _days.map((d) => Tab(text: d)).toList(),
          ),
        ),
        body: TabBarView(
          children: _days.map((day) {
            final periods = _schedule[day] ?? const [];
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: periods.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final p = periods[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(p[1],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${p[0]}  ·  ${p[2]}'),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
