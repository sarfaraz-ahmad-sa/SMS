import 'package:flutter/material.dart';

import 'package:school_management/Screens/Management/AddStudent.dart';
import 'package:school_management/services/models/student.dart';
import 'package:school_management/services/student_service.dart';
import 'package:school_management/theme/app_theme.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({Key? key}) : super(key: key);

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final _service = StudentService();
  String _query = '';

  Future<void> _confirmDelete(Student s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete student?'),
        content: Text('Remove ${s.fullName} permanently?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && s.id != null) {
      await _service.deleteStudent(s.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddStudentScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search by name or ID card',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Student>>(
              stream: _service.streamStudents(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return _error(snap.error.toString());
                }
                final all = snap.data ?? [];
                final list = all
                    .where((s) =>
                        s.fullName
                            .toLowerCase()
                            .contains(_query.toLowerCase()) ||
                        s.idCardNumber
                            .toLowerCase()
                            .contains(_query.toLowerCase()))
                    .toList();

                if (list.isEmpty) {
                  return _empty();
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final s = list[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            s.firstName.isNotEmpty
                                ? s.firstName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(s.fullName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'Class ${s.className}-${s.section} · ${s.idCardNumber}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.danger),
                          onPressed: () => _confirmDelete(s),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_off_outlined,
                size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No students yet'),
            const SizedBox(height: 4),
            Text('Tap "Add Student" to create one',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );

  Widget _error(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              const Text('Could not load from Firebase',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(msg,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
      );
}
