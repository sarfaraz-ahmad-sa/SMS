import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/Auth_services.dart';
import '../services/UserModel.dart';
import '../services/models/subscription.dart';
import '../services/models/tenant.dart';
import '../services/models/user_role.dart';
import '../services/session_state.dart';
import '../services/tenant_service.dart';
import '../theme/app_theme.dart';
import 'ForgetPassword.dart';
import 'RequestLogin.dart';
import 'home.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    required this.title,
    this.initialMessage,
  }) : super(key: key);

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

  final AuthService _authService = AuthService();
  final TenantService _tenantService = TenantService();

  late final AnimationController _animationController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _passwordVisible = false;
  bool _loading = false;
  bool _googleLoading = false;

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

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    if (widget.initialMessage?.trim().isNotEmpty == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showError(widget.initialMessage!);
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    try {
      final credential = await _authService.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );

      await _completeSignIn(credential);
    } on TenantAccessException catch (error) {
      await _authService.signOut();
      _showError(error.message);
    } on FirebaseAuthException catch (error) {
      _showError(_messageForFirebaseError(error));
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);

    try {
      final credential = await _authService.signInWithGoogle();
      await _completeSignIn(credential);
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
      if (mounted) {
        setState(() => _googleLoading = false);
      }
    }
  }

  Future<void> _completeSignIn(UserCredential credential) async {
    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-available',
        message: 'The authenticated user could not be loaded.',
      );
    }

    final session = await _tenantService.loadSession(firebaseUser);

    final accessibleTenants =
        await _tenantService.getAccessibleTenants(firebaseUser);

    SessionState.instance.setSession(
      user: session.user,
      tenant: session.tenant,
      availableTenants: accessibleTenants.isEmpty
          ? <Tenant>[session.tenant]
          : accessibleTenants,
      activeCampusId: session.activeCampusId,
      activeAcademicYearId: session.activeAcademicYearId,
    );

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Home()),
      (_) => false,
    );
  }

  // Temporary developer login.
  // Sirf debug mode mein show aur execute hoga.
  void _developerLogin() {
    if (!kDebugMode) {
      return;
    }

    const tenant = Tenant(
      id: 'school_demo',
      name: 'Demo Public School',
      code: 'DPS',
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
      email: 'debug@local.test',
      displayName: 'School Owner',
      tenantId: 'school_demo',
      roles: <UserRole>[
        UserRole.schoolOwner,
      ],
      permissions: <String>{
        '*',
      },
      campusIds: <String>[
        'main_campus',
      ],
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
      MaterialPageRoute(builder: (_) => const Home()),
      (_) => false,
    );
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

      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'google-sign-in-cancelled':
        return 'Sign-in was cancelled.';

      default:
        return error.message ?? 'Sign-in failed. Please try again.';
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        28,
                        32,
                        28,
                        28,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: const BoxDecoration(
                                gradient: AppColors.brandGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Welcome back',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Sign in with the account assigned by your school.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 28),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.email,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';

                                if (email.isEmpty) {
                                  return 'Enter your email address';
                                }

                                if (!RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(email)) {
                                  return 'Enter a valid email address';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_passwordVisible,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [
                                AutofillHints.password,
                              ],
                              onFieldSubmitted: (_) {
                                if (!_loading && !_googleLoading) {
                                  _signIn();
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _passwordVisible
                                      ? 'Hide password'
                                      : 'Show password',
                                  icon: Icon(
                                    _passwordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _passwordVisible =
                                          !_passwordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter your password';
                                }

                                return null;
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgetPassword(),
                                    ),
                                  );
                                },
                                child: const Text('Forgot password?'),
                              ),
                            ),
                            const SizedBox(height: 4),
                            ElevatedButton(
                              onPressed: _loading || _googleLoading
                                  ? null
                                  : _signIn,
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Sign in'),
                            ),
                            const SizedBox(height: 16),
                            const Row(
                              children: [
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _loading || _googleLoading
                                  ? null
                                  : _signInWithGoogle,
                              icon: _googleLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.login_rounded),
                              label: const Text(
                                'Continue with Google',
                              ),
                            ),

                            // Temporary bypass button.
                            if (kDebugMode) ...[
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _developerLogin,
                                icon: const Icon(
                                  Icons.developer_mode_rounded,
                                ),
                                label: const Text(
                                  'Temporary Developer Login',
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _loading || _googleLoading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RequestLogin(),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.badge_outlined),
                              label: const Text(
                                'Request a school login ID',
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Powered by CARTZ Link',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
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