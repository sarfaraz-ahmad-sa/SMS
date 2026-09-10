import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../Widgets/PermissionGate.dart';
import '../../Widgets/saas_scaffold.dart';
import '../../services/models/user_role.dart';
import '../../services/platform_onboarding_service.dart';
import '../../services/session_state.dart';
import '../../theme/app_theme.dart';

class PlatformSchoolOnboardingScreen extends StatefulWidget {
  const PlatformSchoolOnboardingScreen({super.key});

  @override
  State<PlatformSchoolOnboardingScreen> createState() =>
      _PlatformSchoolOnboardingScreenState();
}

class _PlatformSchoolOnboardingScreenState
    extends State<PlatformSchoolOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolName = TextEditingController();
  final _schoolCode = TextEditingController();
  final _ownerName = TextEditingController();
  final _ownerEmail = TextEditingController();
  final _campusName = TextEditingController(text: 'Main Campus');
  final _campusCode = TextEditingController(text: 'MAIN');
  final _academicYearName = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _service = PlatformOnboardingService();

  late DateTime _academicYearStart;
  late DateTime _academicYearEnd;
  OwnerSetupMethod _setupMethod = OwnerSetupMethod.emailLink;
  String _plan = 'trial';
  int _trialDays = 30;
  bool _passwordVisible = false;
  bool _saving = false;

  static const _plans = <String, String>{
    'trial': 'Free Trial',
    'starter': 'Starter — PKR 3,000',
    'standard': 'Standard — PKR 6,000',
    'pro': 'Professional — PKR 10,000',
    'enterprise': 'Enterprise',
    'custom': 'Custom',
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final startingYear = now.month >= 7 ? now.year : now.year - 1;
    _academicYearStart = DateTime(startingYear, 7, 1);
    _academicYearEnd = DateTime(startingYear + 1, 6, 30);
    _academicYearName.text = '$startingYear-${startingYear + 1}';
    _generatePassword();
  }

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _schoolName,
      _schoolCode,
      _ownerName,
      _ownerEmail,
      _campusName,
      _campusCode,
      _academicYearName,
      _password,
      _confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isSuperAdmin => SessionState.instance.user?.roles
          .contains(UserRole.superAdmin) ==
      true;

  Future<void> _createSchool() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_academicYearEnd.isBefore(_academicYearStart) ||
        _academicYearEnd.isAtSameMomentAs(_academicYearStart)) {
      _showError('Academic year end date must be after its start date.');
      return;
    }

    setState(() => _saving = true);
    try {
      final temporaryPassword = _password.text;
      final result = await _service.createSchool(
        schoolName: _schoolName.text,
        schoolCode: _schoolCode.text,
        ownerName: _ownerName.text,
        ownerEmail: _ownerEmail.text,
        campusName: _campusName.text,
        campusCode: _campusCode.text,
        academicYearName: _academicYearName.text,
        academicYearStart: _academicYearStart,
        academicYearEnd: _academicYearEnd,
        plan: _plan,
        trialDays: _trialDays,
        setupMethod: _setupMethod,
        temporaryPassword:
            _setupMethod == OwnerSetupMethod.temporaryPassword
                ? temporaryPassword
                : null,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => _OnboardingSuccessDialog(
          result: result,
          setupMethod: _setupMethod,
          temporaryPassword: temporaryPassword,
        ),
      );
      if (mounted) _resetForm();
    } catch (error) {
      _showError(
        error is PlatformOnboardingException
            ? error.message
            : 'School onboarding could not be completed.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _schoolName.clear();
    _schoolCode.clear();
    _ownerName.clear();
    _ownerEmail.clear();
    _campusName.text = 'Main Campus';
    _campusCode.text = 'MAIN';
    _setupMethod = OwnerSetupMethod.emailLink;
    _plan = 'trial';
    _trialDays = 30;
    _generatePassword();
    setState(() {});
  }

  void _generatePassword() {
    final random = Random.secure();
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const lower = 'abcdefghijkmnopqrstuvwxyz';
    const digits = '23456789';
    const symbols = '!@#%^&*';
    const all = '$upper$lower$digits$symbols';
    final chars = <String>[
      upper[random.nextInt(upper.length)],
      lower[random.nextInt(lower.length)],
      digits[random.nextInt(digits.length)],
      symbols[random.nextInt(symbols.length)],
      ...List<String>.generate(
        10,
        (_) => all[random.nextInt(all.length)],
      ),
    ]..shuffle(random);
    final generated = chars.join();
    _password.text = generated;
    _confirmPassword.text = generated;
  }

  String? _required(String? value, String label) =>
      (value ?? '').trim().length < 2 ? 'Enter $label' : null;

  String? _passwordError(String? value) {
    if (_setupMethod == OwnerSetupMethod.emailLink) return null;
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

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? _academicYearStart : _academicYearEnd;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 5, 12, 31),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (start) {
        _academicYearStart = selected;
      } else {
        _academicYearEnd = selected;
      }
    });
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
    if (!_isSuperAdmin) {
      return const SaasScaffold(
        title: 'New School',
        activeRoute: '/platform-onboarding',
        body: PermissionDeniedView(),
      );
    }

    return SaasScaffold(
      title: 'New School',
      activeRoute: '/platform-onboarding',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 42),
            children: <Widget>[
              const _OnboardingHero(),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 820;
                    final school = _SchoolSetupCard(
                      schoolName: _schoolName,
                      schoolCode: _schoolCode,
                      campusName: _campusName,
                      campusCode: _campusCode,
                      academicYearName: _academicYearName,
                      academicYearStart: _academicYearStart,
                      academicYearEnd: _academicYearEnd,
                      plan: _plan,
                      trialDays: _trialDays,
                      saving: _saving,
                      plans: _plans,
                      requiredValidator: _required,
                      onPlanChanged: (value) => setState(() => _plan = value),
                      onTrialDaysChanged: (value) =>
                          setState(() => _trialDays = value),
                      onPickStart: () => _pickDate(start: true),
                      onPickEnd: () => _pickDate(start: false),
                    );
                    final owner = _OwnerSetupCard(
                      ownerName: _ownerName,
                      ownerEmail: _ownerEmail,
                      password: _password,
                      confirmPassword: _confirmPassword,
                      setupMethod: _setupMethod,
                      passwordVisible: _passwordVisible,
                      saving: _saving,
                      requiredValidator: _required,
                      passwordValidator: _passwordError,
                      onSetupMethodChanged: (value) =>
                          setState(() => _setupMethod = value),
                      onTogglePassword: () => setState(
                        () => _passwordVisible = !_passwordVisible,
                      ),
                      onGeneratePassword: () => setState(_generatePassword),
                    );
                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(child: school),
                          const SizedBox(width: 16),
                          SizedBox(width: 390, child: owner),
                        ],
                      );
                    }
                    return Column(
                      children: <Widget>[
                        school,
                        const SizedBox(height: 16),
                        owner,
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _createSchool,
                icon: _saving
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_business_rounded),
                label: Text(
                  _saving
                      ? 'Creating secure school workspace…'
                      : 'Create school and owner account',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingHero extends StatelessWidget {
  const _OnboardingHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.navigationGradient,
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 34),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Launch a new school workspace',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Creates the isolated tenant, plan, campus, academic year and first School Owner in one trusted operation.',
                  style: TextStyle(
                    color: AppColors.navigationMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SchoolSetupCard extends StatelessWidget {
  const _SchoolSetupCard({
    required this.schoolName,
    required this.schoolCode,
    required this.campusName,
    required this.campusCode,
    required this.academicYearName,
    required this.academicYearStart,
    required this.academicYearEnd,
    required this.plan,
    required this.trialDays,
    required this.saving,
    required this.plans,
    required this.requiredValidator,
    required this.onPlanChanged,
    required this.onTrialDaysChanged,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final TextEditingController schoolName;
  final TextEditingController schoolCode;
  final TextEditingController campusName;
  final TextEditingController campusCode;
  final TextEditingController academicYearName;
  final DateTime academicYearStart;
  final DateTime academicYearEnd;
  final String plan;
  final int trialDays;
  final bool saving;
  final Map<String, String> plans;
  final String? Function(String?, String) requiredValidator;
  final ValueChanged<String> onPlanChanged;
  final ValueChanged<int> onTrialDaysChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _CardTitle(
              icon: Icons.apartment_rounded,
              title: 'School workspace',
              subtitle: 'Tenant identity, plan and default operating context.',
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: schoolName,
              enabled: !saving,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'School name',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              validator: (value) => requiredValidator(value, 'school name'),
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: schoolCode,
              enabled: !saving,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
                LengthLimitingTextInputFormatter(32),
              ],
              decoration: const InputDecoration(
                labelText: 'Unique school code',
                hintText: 'Example: EXAMPLE-DEMO',
                prefixIcon: Icon(Icons.qr_code_rounded),
              ),
              validator: (value) {
                final code = (value ?? '').trim();
                return RegExp(r'^[A-Za-z0-9_-]{2,32}$').hasMatch(code)
                    ? null
                    : 'Use 2-32 letters, numbers, - or _';
              },
            ),
            const SizedBox(height: 13),
            LayoutBuilder(
              builder: (context, constraints) {
                final campusNameField = TextFormField(
                  controller: campusName,
                  enabled: !saving,
                  decoration: const InputDecoration(
                    labelText: 'Main campus name',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (value) =>
                      requiredValidator(value, 'campus name'),
                );
                final campusCodeField = TextFormField(
                  controller: campusCode,
                  enabled: !saving,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Campus code'),
                  validator: (value) =>
                      requiredValidator(value, 'campus code'),
                );
                if (constraints.maxWidth < 390) {
                  return Column(
                    children: <Widget>[
                      campusNameField,
                      const SizedBox(height: 12),
                      campusCodeField,
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    Expanded(child: campusNameField),
                    const SizedBox(width: 10),
                    SizedBox(width: 148, child: campusCodeField),
                  ],
                );
              },
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: academicYearName,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'Academic year',
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
              validator: (value) =>
                  requiredValidator(value, 'academic year'),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final start = _DateButton(
                  label: 'Starts',
                  value: academicYearStart,
                  enabled: !saving,
                  onTap: onPickStart,
                );
                final end = _DateButton(
                  label: 'Ends',
                  value: academicYearEnd,
                  enabled: !saving,
                  onTap: onPickEnd,
                );
                if (constraints.maxWidth < 390) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      start,
                      const SizedBox(height: 10),
                      end,
                    ],
                  );
                }
                return Row(
                  children: <Widget>[
                    Expanded(child: start),
                    const SizedBox(width: 10),
                    Expanded(child: end),
                  ],
                );
              },
            ),
            const SizedBox(height: 13),
            DropdownButtonFormField<String>(
              value: plan,
              decoration: const InputDecoration(
                labelText: 'Initial plan',
                prefixIcon: Icon(Icons.workspace_premium_outlined),
              ),
              items: plans.entries
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(growable: false),
              onChanged: saving
                  ? null
                  : (value) {
                      if (value != null) onPlanChanged(value);
                    },
            ),
            if (plan == 'trial') ...<Widget>[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: trialDays,
                decoration: const InputDecoration(
                  labelText: 'Trial duration',
                  prefixIcon: Icon(Icons.hourglass_top_rounded),
                ),
                items: const <int>[7, 14, 30, 60, 90]
                    .map(
                      (days) => DropdownMenuItem<int>(
                        value: days,
                        child: Text('$days days'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: saving
                    ? null
                    : (value) {
                        if (value != null) onTrialDaysChanged(value);
                      },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OwnerSetupCard extends StatelessWidget {
  const _OwnerSetupCard({
    required this.ownerName,
    required this.ownerEmail,
    required this.password,
    required this.confirmPassword,
    required this.setupMethod,
    required this.passwordVisible,
    required this.saving,
    required this.requiredValidator,
    required this.passwordValidator,
    required this.onSetupMethodChanged,
    required this.onTogglePassword,
    required this.onGeneratePassword,
  });

  final TextEditingController ownerName;
  final TextEditingController ownerEmail;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final OwnerSetupMethod setupMethod;
  final bool passwordVisible;
  final bool saving;
  final String? Function(String?, String) requiredValidator;
  final FormFieldValidator<String> passwordValidator;
  final ValueChanged<OwnerSetupMethod> onSetupMethodChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onGeneratePassword;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _CardTitle(
              icon: Icons.admin_panel_settings_rounded,
              title: 'First School Owner',
              subtitle: 'Only this account can administer the new school.',
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: ownerName,
              enabled: !saving,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Owner name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => requiredValidator(value, 'owner name'),
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: ownerEmail,
              enabled: !saving,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Owner email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (value) {
                final email = (value ?? '').trim();
                return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                    ? null
                    : 'Enter a valid owner email';
              },
            ),
            const SizedBox(height: 16),
            SegmentedButton<OwnerSetupMethod>(
              segments: const <ButtonSegment<OwnerSetupMethod>>[
                ButtonSegment<OwnerSetupMethod>(
                  value: OwnerSetupMethod.emailLink,
                  icon: Icon(Icons.send_rounded),
                  label: Text('Invite'),
                ),
                ButtonSegment<OwnerSetupMethod>(
                  value: OwnerSetupMethod.temporaryPassword,
                  icon: Icon(Icons.password_rounded),
                  label: Text('Demo password'),
                ),
              ],
              selected: <OwnerSetupMethod>{setupMethod},
              onSelectionChanged: saving
                  ? null
                  : (values) => onSetupMethodChanged(values.first),
            ),
            const SizedBox(height: 12),
            if (setupMethod == OwnerSetupMethod.emailLink)
              const _InfoPanel(
                icon: Icons.verified_user_outlined,
                text:
                    'Recommended for real schools. Supabase sends a secure invitation; no password is shared manually.',
              )
            else ...<Widget>[
              TextFormField(
                controller: password,
                enabled: !saving,
                obscureText: !passwordVisible,
                decoration: InputDecoration(
                  labelText: 'Temporary demo password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: passwordVisible ? 'Hide password' : 'Show password',
                    onPressed: onTogglePassword,
                    icon: Icon(
                      passwordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: passwordValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPassword,
                enabled: !saving,
                obscureText: !passwordVisible,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
                validator: (value) => value == password.text
                    ? null
                    : 'Passwords do not match',
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: saving ? null : onGeneratePassword,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Generate strong password'),
              ),
              const SizedBox(height: 10),
              const _InfoPanel(
                icon: Icons.security_rounded,
                text:
                    'The owner must replace this password on first login. Use only for a controlled demo.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatted = '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: const Icon(Icons.event_outlined, size: 18),
      label: Text('$label: $formatted'),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSuccessDialog extends StatelessWidget {
  const _OnboardingSuccessDialog({
    required this.result,
    required this.setupMethod,
    required this.temporaryPassword,
  });

  final PlatformSchoolOnboardingResult result;
  final OwnerSetupMethod setupMethod;
  final String temporaryPassword;

  @override
  Widget build(BuildContext context) {
    final credentials = 'Email: ${result.ownerEmail}\n'
        '${setupMethod == OwnerSetupMethod.temporaryPassword ? 'Temporary password: $temporaryPassword\n' : ''}'
        'School code: ${result.schoolCode}';
    return AlertDialog(
      icon: const Icon(
        Icons.verified_rounded,
        color: AppColors.success,
        size: 38,
      ),
      title: const Text('School workspace created'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _ResultRow(label: 'School code', value: result.schoolCode),
            _ResultRow(label: 'Owner email', value: result.ownerEmail),
            _ResultRow(label: 'Tenant ID', value: result.tenantId),
            const SizedBox(height: 12),
            Text(
              result.existingOwnerAccount
                  ? 'The existing owner account was linked to this school. The owner can switch schools after signing in.'
                  : result.invitationSent
                      ? 'A secure owner invitation was sent by email.'
                      : 'The temporary owner password is ready. First-login password change is required.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: credentials));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Setup details copied.')),
              );
            }
          },
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Copy setup'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
