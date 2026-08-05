import 'package:flutter/material.dart';

import '../../Widgets/jinn_ui.dart';
import '../../Widgets/saas_scaffold.dart';
import '../../theme/app_theme.dart';

class ExamResult extends StatefulWidget {
  const ExamResult({super.key});

  @override
  State<ExamResult> createState() => _ExamResultState();
}

class _ExamResultState extends State<ExamResult> {
  String _selectedExam = 'Annual Examination 2026';

  static const List<String> _exams = <String>[
    'Annual Examination 2026',
    'Mid Term Examination 2026',
    'First Term Examination 2026',
  ];

  static const List<_SubjectResult> _subjects = <_SubjectResult>[
    _SubjectResult('English', '88', '100', 'A', 0.88, AppColors.pastelRose, Color(0xFFE05D65)),
    _SubjectResult('Mathematics', '94', '100', 'A+', 0.94, AppColors.pastelBlue, Color(0xFF4E68D8)),
    _SubjectResult('Science', '91', '100', 'A+', 0.91, AppColors.pastelCyan, Color(0xFF22949A)),
    _SubjectResult('Pakistan Studies', '87', '100', 'A', 0.87, AppColors.pastelGold, Color(0xFFD89614)),
  ];

  @override
  Widget build(BuildContext context) {
    return SaasScaffold(
      title: 'Exam Results',
      activeRoute: '/modules',
      activeModuleId: 'examinations',
      actions: <Widget>[
        IconButton(
          tooltip: 'Download report card',
          onPressed: _showDownloadMessage,
          icon: const Icon(Icons.download_outlined),
        ),
      ],
      body: JinnPage(
        maxWidth: 1180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final compact = constraints.maxWidth < 760;
                final selector = DropdownButtonFormField<String>(
                  value: _selectedExam,
                  decoration: const InputDecoration(labelText: 'Examination', prefixIcon: Icon(Icons.assignment_outlined)),
                  items: _exams.map((String exam) => DropdownMenuItem<String>(value: exam, child: Text(exam))).toList(growable: false),
                  onChanged: (String? value) {
                    if (value != null) setState(() => _selectedExam = value);
                  },
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const JinnSectionHeader(title: 'Academic Performance', subtitle: 'Subject-wise marks and final grade.'),
                      const SizedBox(height: 14),
                      selector,
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    const Expanded(child: JinnSectionHeader(title: 'Academic Performance', subtitle: 'Subject-wise marks and final grade.')),
                    const SizedBox(width: 18),
                    SizedBox(width: 330, child: selector),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const _ResultSummary(),
            const SizedBox(height: 18),
            const JinnSectionHeader(title: 'Subject Results', subtitle: 'Detailed marks for the selected examination.'),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final compact = constraints.maxWidth < 720;
                final cards = _subjects.map(( _SubjectResult item) => _SubjectResultCard(item: item)).toList(growable: false);
                if (compact) {
                  return Column(
                    children: cards.map((Widget card) => Padding(padding: const EdgeInsets.only(bottom: 10), child: card)).toList(growable: false),
                  );
                }
                return JinnResponsiveGrid(minItemWidth: 350, children: cards);
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.icon(onPressed: _showDownloadMessage, icon: const Icon(Icons.download_rounded, size: 18), label: const Text('Download Report Card')),
                OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Result sharing link prepared.'))),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Share Result'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloadMessage() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report card download will use the document API.')));
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary();

  @override
  Widget build(BuildContext context) {
    return JinnCard(
      color: AppColors.navigation,
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final compact = constraints.maxWidth < 560;
          const items = <Widget>[
            _SummaryItem('Total', '360 / 400', Icons.functions_rounded),
            _SummaryItem('Percentage', '90%', Icons.percent_rounded),
            _SummaryItem('Grade', 'A+', Icons.workspace_premium_rounded),
            _SummaryItem('Result', 'Passed', Icons.verified_rounded),
          ];
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: compact ? 2 : 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: compact ? 2.05 : 1.75,
            children: items,
          );
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _SummaryItem(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: const Color(0xFF91E3BF), size: 20),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Color(0xFFD9E2EA), fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _SubjectResultCard extends StatelessWidget {
  final _SubjectResult item;
  const _SubjectResultCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return JinnCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              JinnIconBadge(icon: Icons.menu_book_rounded, color: item.foreground, background: item.background, size: 46),
              const SizedBox(width: 11),
              Expanded(child: Text(item.subject, style: const TextStyle(fontWeight: FontWeight.w800))),
              JinnStatusPill(label: item.grade, color: item.foreground),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Text(item.obtained, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              Text(' / ${item.total}', style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              Text('${(item.progress * 100).round()}%', style: TextStyle(color: item.foreground, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 7,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(item.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectResult {
  final String subject;
  final String obtained;
  final String total;
  final String grade;
  final double progress;
  final Color background;
  final Color foreground;
  const _SubjectResult(this.subject, this.obtained, this.total, this.grade, this.progress, this.background, this.foreground);
}
