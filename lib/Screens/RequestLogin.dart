import 'package:flutter/material.dart';

import '../services/access_request_service.dart';
import '../theme/app_theme.dart';

class RequestLogin extends StatefulWidget {
  const RequestLogin({Key? key}) : super(key: key);

  @override
  State<RequestLogin> createState() => _RequestLoginState();
}

class _RequestLoginState extends State<RequestLogin> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AccessRequestService _service = AccessRequestService();

  final TextEditingController _schoolCode = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _rollNumber = TextEditingController();
  final TextEditingController _className = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _schoolCode.dispose();
    _name.dispose();
    _rollNumber.dispose();
    _className.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final requestId = await _service.submit(
        schoolCode: _schoolCode.text,
        name: _name.text,
        rollNumber: _rollNumber.text,
        className: _className.text,
        email: _email.text,
        phone: _phone.text,
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Request submitted'),
          content: Text(
            'Your school administrator can now review the request.\n\nReference: $requestId',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request could not be submitted. Please try again.'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Login ID')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        size: 56,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Request school access',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Use the school code provided by your institute. The administrator must approve and create your account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      _field(
                        controller: _schoolCode,
                        label: 'School code',
                        icon: Icons.school_outlined,
                      ),
                      _field(
                        controller: _name,
                        label: 'Full name',
                        icon: Icons.person_outline,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              controller: _rollNumber,
                              label: 'Roll / employee no.',
                              icon: Icons.numbers_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              controller: _className,
                              label: 'Class / department',
                              icon: Icons.class_outlined,
                            ),
                          ),
                        ],
                      ),
                      _field(
                        controller: _email,
                        label: 'Email address',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return 'Required';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email)) {
                            return 'Invalid email';
                          }
                          return null;
                        },
                      ),
                      _field(
                        controller: _phone,
                        label: 'Phone number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: Text(_saving ? 'Submitting...' : 'Submit request'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        validator: validator ??
            (value) => value == null || value.trim().isEmpty ? 'Required' : null,
      ),
    );
  }
}
