import 'package:flutter/material.dart';

import '../Widgets/solid_auth_shell.dart';
import '../services/access_request_service.dart';
import '../theme/app_theme.dart';

class RequestLogin extends StatefulWidget {
  const RequestLogin({super.key});

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
    for (final controller in <TextEditingController>[_schoolCode, _name, _rollNumber, _className, _email, _phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
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
        builder: (BuildContext dialogContext) => AlertDialog(
          icon: const Icon(Icons.mark_email_read_rounded, color: AppColors.success),
          title: const Text('Request submitted'),
          content: Text('Your school administrator can now review your request.\n\nReference: $requestId'),
          actions: <Widget>[
            FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Done')),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request could not be submitted. Please try again.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SolidAuthShell(
      icon: Icons.badge_outlined,
      eyebrow: 'School access',
      title: 'Request a login ID',
      subtitle: 'Use the school code provided by your institute. Your administrator will verify the details and create your account.',
      maxWidth: 620,
      footer: Builder(
        builder: (BuildContext context) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 17),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                'Account access is granted only after school approval.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.5),
              ),
            ),
          ],
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _schoolCode,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'School Code', prefixIcon: Icon(Icons.school_outlined)),
              validator: _required('school code'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline_rounded)),
              validator: _required('full name'),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final compact = constraints.maxWidth < 460;
                final roll = TextFormField(
                  controller: _rollNumber,
                  decoration: const InputDecoration(labelText: 'Roll / Employee ID', prefixIcon: Icon(Icons.numbers_rounded)),
                  validator: _required('roll or employee ID'),
                );
                final classField = TextFormField(
                  controller: _className,
                  decoration: const InputDecoration(labelText: 'Class / Department', prefixIcon: Icon(Icons.groups_outlined)),
                  validator: _required('class or department'),
                );
                if (compact) {
                  return Column(children: <Widget>[roll, const SizedBox(height: 12), classField]);
                }
                return Row(children: <Widget>[Expanded(child: roll), const SizedBox(width: 12), Expanded(child: classField)]);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.mail_outline_rounded)),
              validator: (String? value) {
                final email = (value ?? '').trim();
                if (email.isEmpty) return 'Enter email address';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return 'Enter a valid email address';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_saving) _submit();
              },
              decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
              validator: (String? value) {
                final phone = (value ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
                if (phone.isEmpty) return 'Enter phone number';
                if (phone.replaceAll('+', '').length < 10) return 'Enter a valid phone number';
                return null;
              },
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_saving ? 'Submitting…' : 'Submit Access Request'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _saving ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 17),
              label: const Text('Back to Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  FormFieldValidator<String> _required(String field) {
    return (String? value) => (value ?? '').trim().isEmpty ? 'Enter $field' : null;
  }
}
