import 'package:flutter/material.dart';

import '../Widgets/jinn_ui.dart';
import '../Widgets/saas_scaffold.dart';
import '../theme/app_theme.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  static const List<_ActivityItem> _activities = <_ActivityItem>[
    _ActivityItem('Annual Sports Day', '25 Apr 2026', 'Sports', Icons.sports_soccer_rounded, AppColors.pastelGold, Color(0xFFD89614)),
    _ActivityItem('Science Exhibition', '02 May 2026', 'Academic', Icons.science_rounded, AppColors.pastelCyan, Color(0xFF22949A)),
    _ActivityItem('Debate Competition', '10 May 2026', 'Co-curricular', Icons.record_voice_over_rounded, AppColors.pastelRose, Color(0xFFE05D65)),
    _ActivityItem('Art & Craft Fair', '18 May 2026', 'Creative', Icons.palette_rounded, AppColors.pastelPurple, Color(0xFF7B5DC7)),
    _ActivityItem('Music Concert', '24 May 2026', 'Creative', Icons.music_note_rounded, AppColors.pastelBlue, Color(0xFF4E68D8)),
  ];

  @override
  Widget build(BuildContext context) {
    return SaasScaffold(
      title: 'Activities',
      activeRoute: '/modules',
      activeModuleId: 'events',
      body: JinnPage(
        maxWidth: 1180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const JinnSectionHeader(
              title: 'School Activities',
              subtitle: 'Discover academic, sports and co-curricular events.',
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final compact = constraints.maxWidth < 680;
                final cards = _activities
                    .map((item) => _ActivityCard(
                          item: item,
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Registered interest in ${item.title}')),
                          ),
                        ))
                    .toList(growable: false);
                if (compact) {
                  return Column(
                    children: cards
                        .map((card) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: card,
                            ))
                        .toList(growable: false),
                  );
                }
                return JinnResponsiveGrid(
                  minItemWidth: 330,
                  children: cards,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final _ActivityItem item;
  final VoidCallback onTap;

  const _ActivityCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return JinnCard(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      child: Row(
        children: <Widget>[
          JinnIconBadge(
            icon: item.icon,
            color: item.foreground,
            background: item.background,
            size: 50,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Row(
                  children: <Widget>[
                    JinnStatusPill(label: item.category, color: item.foreground),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(item.date, style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final String title;
  final String date;
  final String category;
  final IconData icon;
  final Color background;
  final Color foreground;

  const _ActivityItem(this.title, this.date, this.category, this.icon, this.background, this.foreground);
}
