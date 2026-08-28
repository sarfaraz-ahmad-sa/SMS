import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Widgets/solid_auth_shell.dart';
import '../config/backend_config.dart';
import '../services/Auth_services.dart';
import '../theme/app_theme.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          icon: const Icon(Icons.mark_email_read_rounded, color: AppColors.success),
          title: const Text('Reset link sent'),
          content: Text('Check your inbox and follow the ${BackendConfig.isSupabasePrimary ? 'Supabase' : 'Firebase'} password reset instructions.'),
          actions: <Widget>[
            FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Done')),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (error) {
      _showError(error.message ?? 'Password reset failed.');
    } catch (_) {
      _showError('Could not send the reset email. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SolidAuthShell(
      icon: Icons.lock_reset_rounded,
      eyebrow: 'Account recovery',
      title: 'Reset your password',
      subtitle: 'Enter the registered email address for your school account. We will send a secure recovery link.',
      footer: Builder(
        builder: (BuildContext context) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.shield_outlined, color: AppColors.success, size: 17),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                'Recovery links are time-limited for account security.',
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
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline_rounded)),
              validator: (String? value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Enter your email address';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return 'Enter a valid email address';
                return null;
              },
              onFieldSubmitted: (_) {
                if (!_loading) _sendResetLink();
              },
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loading ? null : _sendResetLink,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_loading ? 'Sending…' : 'Send Reset Link'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _loading ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 17),
              label: const Text('Back to Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
