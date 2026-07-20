import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SubjectCard extends StatelessWidget {
  final String subjectname;
  final String chapter;
  final String date;
  final String time;
  final String grade;
  final String mark;

  const SubjectCard({
    Key? key,
    required this.subjectname,
    required this.chapter,
    required this.date,
    required this.time,
    required this.grade,
    required this.mark,
  }) : super(key: key);

  Color get _accentColors {
    const colors = <Color>[
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.warning,
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
    ];
    final index = subjectname.codeUnits.fold<int>(0, (a, b) => a + b) %
        colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColors;
    return Card(
      elevation: 0,
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 18,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  children: <Widget>[
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 150),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            subjectname,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$chapter chapters',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(date, style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          time,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Marks: $mark  •  Grade: $grade',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
