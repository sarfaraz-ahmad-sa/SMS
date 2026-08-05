import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Widgets/solid_auth_shell.dart';
import '../../config/backend_config.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/supabase_student_service.dart';
import '../../services/supabase_tenant_service.dart';
import '../../services/tenant_service.dart';
import '../../theme/app_theme.dart';

class SupabaseAuthPilotScreen extends StatefulWidget {
  const SupabaseAuthPilotScreen({super.key});

  @override
  State<SupabaseAuthPilotScreen> createState() =>
      _SupabaseAuthPilotScreenState();
}

class _SupabaseAuthPilotScreenState extends State<SupabaseAuthPilotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final SupabaseAuthService _auth;
  late final SupabaseTenantService _tenants;
  late final SupabaseStudentService _students;

  bool _loading = false;
  bool _passwordVisible = false;
  String? _authenticatedEmail;
  TenantSession? _tenantSession;
  SupabaseStudentPage? _studentPage;
  String? _sessionError;
  String? _studentError;

  @override
  void initState() {
    super.initState();
    _auth = SupabaseAuthService();
    _tenants = SupabaseTenantService();
    _students = SupabaseStudentService();
    _authenticatedEmail = _auth.currentUser?.email;
    if (_auth.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadTenantSession());
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final response = await _auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _authenticatedEmail = response.user?.email);
      await _loadTenantSession(showSuccess: true);
    } on AuthException catch (error) {
      _showMessage(error.message, error: true);
    } catch (_) {
      _showMessage('Could not connect to Supabase Auth.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      _showMessage('Enter a valid email address first.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.sendPasswordReset(email);
      _showMessage('Password reset email sent.');
    } on AuthException catch (error) {
      _showMessage(error.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      setState(() {
        _authenticatedEmail = null;
        _tenantSession = null;
        _studentPage = null;
        _sessionError = null;
        _studentError = null;
      });
    }
  }

  Future<void> _loadTenantSession({bool showSuccess = false}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _sessionError = null;
    });
    try {
      final session = await _tenants.loadSession();
      if (!mounted) return;
      setState(() => _tenantSession = session);
      await _loadStudents(session);
      if (showSuccess) {
        _showMessage('Authentication and school access verified.');
      }
    } on TenantAccessException catch (error) {
      if (!mounted) return;
      setState(() {
        _tenantSession = null;
        _sessionError = error.message;
      });
      _showMessage(error.message, error: true);
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(() {
        _tenantSession = null;
        _sessionError = 'School access could not be verified (${error.code}).';
      });
      _showMessage(_sessionError!, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadStudents(
    TenantSession session, {
    bool loadMore = false,
  }) async {
    final campusId = session.activeCampusId;
    final academicYearId = session.activeAcademicYearId;
    if (campusId == null || academicYearId == null) {
      if (mounted) {
        setState(() => _studentError =
            'Campus and academic year are required for student access.');
      }
      return;
    }
    try {
      final previous = loadMore ? _studentPage : null;
      final page = await _students.fetchPage(
        tenantId: session.tenant.id,
        campusId: campusId,
        academicYearId: academicYearId,
        pageSize: 20,
        afterId: previous?.nextCursor,
      );
      if (!mounted) return;
      setState(() {
        _studentError = null;
        _studentPage = previous == null
            ? page
            : SupabaseStudentPage(
                records: <SupabaseStudentRecord>[
                  ...previous.records,
                  ...page.records,
                ],
                hasMore: page.hasMore,
                nextCursor: page.nextCursor,
              );
      });
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(() => _studentError =
          'Student access could not be verified (${error.code}).');
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.danger : AppColors.success,
        ),
      );
  }

  bool _isValidEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

  @override
  Widget build(BuildContext context) {
    if (!BackendConfig.enableSupabaseAuthPilot) {
      return const SolidAuthShell(
        icon: Icons.block_rounded,
        eyebrow: 'Unavailable',
        title: 'Supabase pilot disabled',
        subtitle: 'The PostgreSQL authentication pilot is not enabled for this build.',
        child: SizedBox.shrink(),
      );
    }

    final authenticated = _authenticatedEmail != null;
    return SolidAuthShell(
      icon: authenticated ? Icons.verified_user_rounded : Icons.cloud_done_rounded,
      eyebrow: 'Migration workspace',
      title: authenticated ? 'Authentication verified' : 'Supabase pilot login',
      subtitle: authenticated
          ? 'Review the resolved school scope and PostgreSQL student access below.'
          : 'Validate the new PostgreSQL authentication flow without changing the live Firebase session.',
      maxWidth: 650,
      child: authenticated ? _buildAuthenticatedState() : _buildLoginForm(),
    );
  }

  Widget _buildAuthenticatedState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.pastelGreen,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.verified_rounded, color: AppColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _authenticatedEmail!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_loading && _tenantSession == null)
          const Center(child: CircularProgressIndicator())
        else if (_tenantSession != null)
          _buildTenantSummary(_tenantSession!)
        else
          _buildSessionError(),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _loading ? null : _signOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out from pilot'),
        ),
      ],
    );
  }

  Widget _buildTenantSummary(TenantSession session) {
    final campus = session.activeCampusId ?? 'Not configured';
    final academicYear = session.activeAcademicYearId ?? 'Not configured';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(session.tenant.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            _contextRow(
                Icons.admin_panel_settings_outlined, session.user.roleLabel),
            _contextRow(Icons.location_city_outlined, campus),
            _contextRow(Icons.calendar_month_outlined, academicYear),
            const Divider(height: 22),
            _buildStudentPilot(session),
            const SizedBox(height: 10),
            const Text(
              'PostgreSQL tenant isolation and role access are verified. '
              'Firebase remains the live dashboard data source during migration.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentPilot(TenantSession session) {
    if (_studentError != null) {
      return Row(
        children: <Widget>[
          const Icon(Icons.error_outline_rounded,
              size: 19, color: AppColors.danger),
          const SizedBox(width: 9),
          Expanded(
            child: Text(_studentError!,
                style: const TextStyle(color: AppColors.danger)),
          ),
          IconButton(
            tooltip: 'Retry students',
            onPressed: _loading ? null : () => _loadStudents(session),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      );
    }
    final page = _studentPage;
    if (page == null) {
      return const Row(
        children: <Widget>[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Loading scoped students...'),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'PostgreSQL students (${page.records.length})',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        if (page.records.isEmpty)
          const Text('No active students in this scope.')
        else
          for (final student in page.records)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${student.admissionNo} · ${student.fullName}'),
            ),
        if (page.hasMore)
          TextButton.icon(
            onPressed: _loading
                ? null
                : () => _loadStudents(
                      session,
                      loadMore: true,
                    ),
            icon: const Icon(Icons.expand_more_rounded),
            label: const Text('Load more'),
          ),
      ],
    );
  }

  Widget _contextRow(IconData icon, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 19, color: AppColors.primary),
            const SizedBox(width: 9),
            Expanded(child: Text(value)),
          ],
        ),
      );

  Widget _buildSessionError() => Column(
        children: <Widget>[
          Text(
            _sessionError ?? 'School session has not loaded yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.danger),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _loading ? null : _loadTenantSession,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry school access'),
          ),
        ],
      );

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const <String>[AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: (value) => _isValidEmail(value?.trim() ?? '')
                ? null
                : 'Enter a valid email address',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: !_passwordVisible,
            autofillHints: const <String>[AutofillHints.password],
            onFieldSubmitted: (_) => _loading ? null : _signIn(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
                icon: Icon(_passwordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
              ),
            ),
            validator: (value) => (value?.length ?? 0) < 8
                ? 'Password must contain at least 8 characters'
                : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loading ? null : _sendReset,
              child: const Text('Send recovery email'),
            ),
          ),
          FilledButton.icon(
            onPressed: _loading ? null : _signIn,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.login_rounded),
            label: Text(_loading ? 'Signing in...' : 'Sign in'),
          ),
        ],
      ),
    );
  }
}
