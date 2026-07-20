import 'package:flutter/material.dart';

import 'package:school_management/theme/app_theme.dart';

class Teacher {
  String name;
  String subject;
  String email;
  String phone;
  String qualification;
  Teacher(this.name, this.subject, this.email, this.phone, this.qualification);
}

class TeacherManagementScreen extends StatefulWidget {
  const TeacherManagementScreen({Key? key}) : super(key: key);

  @override
  State<TeacherManagementScreen> createState() =>
      _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {
  final _teachers = <Teacher>[
    Teacher('Mr. Khan', 'Mathematics', 'khan@cartzlink.com', '+92 300 1010101', 'M.Sc Math'),
    Teacher('Ms. Ali', 'Physics', 'ali@cartzlink.com', '+92 301 2020202', 'M.Phil Physics'),
    Teacher('Dr. Fatima', 'Chemistry', 'fatima@cartzlink.com', '+92 302 3030303', 'PhD Chemistry'),
    Teacher('Mr. Ahmed', 'English', 'ahmed@cartzlink.com', '+92 303 4040404', 'M.A English'),
  ];

  String _query = '';

  void _openForm({Teacher? existing, int? index}) {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: existing?.name ?? '');
    final subject = TextEditingController(text: existing?.subject ?? '');
    final email = TextEditingController(text: existing?.email ?? '');
    final phone = TextEditingController(text: existing?.phone ?? '');
    final qual = TextEditingController(text: existing?.qualification ?? '');

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
                Text(existing == null ? 'Add Teacher' : 'Edit Teacher',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _tf(name, 'Full Name', Icons.person_outline),
                _tf(subject, 'Subject', Icons.book_outlined),
                _tf(email, 'Email', Icons.mail_outline,
                    type: TextInputType.emailAddress, isEmail: true),
                _tf(phone, 'Phone', Icons.phone_outlined,
                    type: TextInputType.phone),
                _tf(qual, 'Qualification', Icons.school_outlined),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final t = Teacher(name.text, subject.text, email.text,
                          phone.text, qual.text);
                      setState(() {
                        if (index != null) {
                          _teachers[index] = t;
                        } else {
                          _teachers.add(t);
                        }
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(existing == null
                              ? 'Teacher added'
                              : 'Teacher updated'),
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
    final removed = _teachers[index];
    setState(() => _teachers.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${removed.name} removed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _teachers
        .where((t) =>
            t.name.toLowerCase().contains(_query.toLowerCase()) ||
            t.subject.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Teacher'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search by name or subject',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('${filtered.length} teachers',
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No teachers found'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final t = filtered[i];
                      final realIndex = _teachers.indexOf(t);
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.accent.withOpacity(0.12),
                            child: Text(
                              t.name.replaceAll(RegExp(r'^(Mr\.|Ms\.|Dr\.)\s*'), '').isNotEmpty
                                  ? t.name.replaceAll(RegExp(r'^(Mr\.|Ms\.|Dr\.)\s*'), '')[0].toUpperCase()
                                  : 'T',
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(t.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text('${t.subject} · ${t.qualification}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') {
                                _openForm(existing: t, index: realIndex);
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
      {TextInputType? type, bool isEmail = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Enter $label';
          if (isEmail && !v.contains('@')) return 'Enter a valid email';
          return null;
        },
      ),
    );
  }
}
