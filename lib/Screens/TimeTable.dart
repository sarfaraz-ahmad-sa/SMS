import 'package:flutter/material.dart';

import '../Widgets/jinn_ui.dart';
import '../Widgets/saas_scaffold.dart';
import '../theme/app_theme.dart';

class TimeTableScreen extends StatelessWidget {
  const TimeTableScreen({super.key});

  static const List<String> _days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  static const Map<String, List<_Period>> _schedule = <String, List<_Period>>{
    'Mon': <_Period>[
      _Period('08:00–08:45', 'Mathematics', 'Mr. Khan', 'Room 12'),
      _Period('08:45–09:30', 'Physics', 'Ms. Ali', 'Lab 2'),
      _Period('09:45–10:30', 'English', 'Mr. Ahmed', 'Room 12'),
      _Period('10:30–11:15', 'Chemistry', 'Dr. Fatima', 'Lab 1'),
    ],
    'Tue': <_Period>[
      _Period('08:00–08:45', 'Biology', 'Ms. Sara', 'Lab 3'),
      _Period('08:45–09:30', 'Mathematics', 'Mr. Khan', 'Room 12'),
      _Period('09:45–10:30', 'Computer', 'Mr. Bilal', 'IT Lab'),
      _Period('10:30–11:15', 'Urdu', 'Ms. Nadia', 'Room 12'),
    ],
    'Wed': <_Period>[
      _Period('08:00–08:45', 'Physics', 'Ms. Ali', 'Lab 2'),
      _Period('08:45–09:30', 'English', 'Mr. Ahmed', 'Room 12'),
      _Period('09:45–10:30', 'Mathematics', 'Mr. Khan', 'Room 12'),
      _Period('10:30–11:15', 'Physical Education', 'Coach Omar', 'Ground'),
    ],
    'Thu': <_Period>[
      _Period('08:00–08:45', 'Chemistry', 'Dr. Fatima', 'Lab 1'),
      _Period('08:45–09:30', 'Biology', 'Ms. Sara', 'Lab 3'),
      _Period('09:45–10:30', 'Computer', 'Mr. Bilal', 'IT Lab'),
      _Period('10:30–11:15', 'English', 'Mr. Ahmed', 'Room 12'),
    ],
    'Fri': <_Period>[
      _Period('08:00–08:45', 'Mathematics', 'Mr. Khan', 'Room 12'),
      _Period('08:45–09:30', 'Islamiat', 'Mr. Yusuf', 'Room 12'),
      _Period('09:45–10:30', 'Physics', 'Ms. Ali', 'Lab 2'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _days.length,
      child: SaasScaffold(
        title: 'Time Table',
        activeRoute: '/modules',
        activeModuleId: 'timetable',
        body: JinnPage(
          maxWidth: 1120,
          scrollable: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const JinnSectionHeader(
                title: 'Weekly Schedule',
                subtitle: 'Class timings, subjects, teachers and rooms.',
              ),
              const SizedBox(height: 14),
              JinnCard(
                padding: const EdgeInsets.all(6),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.navigation,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: _days.map((String day) => Tab(text: day)).toList(growable: false),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: _days.map((String day) => _DaySchedule(periods: _schedule[day] ?? const <_Period>[])).toList(growable: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaySchedule extends StatelessWidget {
  final List<_Period> periods;
  const _DaySchedule({required this.periods});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: periods.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final period = periods[index];
        final tones = <List<Color>>[
          <Color>[AppColors.pastelBlue, const Color(0xFF4E68D8)],
          <Color>[AppColors.pastelCyan, const Color(0xFF22949A)],
          <Color>[AppColors.pastelGold, const Color(0xFFD89614)],
          <Color>[AppColors.pastelPurple, const Color(0xFF7B5DC7)],
        ];
        final tone = tones[index % tones.length];
        return JinnCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              JinnIconBadge(
                icon: Icons.menu_book_rounded,
                color: tone[1],
                background: tone[0],
                size: 48,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(period.subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${period.time}  ·  ${period.teacher}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              JinnStatusPill(label: period.room, color: AppColors.primary),
            ],
          ),
        );
      },
    );
  }
}

class _Period {
  final String time;
  final String subject;
  final String teacher;
  final String room;
  const _Period(this.time, this.subject, this.teacher, this.room);
}
