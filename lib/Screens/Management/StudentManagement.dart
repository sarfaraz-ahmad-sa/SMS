import 'package:flutter/material.dart';

import 'package:school_management/theme/app_theme.dart';

class Student {
  String name;
  String rollNo;
  String className;
  String section;
  String guardian;
  String phone;
  Student(this.name, this.rollNo, this.className, this.section, this.guardian,
      this.phone);
}

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({Key? key}) : super(key: key);

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final _students = <Student>[
    Student('Ahmed Raza', 'BCM2005', '12', 'B', 'Raza Khan', '+92 300 1112222'),
    Student('Sara Ali', 'BCM2006', '12', 'A', 'Imran Ali', '+92 301 3334444'),
    Student('Hassan Iqbal', 'BCM1998', '11', 'C', 'Iqbal Sheikh', '+92 302 5556666'),
    Student('Ayesha Noor', 'BCM2011', '10', 'B', 'Noor Ahmed', '+92 303 7778888'),
  ];

  String _query = '';

  void _openForm({Student? existing, int? index}) {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: existing?.name ?? '');
    final roll = TextEditingController(text: existing?.rollNo ?? '');
    final cls = TextEditingController(text: existing?.className ?? '');
    final sec = TextEditingController(text: existing?.section ?? '');
    final guardian = TextEditingController(text: existing?.guardian ?? '');
    final phone = TextEditingController(text: existing?.phone ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing == null ? 'Add Student' : 'Edit Student',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _tf(name, 'Full Name', Icons.person_outline),
                _tf(roll, 'Roll No', Icons.badge_outlined),
                Row(children: [
                  Expanded(child: _tf(cls, 'Class', Icons.school_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _tf(sec, 'Section', Icons.group_outlined)),
                ]),
                _tf(guardian, 'Guardian', Icons.people_outline),
                _tf(phone, 'Phone', Icons.phone_outlined,
                    type: TextInputType.phone),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final s = Student(name.text, roll.text, cls.text,
                          sec.text, guardian.text, phone.text);
                      setState(() {
                        if (index != null) {
                          _students[index] = s;
                        } else {
                          _students.add(s);
                        }
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(existing == null
                              ? 'Student added'
                              : 'Student updated'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child: Text(existing == null ? 'Add' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _delete(int index) {
    final removed = _students[index];
    setState(() => _students.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${removed.name} removed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _students
        .where((s) =>
            s.name.toLowerCase().contains(_query.toLowerCase()) ||
            s.rollNo.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Student Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
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
                hintText: 'Search by name or roll no',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${filtered.length} students',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No students found'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final s = filtered[i];
                      final realIndex = _students.indexOf(s);
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(s.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'Roll ${s.rollNo} · Class ${s.className}-${s.section}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') {
                                _openForm(existing: s, index: realIndex);
                              } else if (v == 'delete') {
                                _delete(realIndex);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                  value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tf(TextEditingController c, String label, IconData icon,
      {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Enter $label' : null,
      ),
    );
  }
}
