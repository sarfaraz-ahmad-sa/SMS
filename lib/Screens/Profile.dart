import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Widgets/saas_scaffold.dart';

import '../services/Auth_services.dart';
import '../services/profile_service.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';
import '../config/backend_config.dart';
import '../services/supabase_auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  late final TextEditingController _nameController;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: SessionState.instance.user?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _profileService.updateDisplayName(_nameController.text);
      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendVerification() async {
    try {
      await _authService.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent. Check your inbox.'),
          backgroundColor: AppColors.success,
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(error.message ?? 'Verification email could not be sent.'),
          backgroundColor: AppColors.danger,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification could not be completed: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    final supportsPassword = BackendConfig.isSupabasePrimary ||
        FirebaseAuth.instance.currentUser?.providerData.any(
              (UserInfo provider) => provider.providerId == 'password',
            ) ==
            true;
    if (!supportsPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Password is managed by your external sign-in provider.'),
        ),
      );
      return;
    }

    final result = await showDialog<_PasswordChangeData>(
      context: context,
      builder: (BuildContext context) => const _PasswordChangeDialog(),
    );
    if (result == null) return;

    try {
      await _authService.changePassword(
        currentPassword: result.currentPassword,
        newPassword: result.newPassword,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Password could not be changed.'),
          backgroundColor: AppColors.danger,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password could not be changed: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionState.instance,
      builder: (BuildContext context, Widget? child) {
        final user = SessionState.instance.user;
        final tenant = SessionState.instance.tenant;

        final emailVerified = BackendConfig.isSupabasePrimary
            ? SupabaseAuthService().isEmailVerified
            : FirebaseAuth.instance.currentUser?.emailVerified == true;

        return SaasScaffold(
          title: 'Profile',
          activeRoute: '/profile',
          actions: <Widget>[
            IconButton(
              tooltip: _editing ? 'Cancel editing' : 'Edit profile',
              icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
              onPressed: _saving
                  ? null
                  : () {
                      setState(() {
                        _editing = !_editing;
                        if (!_editing) {
                          _nameController.text = user?.displayName ?? '';
                        }
                      });
                    },
            ),
          ],
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.tenantGradient(tenant),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: <Widget>[
                        const CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.person,
                            size: 52,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.displayName?.trim().isNotEmpty == true
                              ? user!.displayName!.trim()
                              : 'User',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.roleLabel ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            TextFormField(
                              controller: _nameController,
                              enabled: _editing && !_saving,
                              decoration: const InputDecoration(
                                labelText: 'Display name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (String? value) {
                                final name = value?.trim() ?? '';
                                if (name.length < 2) {
                                  return 'Enter at least 2 characters';
                                }
                                if (name.length > 120) {
                                  return 'Maximum 120 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _ReadOnlyField(
                              label: 'Email address',
                              value: user?.email ?? 'Not available',
                              icon: Icons.mail_outline,
                            ),
                            const SizedBox(height: 14),
                            _ReadOnlyField(
                              label: 'School',
                              value: tenant?.name ?? 'Not assigned',
                              icon: Icons.school_outlined,
                            ),
                            const SizedBox(height: 14),
                            _ReadOnlyField(
                              label: 'Role',
                              value: user?.roleLabel ?? 'Not assigned',
                              icon: Icons.badge_outlined,
                            ),
                            const SizedBox(height: 14),
                            _ReadOnlyField(
                              label: 'Campus access',
                              value: user?.campusIds.isNotEmpty == true
                                  ? user!.campusIds.join(', ')
                                  : 'All authorized campuses',
                              icon: Icons.location_city_outlined,
                            ),
                            if (_editing) ...<Widget>[
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _saving ? null : _save,
                                child: _saving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Save Changes'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          leading: Icon(
                            emailVerified
                                ? Icons.verified_rounded
                                : Icons.mark_email_unread_outlined,
                            color: emailVerified
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          title: const Text(
                            'Email verification',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            emailVerified
                                ? 'Your email address is verified.'
                                : 'Verify your email to secure recovery and notifications.',
                          ),
                          trailing: emailVerified
                              ? const Icon(Icons.check_circle,
                                  color: AppColors.success)
                              : TextButton(
                                  onPressed: _sendVerification,
                                  child: const Text('Send email'),
                                ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.password_rounded),
                          title: const Text(
                            'Password & sign-in',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text(
                            'Change your password after confirming the current one.',
                          ),
                          trailing: TextButton(
                            onPressed: _changePassword,
                            child: const Text('Change'),
                          ),
                        ),
                        if (user?.linkedRecordId?.isNotEmpty ==
                            true) ...<Widget>[
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.link_rounded),
                            title: const Text(
                              'Linked ERP identity',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${user!.linkedRecordType ?? 'profile'} • ${user.linkedRecordId}',
                            ),
                            trailing: const Icon(Icons.lock_outline_rounded),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PasswordChangeData {
  const _PasswordChangeData({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;
}

class _PasswordChangeDialog extends StatefulWidget {
  const _PasswordChangeDialog();

  @override
  State<_PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<_PasswordChangeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _visible = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateNewPassword(String? value) {
    final password = value ?? '';
    if (password.length < 10) return 'Use at least 10 characters';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Add an uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(password)) return 'Add a lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(password)) return 'Add a number';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Add a special character';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _currentController,
                obscureText: !_visible,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (String? value) => value == null || value.isEmpty
                    ? 'Enter your current password'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newController,
                obscureText: !_visible,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  prefixIcon: Icon(Icons.password_rounded),
                ),
                validator: _validateNewPassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: !_visible,
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    tooltip: _visible ? 'Hide passwords' : 'Show passwords',
                    onPressed: () => setState(() => _visible = !_visible),
                    icon: Icon(
                        _visible ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
                validator: (String? value) => value != _newController.text
                    ? 'Passwords do not match'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _PasswordChangeData(
                currentPassword: _currentController.text,
                newPassword: _newController.text,
              ),
            );
          },
          child: const Text('Update password'),
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      child: Text(value),
    );
  }
}
