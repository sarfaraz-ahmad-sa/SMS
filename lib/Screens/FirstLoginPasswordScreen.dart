import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/Auth_services.dart';
import '../services/school_account_service.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';
import 'home.dart';

class FirstLoginPasswordScreen extends StatefulWidget {
  const FirstLoginPasswordScreen({super.key});

  @override
  State<FirstLoginPasswordScreen> createState() =>
      _FirstLoginPasswordScreenState();
}

class _FirstLoginPasswordScreenState extends State<FirstLoginPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _accountService = SchoolAccountService();

  bool _saving = false;
  bool _currentVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 10) return 'Use at least 10 characters';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Add at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Add at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Add at least one number';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Add at least one special character';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final tenantId = SessionState.instance.tenant?.id;
    final profile = SessionState.instance.user;
    if (tenantId == null || profile == null) return;

    setState(() => _saving = true);
    try {
      await _authService.reauthenticateWithPassword(
        currentPassword: _currentPasswordController.text,
      );
      await _accountService.completeInitialPasswordChange(
        tenantId,
        _newPasswordController.text,
      );
      await _authService.refreshCurrentUser();
      SessionState.instance.updateUser(
        profile.copyWith(mustChangePassword: false),
      );
      try {
        await _authService.sendEmailVerification();
      } on FirebaseAuthException {
        // Password change is complete even if the verification email provider
        // is not configured yet.
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => const Home()),
        (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (error) {
      _showError(_messageFor(error));
    } on FirebaseFunctionsException catch (error) {
      _showError(error.message ?? 'Password setup could not be completed.');
    } catch (_) {
      _showError('Password could not be changed. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _messageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'The temporary password is incorrect.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'requires-recent-login':
        return 'Sign in again before changing your password.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return error.message ?? 'Password could not be changed.';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.danger),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = SessionState.instance;
    final tenant = state.tenant;
    final primary = AppColors.tenantPrimary(tenant);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(
                                  Icons.password_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'Secure your account',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Welcome to ${tenant?.name ?? 'your school'}. '
                              'Replace the temporary password before continuing.',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _PasswordField(
                              controller: _currentPasswordController,
                              label: 'Temporary password',
                              visible: _currentVisible,
                              onToggle: () => setState(
                                () => _currentVisible = !_currentVisible,
                              ),
                              validator: (String? value) =>
                                  value == null || value.isEmpty
                                      ? 'Enter the temporary password'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            _PasswordField(
                              controller: _newPasswordController,
                              label: 'New password',
                              visible: _newVisible,
                              onToggle: () => setState(
                                () => _newVisible = !_newVisible,
                              ),
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 14),
                            _PasswordField(
                              controller: _confirmPasswordController,
                              label: 'Confirm new password',
                              visible: _confirmVisible,
                              onToggle: () => setState(
                                () => _confirmVisible = !_confirmVisible,
                              ),
                              validator: (String? value) =>
                                  value != _newPasswordController.text
                                      ? 'Passwords do not match'
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            const _PasswordRules(),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.verified_user_outlined),
                              label: Text(
                                _saving
                                    ? 'Securing account...'
                                    : 'Change password & continue',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () async {
                                      await _authService.signOut();
                                      SessionState.instance.clear();
                                      if (!context.mounted) return;
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        '/login',
                                        (Route<dynamic> route) => false,
                                      );
                                    },
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text('Sign out'),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.visible,
    required this.onToggle,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool visible;
  final VoidCallback onToggle;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      autofillHints: const <String>[AutofillHints.password],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: visible ? 'Hide password' : 'Show password',
          onPressed: onToggle,
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
        ),
      ),
      validator: validator,
    );
  }
}

class _PasswordRules extends StatelessWidget {
  const _PasswordRules();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Use 10+ characters with uppercase, lowercase, a number and a special character. Do not reuse the temporary password.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}
