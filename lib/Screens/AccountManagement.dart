import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../Widgets/PermissionGate.dart';
import '../Widgets/saas_scaffold.dart';
import '../services/models/app_permission.dart';
import '../services/models/user_role.dart';
import '../services/school_account_service.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _campusController = TextEditingController();
  final _recordIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _service = SchoolAccountService();

  UserRole _role = UserRole.student;
  String _recordType = 'student';
  AccountSetupMethod _setupMethod = AccountSetupMethod.temporaryPassword;
  bool _forcePasswordChange = true;
  bool _passwordVisible = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final state = SessionState.instance;
    _campusController.text =
        state.activeCampusId ?? state.user?.campusIds.firstOrNull ?? '';
    final generated = _generateTemporaryPassword();
    _passwordController.text = generated;
    _confirmPasswordController.text = generated;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _campusController.dispose();
    _recordIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  List<UserRole> get _assignableRoles {
    final currentRoles = SessionState.instance.user?.roles ?? const <UserRole>[];
    if (currentRoles.contains(UserRole.superAdmin)) return UserRole.values;
    if (currentRoles.contains(UserRole.schoolOwner)) {
      return UserRole.values
          .where((UserRole role) => role != UserRole.superAdmin)
          .toList(growable: false);
    }
    return UserRole.values
        .where(
          (UserRole role) =>
              !role.isLeadership &&
              role != UserRole.adminStaff &&
              role != UserRole.itAdmin,
        )
        .toList(growable: false);
  }

  String? _validatePassword(String? value) {
    if (_setupMethod == AccountSetupMethod.emailLink) return null;
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

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    final tenantId = SessionState.instance.tenant?.id;
    if (tenantId == null || tenantId.isEmpty) return;

    setState(() => _saving = true);
    try {
      final result = await _service.provisionAccount(
        tenantId: tenantId,
        email: _emailController.text,
        displayName: _nameController.text,
        role: _role,
        campusIds: _campusController.text.toIdList(),
        setupMethod: _setupMethod,
        temporaryPassword: _setupMethod == AccountSetupMethod.temporaryPassword
            ? _passwordController.text
            : null,
        forcePasswordChange: _forcePasswordChange,
        recordType: _recordType.isEmpty ? null : _recordType,
        recordId:
            _recordType.isEmpty ? null : _recordIdController.text.trim(),
      );
      if (!mounted) return;

      final email = _emailController.text.trim().toLowerCase();
      final temporaryPassword = _passwordController.text;
      final setupMethod = _setupMethod;
      _resetForm();

      if (setupMethod == AccountSetupMethod.temporaryPassword) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => _CredentialsDialog(
            email: email,
            password: temporaryPassword,
            existingAuthenticationAccount:
                result.existingAuthenticationAccount,
          ),
        );
      } else {
        _showMessage(
          result.passwordEmailSent
              ? 'Account created and password setup email sent to $email.'
              : 'Account created, but the setup email could not be sent. '
                  'Use the account menu to resend it. '
                  '${result.passwordEmailError ?? ''}',
          success: result.passwordEmailSent,
        );
      }
    } on FirebaseFunctionsException catch (error) {
      _showError(error.message ?? 'The account could not be created.');
    } on FirebaseAuthException catch (error) {
      _showError(error.message ?? 'The setup email could not be sent.');
    } catch (_) {
      _showError('The account could not be created. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _recordIdController.clear();
    final generated = _generateTemporaryPassword();
    _passwordController.text = generated;
    _confirmPasswordController.text = generated;
    setState(() {
      _role = UserRole.student;
      _recordType = 'student';
      _setupMethod = AccountSetupMethod.temporaryPassword;
      _forcePasswordChange = true;
    });
  }

  void _generateAndSetPassword() {
    final generated = _generateTemporaryPassword();
    setState(() {
      _passwordController.text = generated;
      _confirmPasswordController.text = generated;
      _passwordVisible = true;
    });
  }

  void _showMessage(String message, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? AppColors.success : AppColors.warning,
          duration: const Duration(seconds: 7),
        ),
      );
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
    if (!SessionState.instance.hasPermission(AppPermission.usersManage)) {
      return const SaasScaffold(
        title: 'School Accounts',
        activeRoute: '/accounts',
        body: PermissionDeniedView(),
      );
    }

    final tenantId = SessionState.instance.tenant!.id;
    return SaasScaffold(
      title: 'School Accounts',
      activeRoute: '/accounts',
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final form = _AccountForm(
            tenantId: tenantId,
            formKey: _formKey,
            nameController: _nameController,
            emailController: _emailController,
            campusController: _campusController,
            recordIdController: _recordIdController,
            passwordController: _passwordController,
            confirmPasswordController: _confirmPasswordController,
            roles: _assignableRoles,
            role: _role,
            recordType: _recordType,
            setupMethod: _setupMethod,
            forcePasswordChange: _forcePasswordChange,
            passwordVisible: _passwordVisible,
            saving: _saving,
            validatePassword: _validatePassword,
            onRoleChanged: (UserRole? value) {
              if (value == null) return;
              setState(() {
                _role = value;
                final requiredType = switch (value) {
                  UserRole.student => 'student',
                  UserRole.parent => 'guardian',
                  UserRole.teacher || UserRole.classTeacher => 'teacher',
                  _ => '',
                };
                if (_recordType != requiredType) {
                  _recordType = requiredType;
                  _recordIdController.clear();
                }
              });
            },
            onSetupMethodChanged: (AccountSetupMethod value) {
              setState(() => _setupMethod = value);
            },
            onForcePasswordChangeChanged: (bool value) {
              setState(() => _forcePasswordChange = value);
            },
            onTogglePassword: () {
              setState(() => _passwordVisible = !_passwordVisible);
            },
            onGeneratePassword: _generateAndSetPassword,
            onSubmit: _createAccount,
          );
          final members = _MemberDirectory(
            tenantId: tenantId,
            service: _service,
            assignableRoles: _assignableRoles,
          );

          if (constraints.maxWidth >= 1040) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(width: 430, child: form),
                      const SizedBox(width: 20),
                      Expanded(child: members),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              form,
              const SizedBox(height: 16),
              members,
            ],
          );
        },
      ),
    );
  }
}

