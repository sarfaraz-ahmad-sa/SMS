import 'package:flutter/material.dart';

import 'package:school_management/theme/app_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: const [
              _StatCard('Total Students', '1,248', Icons.groups_outlined,
                  AppColors.primary),
              _StatCard('Total Teachers', '86', Icons.co_present_outlined,
                  AppColors.accent),
              _StatCard('Avg. Attendance', '92%', Icons.fact_check_outlined,
                  AppColors.success),
              _StatCard('Exam Pass Rate', '88%', Icons.assignment_turned_in_outlined,
                  AppColors.secondary),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Fees Collection',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const _ProgressRow('Collected', 0.78, AppColors.success,
              'Rs. 9.36M of Rs. 12M'),
          const SizedBox(height: 12),
          const _ProgressRow('Pending', 0.22, AppColors.warning,
              'Rs. 2.64M outstanding'),
          const SizedBox(height: 24),
          const Text('Attendance by Class',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const _ProgressRow('Class 10', 0.94, AppColors.primary, '94%'),
          const SizedBox(height: 10),
          const _ProgressRow('Class 11', 0.90, AppColors.primary, '90%'),
          const SizedBox(height: 10),
          const _ProgressRow('Class 12', 0.91, AppColors.primary, '91%'),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.download_outlined,
                  color: AppColors.primary),
              title: const Text('Export full report (PDF)',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Generate a printable summary'),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report export coming soon')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 26),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String caption;
  const _ProgressRow(this.label, this.value, this.color, this.caption,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(caption,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 10,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
