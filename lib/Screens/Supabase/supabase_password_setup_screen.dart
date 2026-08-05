import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Widgets/solid_auth_shell.dart';
import '../../config/backend_config.dart';
import '../../services/supabase_auth_service.dart';
import '../../theme/app_theme.dart';

class SupabasePasswordSetupScreen extends StatefulWidget {
  const SupabasePasswordSetupScreen({super.key});

  @override
  State<SupabasePasswordSetupScreen> createState() => _SupabasePasswordSetupScreenState();
}

class _SupabasePasswordSetupScreenState extends State<SupabasePasswordSetupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  late final SupabaseAuthService _auth;

  bool _loading = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _auth = SupabaseAuthService();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_auth.currentSession == null) {
      _show('The invitation or recovery link has expired.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.updatePassword(_passwordController.text);
      if (!mounted) return;
      _show('Password saved. You can now sign in.');
      Navigator.pushNamedAndRemoveUntil(context, '/supabase-auth', (Route<dynamic> _) => false);
    } on AuthException catch (error) {
      _show(error.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: error ? AppColors.danger : AppColors.success));
  }

  @override
  Widget build(BuildContext context) {
    if (!BackendConfig.enableSupabaseAuthPilot) {
      return const SolidAuthShell(
        icon: Icons.block_rounded,
        eyebrow: 'Unavailable',
        title: 'Password setup disabled',
        subtitle: 'The Supabase authentication pilot is not enabled for this build.',
        child: SizedBox.shrink(),
      );
    }

    return SolidAuthShell(
      icon: Icons.password_rounded,
      eyebrow: 'Secure account',
      title: 'Create your password',
      subtitle: 'Choose a strong password for your school account. It must contain at least ten characters.',
      footer: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.shield_outlined, color: AppColors.success, size: 17),
          SizedBox(width: 7),
          Flexible(child: Text('Your password is transmitted over an encrypted connection.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary))),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _passwordController,
              obscureText: !_visible,
              autofillHints: const <String>[AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _visible = !_visible),
                  icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                ),
              ),
              validator: (String? value) => (value?.length ?? 0) < 10 ? 'Use at least 10 characters' : null,
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: _confirmController,
              obscureText: !_visible,
              autofillHints: const <String>[AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.verified_user_outlined)),
              validator: (String? value) => value != _passwordController.text ? 'Passwords do not match' : null,
              onFieldSubmitted: (_) => _loading ? null : _savePassword(),
            ),
            const SizedBox(height: 18),
            const _PasswordRules(),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loading ? null : _savePassword,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text(_loading ? 'Saving…' : 'Save Secure Password'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordRules extends StatelessWidget {
  const _PasswordRules();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Recommended', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
          SizedBox(height: 7),
          _Rule('At least 10 characters'),
          _Rule('Mix uppercase, lowercase and numbers'),
          _Rule('Do not reuse a personal password'),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  final String text;
  const _Rule(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success),
          SizedBox(width: 7),
          Expanded(child: Text(text, style: TextStyle(fontSize: 11, color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}
