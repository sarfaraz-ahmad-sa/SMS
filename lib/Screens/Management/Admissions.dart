import 'package:flutter/material.dart';

import 'package:school_management/theme/app_theme.dart';

class _Application {
  String name;
  String className;
  String guardian;
  String phone;
  String status;
  _Application(this.name, this.className, this.guardian, this.phone,
      {this.status = 'Pending'});
}

class AdmissionsScreen extends StatefulWidget {
  const AdmissionsScreen({Key? key}) : super(key: key);

  @override
  State<AdmissionsScreen> createState() => _AdmissionsScreenState();
}

class _AdmissionsScreenState extends State<AdmissionsScreen> {
  final _apps = <_Application>[
    _Application('Bilal Ahmed', '9', 'Ahmed Khan', '+92 300 1231234',
        status: 'Approved'),
    _Application('Fatima Zahra', '6', 'Zahra Bibi', '+92 301 5675678',
        status: 'Pending'),
  ];

  void _newAdmission() {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final cls = TextEditingController();
    final guardian = TextEditingController();
    final phone = TextEditingController();

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
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Admission Form',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _tf(name, 'Student Name', Icons.person_outline),
                _tf(cls, 'Applying for Class', Icons.school_outlined),
                _tf(guardian, 'Guardian Name', Icons.people_outline),
                _tf(phone, 'Contact Number', Icons.phone_outlined,
                    type: TextInputType.phone),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => _apps.insert(
                          0,
                          _Application(name.text, cls.text, guardian.text,
                              phone.text)));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Admission application submitted'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    child: const Text('Submit Application'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String s) => s == 'Approved'
      ? AppColors.success
      : (s == 'Rejected' ? AppColors.danger : AppColors.warning);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admissions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newAdmission,
        icon: const Icon(Icons.add),
        label: const Text('New Admission'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: _apps.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final a = _apps[i];
          final c = _statusColor(a.status);
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(a.name[0].toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
              ),
              title: Text(a.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Class ${a.className} · ${a.guardian}'),
              trailing: PopupMenuButton<String>(
                onSelected: (v) => setState(() => a.status = v),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(a.status,
                      style: TextStyle(
                          color: c,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'Approved', child: Text('Approve')),
                  PopupMenuItem(value: 'Pending', child: Text('Mark Pending')),
                  PopupMenuItem(value: 'Rejected', child: Text('Reject')),
                ],
              ),
            ),
          );
        },
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