class _AccountForm extends StatelessWidget {
  const _AccountForm({
    required this.tenantId,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.campusController,
    required this.recordIdController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.roles,
    required this.role,
    required this.recordType,
    required this.setupMethod,
    required this.forcePasswordChange,
    required this.passwordVisible,
    required this.saving,
    required this.validatePassword,
    required this.onRoleChanged,
    required this.onSetupMethodChanged,
    required this.onForcePasswordChangeChanged,
    required this.onTogglePassword,
    required this.onGeneratePassword,
    required this.onSubmit,
  });

  final String tenantId;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController campusController;
  final TextEditingController recordIdController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final List<UserRole> roles;
  final UserRole role;
  final String recordType;
  final AccountSetupMethod setupMethod;
  final bool forcePasswordChange;
  final bool passwordVisible;
  final bool saving;
  final FormFieldValidator<String> validatePassword;
  final ValueChanged<UserRole?> onRoleChanged;
  final ValueChanged<AccountSetupMethod> onSetupMethodChanged;
  final ValueChanged<bool> onForcePasswordChangeChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onGeneratePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Create login account',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const Text(
                          'Assign the exact role, campus and ERP identity.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (String? value) =>
                    value == null || value.trim().length < 2
                        ? 'Enter the user name'
                        : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (String? value) {
                  final email = value?.trim() ?? '';
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                      ? null
                      : 'Enter a valid email address';
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<UserRole>(
                value: role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                ),
                items: roles
                    .map(
                      (UserRole item) => DropdownMenuItem<UserRole>(
                        value: item,
                        child: Text(item.label),
                      ),
                    )
                    .toList(),
                onChanged: saving ? null : onRoleChanged,
              ),
              const SizedBox(height: 14),
              _CampusScopeField(
                tenantId: tenantId,
                controller: campusController,
                enabled: !saving,
              ),
              const SizedBox(height: 14),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'ERP identity',
                  prefixIcon: Icon(Icons.link_outlined),
                ),
                child: Text(
                  switch (recordType) {
                    'student' => 'Student profile required',
                    'guardian' => 'Parent / guardian profile required',
                    'teacher' => 'Teacher profile required',
                    _ => 'Administrative account (no linked profile)',
                  },
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (recordType.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                _LinkedRecordDropdown(
                  tenantId: tenantId,
                  recordType: recordType,
                  controller: recordIdController,
                  enabled: !saving,
                ),
              ],
              const SizedBox(height: 18),
              Text(
                'Account setup',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              SegmentedButton<AccountSetupMethod>(
                segments: const <ButtonSegment<AccountSetupMethod>>[
                  ButtonSegment<AccountSetupMethod>(
                    value: AccountSetupMethod.temporaryPassword,
                    icon: Icon(Icons.password_rounded),
                    label: Text('Password'),
                  ),
                  ButtonSegment<AccountSetupMethod>(
                    value: AccountSetupMethod.emailLink,
                    icon: Icon(Icons.mark_email_read_outlined),
                    label: Text('Email link'),
                  ),
                ],
                selected: <AccountSetupMethod>{setupMethod},
                onSelectionChanged: saving
                    ? null
                    : (Set<AccountSetupMethod> value) {
                        onSetupMethodChanged(value.first);
                      },
              ),
              if (setupMethod == AccountSetupMethod.temporaryPassword) ...<Widget>[
                const SizedBox(height: 14),
                TextFormField(
                  controller: passwordController,
                  obscureText: !passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Temporary password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: passwordVisible ? 'Hide password' : 'Show password',
                      onPressed: onTogglePassword,
                      icon: Icon(
                        passwordVisible ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: validatePassword,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: !passwordVisible,
                  decoration: const InputDecoration(
                    labelText: 'Confirm temporary password',
                    prefixIcon: Icon(Icons.lock_reset_rounded),
                  ),
                  validator: (String? value) =>
                      value != passwordController.text
                          ? 'Passwords do not match'
                          : null,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: saving ? null : onGeneratePassword,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Generate strong password'),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: forcePasswordChange,
                  onChanged: saving ? null : onForcePasswordChangeChanged,
                  title: const Text('Require password change on first login'),
                  subtitle: const Text(
                    'Recommended for every admin-created account.',
                  ),
                ),
              ] else ...<Widget>[
                const SizedBox(height: 12),
                const _InfoPanel(
                  icon: Icons.outgoing_mail,
                  text:
                      'Firebase will email a secure password setup link. The user cannot sign in until the link is completed.',
                ),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: saving ? null : onSubmit,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_add_alt_1_rounded),
                label: Text(saving ? 'Creating account...' : 'Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberDirectory extends StatefulWidget {
  const _MemberDirectory({
    required this.tenantId,
    required this.service,
    required this.assignableRoles,
  });

  final String tenantId;
  final SchoolAccountService service;
  final List<UserRole> assignableRoles;

  @override
  State<_MemberDirectory> createState() => _MemberDirectoryState();
}

class _MemberDirectoryState extends State<_MemberDirectory> {
  final _searchController = TextEditingController();
  String _statusFilter = 'all';
  bool _working = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = error is FirebaseFunctionsException
        ? error.message ?? 'The account action failed.'
        : error is FirebaseAuthException
            ? error.message ?? 'The account action failed.'
            : 'The account action failed. Please try again.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.danger),
      );
  }

  Future<void> _editAccess(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final nameController = TextEditingController(
      text: data['displayName']?.toString() ?? '',
    );
    final campusController = TextEditingController(
      text: _stringList(data['campusIds']).join(', '),
    );
    final currentRoles = _roles(data['roles']);
    var selectedRole = currentRoles.firstOrNull ?? UserRole.student;
    if (!widget.assignableRoles.contains(selectedRole)) {
      selectedRole = widget.assignableRoles.first;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return AlertDialog(
            title: const Text('Edit account access'),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.shield_outlined),
                    ),
                    items: widget.assignableRoles
                        .map(
                          (UserRole role) => DropdownMenuItem<UserRole>(
                            value: role,
                            child: Text(role.label),
                          ),
                        )
                        .toList(),
                    onChanged: (UserRole? value) {
                      if (value != null) setDialogState(() => selectedRole = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  _CampusScopeField(
                    tenantId: widget.tenantId,
                    controller: campusController,
                    enabled: true,
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save access'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) {
      nameController.dispose();
      campusController.dispose();
      return;
    }

    setState(() => _working = true);
    try {
      await widget.service.updateAccess(
        tenantId: widget.tenantId,
        targetUid: uid,
        displayName: nameController.text,
        roles: <UserRole>[selectedRole],
        campusIds: campusController.text.toIdList(),
      );
      if (mounted) _success('Account access updated.');
    } catch (error) {
      _showError(error);
    } finally {
      nameController.dispose();
      campusController.dispose();
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _resetPassword(String uid, String email) async {
    final passwordController = TextEditingController(
      text: _generateTemporaryPassword(),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Reset temporary password'),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Account: $email'),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'New temporary password',
                  prefixIcon: const Icon(Icons.password_rounded),
                  suffixIcon: IconButton(
                    tooltip: 'Generate another password',
                    onPressed: () {
                      passwordController.text = _generateTemporaryPassword();
                    },
                    icon: const Icon(Icons.auto_awesome_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'The user will be signed out and must replace this password on the next login.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset password'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      passwordController.dispose();
      return;
    }

    final password = passwordController.text;
    setState(() => _working = true);
    try {
      await widget.service.resetTemporaryPassword(
        tenantId: widget.tenantId,
        targetUid: uid,
        temporaryPassword: password,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => _CredentialsDialog(
          email: email,
          password: password,
        ),
      );
    } catch (error) {
      _showError(error);
    } finally {
      passwordController.dispose();
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _toggleActive(
    String uid,
    String name,
    bool currentlyActive,
  ) async {
    String reason = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(currentlyActive ? 'Suspend account?' : 'Activate account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              currentlyActive
                  ? '$name will immediately lose access to this school.'
                  : '$name will regain access using the existing credentials.',
            ),
            if (currentlyActive) ...<Widget>[
              const SizedBox(height: 14),
              TextField(
                autofocus: true,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Suspension reason',
                  hintText: 'Required for the audit log',
                ),
                onChanged: (String value) => reason = value,
              ),
            ],
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(currentlyActive ? 'Suspend' : 'Activate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (currentlyActive && reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a suspension reason.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _working = true);
    try {
      await widget.service.setAccountActive(
        tenantId: widget.tenantId,
        targetUid: uid,
        active: !currentlyActive,
        reason: reason,
      );
      if (mounted) {
        _success(currentlyActive ? 'Account suspended.' : 'Account activated.');
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _sendSetupEmail(String email) async {
    setState(() => _working = true);
    try {
      await widget.service.sendPasswordSetupEmail(email);
      if (mounted) _success('Password setup email sent to $email.');
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _success(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.success),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Account directory',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const Text(
                        'Roles, campus scope, linked identity and account status.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_working)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search name, email or role',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final filter in const <String>['all', 'active', 'suspended'])
                  ChoiceChip(
                    label: Text(filter[0].toUpperCase() + filter.substring(1)),
                    selected: _statusFilter == filter,
                    onSelected: (_) => setState(() => _statusFilter = filter),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 610,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: widget.service.watchMembers(widget.tenantId),
                builder: (
                  BuildContext context,
                  AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const PermissionDeniedView(
                      message: 'School accounts could not be loaded.',
                    );
                  }
                  final query = _searchController.text.trim().toLowerCase();
                  final documents = (snapshot.data?.docs ??
                          const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                      .where((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
                    final data = doc.data();
                    final active = _isActive(data);
                    if (_statusFilter == 'active' && !active) return false;
                    if (_statusFilter == 'suspended' && active) return false;
                    if (query.isEmpty) return true;
                    final haystack = <String>[
                      data['displayName']?.toString() ?? '',
                      data['email']?.toString() ?? '',
                      ..._stringList(data['roles']),
                    ].join(' ').toLowerCase();
                    return haystack.contains(query);
                  }).toList(growable: true)
                    ..sort((left, right) {
                      final leftName = left
                          .data()['displayName']
                          ?.toString()
                          .toLowerCase() ?? '';
                      final rightName = right
                          .data()['displayName']
                          ?.toString()
                          .toLowerCase() ?? '';
                      return leftName.compareTo(rightName);
                    });

                  if (documents.isEmpty) {
                    return const Center(
                      child: Text('No matching school accounts.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: documents.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final document = documents[index];
                      final data = document.data();
                      final active = _isActive(data);
                      final roles = _roles(data['roles']);
                      final roleLabel = roles.isEmpty
                          ? 'No role'
                          : roles.map((UserRole role) => role.label).join(', ');
                      final name = data['displayName']?.toString().trim();
                      final email = data['email']?.toString().trim() ?? '';
                      final mustChange = data['mustChangePassword'] == true;
                      final linkedType = data['linkedRecordType']?.toString();
                      final accountCategory =
                          data['accountCategory']?.toString() == 'portal'
                              ? 'Portal account'
                              : 'Staff seat';
                      final campuses = _stringList(data['campusIds']);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            CircleAvatar(
                              backgroundColor: active
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1)
                                  : AppColors.danger.withOpacity(0.1),
                              child: Icon(
                                active
                                    ? Icons.person_outline_rounded
                                    : Icons.person_off_outlined,
                                color: active
                                    ? Theme.of(context).colorScheme.primary
                                    : AppColors.danger,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    name?.isNotEmpty == true ? name! : email,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 7),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: <Widget>[
                                      _MiniBadge(label: roleLabel),
                                      _MiniBadge(
                                        label: accountCategory,
                                        color: accountCategory == 'Portal account'
                                            ? AppColors.info
                                            : AppColors.accent,
                                      ),
                                      _MiniBadge(
                                        label: active ? 'Active' : 'Suspended',
                                        color: active
                                            ? AppColors.success
                                            : AppColors.danger,
                                      ),
                                      if (mustChange)
                                        const _MiniBadge(
                                          label: 'Password change required',
                                          color: AppColors.warning,
                                        ),
                                      if (linkedType?.isNotEmpty == true)
                                        _MiniBadge(
                                          label: 'Linked ${linkedType!}',
                                          color: AppColors.info,
                                        ),
                                      if (campuses.isNotEmpty)
                                        _MiniBadge(
                                          label: '${campuses.length} campus',
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              enabled: !_working,
                              tooltip: 'Account actions',
                              onSelected: (String action) {
                                switch (action) {
                                  case 'edit':
                                    _editAccess(document.id, data);
                                    break;
                                  case 'reset':
                                    _resetPassword(document.id, email);
                                    break;
                                  case 'email':
                                    _sendSetupEmail(email);
                                    break;
                                  case 'status':
                                    _toggleActive(
                                      document.id,
                                      name?.isNotEmpty == true ? name! : email,
                                      active,
                                    );
                                    break;
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.manage_accounts_outlined),
                                    title: Text('Edit role & campuses'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'reset',
                                  child: ListTile(
                                    leading: Icon(Icons.password_rounded),
                                    title: Text('Reset temporary password'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'email',
                                  child: ListTile(
                                    leading: Icon(Icons.outgoing_mail),
                                    title: Text('Send password setup email'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'status',
                                  child: ListTile(
                                    leading: Icon(
                                      active
                                          ? Icons.person_off_outlined
                                          : Icons.person_add_alt_rounded,
                                      color: active
                                          ? AppColors.danger
                                          : AppColors.success,
                                    ),
                                    title: Text(
                                      active ? 'Suspend account' : 'Activate account',
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _CampusScopeField extends StatefulWidget {
  const _CampusScopeField({
    required this.tenantId,
    required this.controller,
    required this.enabled,
  });

  final String tenantId;
  final TextEditingController controller;
  final bool enabled;

  @override
  State<_CampusScopeField> createState() => _CampusScopeFieldState();
}

class _CampusScopeFieldState extends State<_CampusScopeField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant _CampusScopeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _toggle(String campusId, bool selected) {
    final values = widget.controller.text.toIdList().toSet();
    if (selected) {
      values.add(campusId);
    } else {
      values.remove(campusId);
    }
    widget.controller.text = values.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('tenants')
        .doc(widget.tenantId)
        .collection('campuses')
        .limit(100)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (
        BuildContext context,
        AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
      ) {
        final campuses = snapshot.data?.docs
                .where((document) => document.data()['isArchived'] != true)
                .toList() ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        campuses.sort((left, right) {
          final leftName = (left.data()['name'] ?? left.id).toString();
          final rightName = (right.data()['name'] ?? right.id).toString();
          return leftName.toLowerCase().compareTo(rightName.toLowerCase());
        });

        if (snapshot.hasError ||
            (snapshot.connectionState != ConnectionState.waiting &&
                campuses.isEmpty)) {
          return TextFormField(
            controller: widget.controller,
            enabled: widget.enabled,
            decoration: const InputDecoration(
              labelText: 'Campus scope',
              hintText: 'main-campus, north-campus',
              helperText: 'No campus list is available. Enter campus IDs.',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
          );
        }

        final selectedIds = widget.controller.text.toIdList().toSet();
        return InputDecorator(
          decoration: InputDecoration(
            labelText: 'Campus scope',
            prefixIcon: const Icon(Icons.location_city_outlined),
            helperText: snapshot.connectionState == ConnectionState.waiting
                ? 'Loading campuses…'
                : selectedIds.isEmpty
                    ? 'No selection means all campuses allowed by the role.'
                    : '${selectedIds.length} campus(es) selected',
          ),
          child: campuses.isEmpty
              ? const LinearProgressIndicator(minHeight: 2)
              : Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: campuses.map((document) {
                    final data = document.data();
                    final name = (data['name'] ?? document.id).toString();
                    final code = data['code']?.toString().trim() ?? '';
                    return FilterChip(
                      selected: selectedIds.contains(document.id),
                      onSelected: widget.enabled
                          ? (bool selected) => _toggle(document.id, selected)
                          : null,
                      label: Text(code.isEmpty ? name : '$name ($code)'),
                    );
                  }).toList(growable: false),
                ),
        );
      },
    );
  }
}

class _LinkedRecordDropdown extends StatelessWidget {
  const _LinkedRecordDropdown({
    required this.tenantId,
    required this.recordType,
    required this.controller,
    required this.enabled,
  });

  final String tenantId;
  final String recordType;
  final TextEditingController controller;
  final bool enabled;

  String get _collection => switch (recordType) {
        'student' => 'students',
        'guardian' => 'guardians',
        _ => 'teachers',
      };

  String get _label => switch (recordType) {
        'student' => 'Select student',
        'guardian' => 'Select parent / guardian',
        _ => 'Select teacher',
      };

  String _title(Map<String, dynamic> data) {
    return (data['fullName'] ?? data['name'] ?? 'Unnamed record').toString();
  }

  String _subtitle(Map<String, dynamic> data, String id) {
    final reference = switch (recordType) {
      'student' => data['admissionNo'],
      'guardian' => data['relationship'] ?? data['phone'],
      _ => data['employeeNo'],
    };
    final value = reference?.toString().trim() ?? '';
    return value.isEmpty ? id : '$value • $id';
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('tenants')
        .doc(tenantId)
        .collection(_collection)
        .limit(300)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (
        BuildContext context,
        AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
      ) {
        if (snapshot.hasError) {
          return TextFormField(
            controller: controller,
            enabled: enabled,
            decoration: InputDecoration(
              labelText: '$_label record ID',
              helperText: 'Profile list unavailable. Enter its Firestore ID.',
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
            validator: (String? value) => value == null || value.trim().isEmpty
                ? 'Select or enter the linked profile'
                : null,
          );
        }

        final documents = snapshot.data?.docs
                .where((document) => document.data()['isArchived'] != true)
                .toList() ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        documents.sort((left, right) =>
            _title(left.data()).toLowerCase().compareTo(
                  _title(right.data()).toLowerCase(),
                ));
        final ids = documents.map((document) => document.id).toSet();
        final selected = ids.contains(controller.text.trim())
            ? controller.text.trim()
            : null;

        return DropdownButtonFormField<String>(
          value: selected,
          isExpanded: true,
          itemHeight: 64,
          decoration: InputDecoration(
            labelText: _label,
            prefixIcon: const Icon(Icons.badge_outlined),
            helperText: snapshot.connectionState == ConnectionState.waiting
                ? 'Loading profiles…'
                : '${documents.length} available profile(s)',
          ),
          items: documents
              .map(
                (document) => DropdownMenuItem<String>(
                  value: document.id,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _title(document.data()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _subtitle(document.data(), document.id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: !enabled || documents.isEmpty
              ? null
              : (String? value) => controller.text = value ?? '',
          validator: (String? value) => value == null || value.trim().isEmpty
              ? 'Select the linked ERP profile'
              : null,
        );
      },
    );
  }
}

class _CredentialsDialog extends StatelessWidget {
  const _CredentialsDialog({
    required this.email,
    required this.password,
    this.existingAuthenticationAccount = false,
  });

  final String email;
  final String password;
  final bool existingAuthenticationAccount;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        existingAuthenticationAccount
            ? Icons.info_outline_rounded
            : Icons.verified_user_outlined,
        color: existingAuthenticationAccount
            ? AppColors.info
            : AppColors.success,
        size: 36,
      ),
      title: Text(
        existingAuthenticationAccount
            ? 'School access added'
            : 'Account created successfully',
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (existingAuthenticationAccount)
              const _InfoPanel(
                icon: Icons.shield_outlined,
                text:
                    'This email already had a Firebase account, so its existing password was preserved. Send a password setup email if the user does not know it.',
              )
            else ...<Widget>[
              const Text(
                'Share these credentials securely. The user must change the temporary password on first login.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _CredentialRow(label: 'Email', value: email),
              const SizedBox(height: 10),
              _CredentialRow(label: 'Temporary password', value: password),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text: 'Email: $email\nTemporary password: $password',
                    ),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Credentials copied.')),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy credentials'),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy $label',
            onPressed: () => Clipboard.setData(ClipboardData(text: value)),
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppColors.info, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: effectiveColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

bool _isActive(Map<String, dynamic> data) {
  final status = data['status']?.toString().toLowerCase();
  return data['isActive'] != false &&
      status != 'suspended' &&
      status != 'inactive' &&
      status != 'disabled';
}

List<String> _stringList(dynamic value) {
  if (value is! Iterable) return const <String>[];
  return value
      .map((dynamic item) => item?.toString().trim() ?? '')
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
}

List<UserRole> _roles(dynamic value) {
  return _stringList(value)
      .map(tryUserRoleFromString)
      .whereType<UserRole>()
      .toList(growable: false);
}

String _generateTemporaryPassword() {
  const uppercase = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const lowercase = 'abcdefghijkmnopqrstuvwxyz';
  const numbers = '23456789';
  const symbols = '!@#%&*+-_';
  const all = '$uppercase$lowercase$numbers$symbols';
  final random = Random.secure();
  final characters = <String>[
    uppercase[random.nextInt(uppercase.length)],
    lowercase[random.nextInt(lowercase.length)],
    numbers[random.nextInt(numbers.length)],
    symbols[random.nextInt(symbols.length)],
    for (var index = 0; index < 10; index++)
      all[random.nextInt(all.length)],
  ]..shuffle(random);
  return characters.join();
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

extension _IdList on String {
  List<String> toIdList() => split(',')
      .map((String value) => value.trim())
      .where((String value) => value.isNotEmpty)
      .toSet()
      .toList(growable: false);
}
