import 'package:flutter/material.dart';

import '../../Widgets/Exams/SubjectCard.dart';
import '../../theme/app_theme.dart';

class ExamResult extends StatefulWidget {
  const ExamResult({Key? key}) : super(key: key);

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

  static const List<Map<String, String>> _subjects =
      <Map<String, String>>[
    <String, String>{
      'name': 'English',
      'chapters': '1-8',
      'date': '12/03/2026',
      'time': '09:00 AM – 11:00 AM',
      'mark': '88/100',
      'grade': 'A',
    },
    <String, String>{
      'name': 'Mathematics',
      'chapters': '1-10',
      'date': '14/03/2026',
      'time': '09:00 AM – 11:00 AM',
      'mark': '94/100',
      'grade': 'A+',
    },
    <String, String>{
      'name': 'Science',
      'chapters': '1-7',
      'date': '16/03/2026',
      'time': '09:00 AM – 11:00 AM',
      'mark': '91/100',
      'grade': 'A+',
    },
    <String, String>{
      'name': 'Pakistan Studies',
      'chapters': '1-6',
      'date': '18/03/2026',
      'time': '09:00 AM – 11:00 AM',
      'mark': '87/100',
      'grade': 'A',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Results')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              DropdownButtonFormField<String>(
                value: _selectedExam,
                decoration: const InputDecoration(
                  labelText: 'Examination',
                  prefixIcon: Icon(Icons.assignment_outlined),
                ),
                items: _exams
                    .map(
                      (String exam) => DropdownMenuItem<String>(
                        value: exam,
                        child: Text(exam),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  if (value != null) setState(() => _selectedExam = value);
                },
              ),
              const SizedBox(height: 18),
              const _ResultSummary(),
              const SizedBox(height: 20),
              const Text(
                'Subject Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._subjects.map(
                (Map<String, String> subject) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SubjectCard(
                    subjectname: subject['name']!,
                    chapter: subject['chapters']!,
                    date: subject['date']!,
                    time: subject['time']!,
                    grade: subject['grade']!,
                    mark: subject['mark']!,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report card download will use the document API.'),
                      ),
                    ),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Download Report Card'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Result sharing link prepared.'),
                      ),
                    ),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Wrap(
        spacing: 28,
        runSpacing: 18,
        alignment: WrapAlignment.spaceAround,
        children: <Widget>[
          _SummaryItem(label: 'Total', value: '360 / 400'),
          _SummaryItem(label: 'Percentage', value: '90%'),
          _SummaryItem(label: 'Grade', value: 'A+'),
          _SummaryItem(label: 'Result', value: 'Pass'),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
