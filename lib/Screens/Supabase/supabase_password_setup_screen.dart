import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/backend_config.dart';
import '../../services/supabase_auth_service.dart';
import '../../theme/app_theme.dart';

class SupabasePasswordSetupScreen extends StatefulWidget {
  const SupabasePasswordSetupScreen({super.key});

  @override
  State<SupabasePasswordSetupScreen> createState() =>
      _SupabasePasswordSetupScreenState();
}

class _SupabasePasswordSetupScreenState
    extends State<SupabasePasswordSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
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
    if (!_formKey.currentState!.validate()) return;
    if (_auth.currentSession == null) {
      _show('The invitation or recovery link has expired.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.updatePassword(_passwordController.text);
      if (!mounted) return;
      _show('Password saved. You can now sign in.');
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/supabase-auth',
        (route) => false,
      );
    } on AuthException catch (error) {
      _show(error.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!BackendConfig.enableSupabaseAuthPilot) {
      return const Scaffold(
        body: Center(child: Text('Supabase authentication pilot is disabled.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Set your password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Icon(Icons.password_rounded,
                          size: 58, color: AppColors.primary),
                      const SizedBox(height: 18),
                      const Text(
                        'Create a secure password',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_visible,
                        autofillHints: const <String>[
                          AutofillHints.newPassword
                        ],
                        decoration: InputDecoration(
                          labelText: 'New password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _visible = !_visible),
                            icon: Icon(_visible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                          ),
                        ),
                        validator: (value) => (value?.length ?? 0) < 10
                            ? 'Use at least 10 characters'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: !_visible,
                        autofillHints: const <String>[
                          AutofillHints.newPassword
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.verified_user_outlined),
                        ),
                        validator: (value) => value != _passwordController.text
                            ? 'Passwords do not match'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _loading ? null : _savePassword,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(
                            _loading ? 'Saving...' : 'Save secure password'),
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
}
