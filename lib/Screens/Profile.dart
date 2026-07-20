import 'package:flutter/material.dart';

import 'package:school_management/services/session_state.dart';
import 'package:school_management/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  final _rollNo = TextEditingController(text: 'BCM2005');
  final _className = TextEditingController(text: '12');
  final _section = TextEditingController(text: 'B');
  final _dob = TextEditingController(text: '2007-05-14');
  final _address = TextEditingController(text: '123 Park Street, City');

  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final u = SessionState.instance.user;
    _name = TextEditingController(text: u?.displayName ?? 'Student');
    _email = TextEditingController(text: u?.email ?? 'student@cartzlink.com');
    _phone = TextEditingController(text: '+92 300 0000000');
  }

  @override
  void dispose() {
    for (final c in [
      _name, _email, _phone, _rollNo, _className, _section, _dob, _address
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _editing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile saved'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
            onPressed: () => setState(() => _editing = !_editing),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 52, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _name.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Roll No: ${_rollNo.text}',
                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _field('Full Name', _name, Icons.person_outline),
              _field('Email', _email, Icons.mail_outline,
                  type: TextInputType.emailAddress),
              _field('Phone', _phone, Icons.phone_outlined,
                  type: TextInputType.phone),
              Row(
                children: [
                  Expanded(
                      child: _field('Class', _className, Icons.school_outlined)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _field('Section', _section, Icons.group_outlined)),
                ],
              ),
              _field('Date of Birth', _dob, Icons.cake_outlined),
              _field('Address', _address, Icons.home_outlined, maxLines: 2),
              const SizedBox(height: 20),
              if (_editing)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save Changes'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, IconData icon,
      {TextInputType? type, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        enabled: _editing,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Enter $label' : null,
      ),
    );
  }
}
