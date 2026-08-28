import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/backend_config.dart';
import '../services/Auth_services.dart';
import '../services/UserModel.dart';
import '../services/session_state.dart';
import '../services/models/subscription.dart';
import '../services/models/tenant.dart';
import '../services/models/user_role.dart';
import '../services/tenant_service.dart';
import '../services/school_account_service.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_tenant_service.dart';
import '../theme/app_theme.dart';
import '../Widgets/school_brand.dart';
import 'FirstLoginPasswordScreen.dart';
import 'ForgetPassword.dart';
import 'RequestLogin.dart';
import 'home.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title, this.initialMessage})
      : super(key: key);

  final String title;
  final String? initialMessage;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  final TenantService? _tenantService =
      BackendConfig.isSupabasePrimary ? null : TenantService();
  final SupabaseAuthService? _supabaseAuthService =
      BackendConfig.isSupabasePrimary ? SupabaseAuthService() : null;
  final SupabaseTenantService? _supabaseTenantService =
      BackendConfig.isSupabasePrimary ? SupabaseTenantService() : null;

  late final AnimationController _animationController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _passwordVisible = false;
  bool _loading = false;
  bool _googleLoading = false;

  static const bool _enableDeveloperLogin = bool.fromEnvironment(
    'ENABLE_DEV_LOGIN',
    defaultValue: true,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fade = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    if (widget.initialMessage?.trim().isNotEmpty == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showError(widget.initialMessage!);
      });
    }

    // Web: Google redirect ke baad wapas aane par result handle karo.
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleGoogleRedirectResult();
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (BackendConfig.isSupabasePrimary) {
        await _supabaseAuthService!.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        final session = await _supabaseTenantService!.loadSession();
        final accessibleTenants =
            await _supabaseTenantService.getAccessibleTenants();
        SessionState.instance.setSession(
          user: session.user,
          tenant: session.tenant,
          availableTenants: accessibleTenants.isEmpty
              ? <Tenant>[session.tenant]
              : accessibleTenants,
          activeCampusId: session.activeCampusId,
          activeAcademicYearId: session.activeAcademicYearId,
        );
        try {
          await SchoolAccountService().recordSuccessfulLogin(session.tenant.id);
        } catch (_) {
          // Authentication remains valid if activity tracking is unavailable.
        }
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(
            builder: (_) => session.user.mustChangePassword
                ? const FirstLoginPasswordScreen()
                : const Home(),
          ),
          (_) => false,
        );
        return;
      }
      final credential = await _authService.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await _completeSignIn(credential);
    } on TenantAccessException catch (error) {
      if (BackendConfig.isSupabasePrimary) {
        await _supabaseAuthService!.signOut();
      } else {
        await _authService.signOut();
      }
      _showError(error.message);
    } on FirebaseAuthException catch (error) {
      _showError(_messageForFirebaseError(error));
    } on FirebaseException catch (error) {
      _showError(_messageForFirebaseServiceError(error));
    } catch (error) {
      if (kDebugMode) debugPrint('Email sign-in failed: $error');
      _showError('Login could not be completed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (BackendConfig.isSupabasePrimary) {
      _showError(
        'Google sign-in will be enabled after Supabase provider setup.',
      );
      return;
    }
    setState(() => _googleLoading = true);
    try {
      final credential = await _authService.signInWithGoogle();
      // Web pe yahan credential null hoga kyunki redirect ho raha hai —
      // asli result reload ke baad _handleGoogleRedirectResult() se milega.
      if (credential?.user != null) {
        await _completeSignIn(credential!);
      }
    } on TenantAccessException catch (error) {
      await _authService.signOut();
      _showError(error.message);
    } on FirebaseAuthException catch (error) {
      if (error.code != 'google-sign-in-cancelled') {
        _showError(_messageForFirebaseError(error));
      }
    } catch (_) {
      _showError('Google sign-in failed. Please try again.');
    } finally {
      // Web pe page redirect ho jayega isliye finally shayad na chale;
      // non-web pe loading band karna zaroori hai.
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  // Web: redirect ke baad app dobara load hone par result pakadta hai.
  Future<void> _handleGoogleRedirectResult() async {
    setState(() => _googleLoading = true);
    try {
      final credential = await _authService.getRedirectResultIfAny();
      // credential null ho sakta hai agar user abhi redirect se nahi aaya.
      if (credential?.user != null) {
        await _completeSignIn(credential!);
      }
    } on TenantAccessException catch (error) {
      await _authService.signOut();
      _showError(error.message);
    } on FirebaseAuthException catch (error) {
      if (error.code != 'google-sign-in-cancelled') {
        _showError(_messageForFirebaseError(error));
      }
    } catch (_) {
      // redirect result nahi tha, chup rahe.
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _completeSignIn(UserCredential credential) async {
    final firebaseUser = await _authService.resolveSignedInUser(
      credentialUser: credential.user,
    );
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'auth-state-not-ready',
        message: 'Login succeeded, but the browser session was not ready. '
            'Refresh the page and sign in again.',
      );
    }

    // Refresh the ID token before Firestore membership reads. This avoids a
    // production-only race where rules evaluate an older auth token directly
    // after email/password sign-in.
    await firebaseUser.getIdToken(true);

    final session = await _tenantService!.loadSession(firebaseUser);
    final accessibleTenants = await _tenantService.getAccessibleTenants(
      firebaseUser,
    );
    SessionState.instance.setSession(
      user: session.user,
      tenant: session.tenant,
      availableTenants: accessibleTenants.isEmpty
          ? <Tenant>[session.tenant]
          : accessibleTenants,
      activeCampusId: session.activeCampusId,
      activeAcademicYearId: session.activeAcademicYearId,
    );

    try {
      await SchoolAccountService().recordSuccessfulLogin(session.tenant.id);
    } catch (_) {
      // Login remains valid if optional activity tracking is temporarily unavailable.
    }

    if (!mounted) return;
    final destination = session.user.mustChangePassword
        ? const FirstLoginPasswordScreen()
        : const Home();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => destination),
      (_) => false,
    );
  }

  void _developerLogin() {
    if (!kDebugMode || !_enableDeveloperLogin) return;

    const tenant = Tenant(
      id: 'school_demo',
      name: 'SEEF Demo School',
      code: 'DEMO',
      timezone: 'Asia/Karachi',
      currency: 'PKR',
      activeAcademicYearId: '2026-2027',
      subscription: Subscription(
        tier: SubscriptionTier.enterprise,
        status: SubscriptionStatus.active,
      ),
    );

    const user = UserModel(
      uid: 'debug-school-owner',
      email: 'owner@demo.local',
      displayName: 'School Owner',
      tenantId: 'school_demo',
      roles: <UserRole>[UserRole.schoolOwner],
      permissions: <String>{'*'},
      campusIds: <String>['main_campus'],
      isActive: true,
    );

    SessionState.instance.setSession(
      user: user,
      tenant: tenant,
      availableTenants: const <Tenant>[tenant],
      activeCampusId: 'main_campus',
      activeAcademicYearId: '2026-2027',
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const Home()),
      (Route<dynamic> route) => false,
    );
  }

  String _messageForFirebaseServiceError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Login succeeded, but this account cannot read its school profile. '
            'Deploy the latest Firestore rules and verify the user membership.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'The school service is temporarily unavailable. Check the '
            'internet connection and try again.';
      case 'failed-precondition':
        return error.message ??
            'The school profile is incomplete or requires configuration.';
      default:
        return error.message ??
            'The school profile could not be loaded after login.';
    }
  }

  String _messageForFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account was found for this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email address or password.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'auth-state-not-ready':
      case 'user-not-available':
        return error.message ??
            'Login succeeded, but the browser session was not ready. Try again.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'google-sign-in-cancelled':
        return 'Sign-in was cancelled.';
      default:
        return error.message ?? 'Sign-in failed. Please try again.';
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        color: dark ? AppColors.darkBackground : AppColors.background,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // The brand panel uses a presentation-style flex layout. On a
              // wide but short browser window it cannot fit safely, so use the
              // vertically scrollable compact layout instead.
              final wide =
                  constraints.maxWidth >= 980 && constraints.maxHeight >= 640;
              if (wide) {
                return Row(
                  children: <Widget>[
                    const Expanded(flex: 11, child: _LoginBrandPanel()),
                    Expanded(
                      flex: 9,
                      child: Center(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          primary: false,
                          padding: const EdgeInsets.all(36),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 500),
                            child: FadeTransition(
                              opacity: _fade,
                              child: SlideTransition(
                                position: _slide,
                                child: _buildLoginCard(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Center(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  primary: false,
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 380 ? 14 : 18,
                    vertical: 18,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _slide,
                        child: _buildLoginCard(context),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 20 : 30,
          compact ? 24 : 32,
          compact ? 20 : 30,
          compact ? 20 : 26,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const SchoolBrandMark(size: 54),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'SEEF SCHOOL',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Modern School Management',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Welcome back',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Sign in with the account and role assigned by your school administrator.',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 26),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: (String? value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Enter your email address';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[AutofillHints.password],
                onFieldSubmitted: (_) => _loading ? null : _signIn(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip:
                        _passwordVisible ? 'Hide password' : 'Show password',
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _passwordVisible = !_passwordVisible),
                  ),
                ),
                validator: (String? value) => value == null || value.isEmpty
                    ? 'Enter your password'
                    : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ForgetPassword(),
                    ),
                  ),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 2),
              FilledButton.icon(
                onPressed: _loading || _googleLoading ? null : _signIn,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login_rounded),
                label: Text(_loading ? 'Signing in...' : 'Sign in securely'),
              ),
              if (!BackendConfig.isSupabasePrimary) ...<Widget>[
                const SizedBox(height: 17),
                Row(
                  children: <Widget>[
                    const Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 17),
                OutlinedButton.icon(
                  onPressed:
                      _loading || _googleLoading ? null : _signInWithGoogle,
                  icon: _googleLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.account_circle_outlined),
                  label: const Text('Continue with Google'),
                ),
              ],
              if (!BackendConfig.isSupabasePrimary &&
                  kDebugMode &&
                  _enableDeveloperLogin) ...<Widget>[
                const SizedBox(height: 11),
                FilledButton.tonalIcon(
                  onPressed:
                      _loading || _googleLoading ? null : _developerLogin,
                  icon: const Icon(Icons.developer_mode_rounded),
                  label: const Text('Open full ERP demo'),
                ),
              ],
              if (!BackendConfig.isSupabasePrimary &&
                  BackendConfig.enableSupabaseAuthPilot) ...<Widget>[
                const SizedBox(height: 11),
                OutlinedButton.icon(
                  onPressed: _loading || _googleLoading
                      ? null
                      : () => Navigator.pushNamed(context, '/supabase-auth'),
                  icon: const Icon(Icons.cloud_done_outlined),
                  label: const Text('Open Supabase login pilot'),
                ),
              ],
              const SizedBox(height: 11),
              TextButton.icon(
                onPressed: _loading || _googleLoading
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const RequestLogin(),
                          ),
                        ),
                icon: const Icon(Icons.badge_outlined),
                label: const Text('Request a school login ID'),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Tenant-isolated, role-based access',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.navigationGradient,
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                right: 36,
                top: 42,
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 160,
                  color: Colors.white10,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SchoolBrandLockup(
                      light: true,
                      markSize: 62,
                    ),
                    const Spacer(),
                    const Text(
                      'One intelligent platform\nfor the entire school.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        height: 1.12,
                        letterSpacing: -1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Admissions, academics, fees, HR, parent and student portals—securely separated for every school tenant.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.76),
                        fontSize: 16,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 34),
                    const Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        _LoginFeature(
                          icon: Icons.shield_outlined,
                          label: 'Role permissions',
                        ),
                        _LoginFeature(
                          icon: Icons.apartment_rounded,
                          label: 'Multi-campus',
                        ),
                        _LoginFeature(
                          icon: Icons.insights_outlined,
                          label: 'Live analytics',
                        ),
                        _LoginFeature(
                          icon: Icons.devices_rounded,
                          label: 'Web & mobile',
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'SEEF School ERP  •  Web & Mobile',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginFeature extends StatelessWidget {
  const _LoginFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? Colors.lightBlueAccent.withOpacity(0.12),
      ),
    );
  }
}
