import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fzregex/utils/fzregex.dart';
import 'package:fzregex/utils/pattern.dart';

import 'package:school_management/Screens/home.dart';
import 'package:school_management/services/UserModel.dart';
import 'package:school_management/services/models/user_role.dart';
import 'package:school_management/services/session_state.dart';
import 'package:school_management/services/tenant_service.dart';
import 'package:school_management/theme/app_theme.dart';

import 'ForgetPassword.dart';
import 'RequestLogin.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late final Animation animation, delayedAnimation, muchDelayedAnimation;
  late final Animation leftCurve;

  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TenantService _tenantService = TenantService();

  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  bool _passShow = false;
  bool _loading = false;
  String _pass = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(duration: const Duration(seconds: 3), vsync: this);
    animation = Tween(begin: -1.0, end: 0.0).animate(CurvedAnimation(
        parent: animationController, curve: Curves.fastOutSlowIn));
    delayedAnimation = Tween(begin: -1.0, end: 0.0).animate(CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn)));
    muchDelayedAnimation = Tween(begin: -1.0, end: 0.0).animate(CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.8, 1.0, curve: Curves.fastOutSlowIn)));
    leftCurve = Tween(begin: -1.0, end: 0.0).animate(CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut)));
    animationController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formkey.currentState!.validate()) {
      setState(() => _autoValidateMode = AutovalidateMode.always);
      return;
    }
    _formkey.currentState!.save();
    setState(() => _loading = true);

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: _email.trim(),
        password: _pass,
      );
      final firebaseUser = cred.user;
      if (firebaseUser == null) throw FirebaseAuthException(code: 'unknown');

      // Load the tenant-scoped profile; fall back to a minimal user if the
      // Firestore profile isn't set up yet so login still succeeds.
      final profile = await _tenantService.getUserProfile(firebaseUser.uid) ??
          UserModel(uid: firebaseUser.uid, email: firebaseUser.email);
      final tenant = await _tenantService.getTenant(profile.tenantId);

      if (!mounted) return;
      SessionState.instance.setSession(user: profile, tenant: tenant);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
      );
    } on FirebaseAuthException catch (e) {
      _showError(_messageFor(e.code));
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Demo entry point — skips Firebase auth so the app can be previewed
  /// with any role before real accounts exist. Remove once sign-up is wired up.
  void _continueAsGuest() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Enter demo as…',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 360,
              child: ListView(
                children: UserRole.values
                    .map((r) => ListTile(
                          leading: const Icon(Icons.badge_outlined),
                          title: Text(r.label),
                          onTap: () {
                            Navigator.pop(ctx);
                            _enterAs(r);
                          },
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _enterAs(UserRole role) {
    SessionState.instance.setSession(
      user: UserModel(
        uid: 'demo',
        displayName: '${role.label} (Demo)',
        role: role,
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Home()),
    );
  }

  String _messageFor(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'network-request-failed':
        return 'Network error — check your connection.';
      default:
        return 'Sign in failed. Please try again.';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: AnimatedBuilder(
        animation: animationController,
        builder: (BuildContext context, Widget? child) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            children: <Widget>[
              const SizedBox(height: 60),
              Transform(
                transform:
                    Matrix4.translationValues(animation.value * width, 0, 0),
                child: Row(
                  children: [
                    Text(
                      'Welcome',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '.',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Transform(
                transform:
                    Matrix4.translationValues(animation.value * width, 0, 0),
                child: const Text(
                  'Sign in to your account',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Transform(
                transform:
                    Matrix4.translationValues(leftCurve.value * width, 0, 0),
                child: Form(
                  key: _formkey,
                  autovalidateMode: _autoValidateMode,
                  child: Column(
                    children: [
                      TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your email address';
                          }
                          if (!Fzregex.hasMatch(value, FzPattern.email)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                        onSaved: (value) => _email = value ?? '',
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        obscureText: !_passShow,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_passShow
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () =>
                                setState(() => _passShow = !_passShow),
                          ),
                        ),
                        validator: (val) =>
                            (val == null || val.isEmpty)
                                ? 'Enter your password'
                                : null,
                        onSaved: (val) => _pass = val ?? '',
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ForgetPassword()),
                  ),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 8),
              Transform(
                transform: Matrix4.translationValues(
                    muchDelayedAnimation.value * width, 0, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signIn,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Login'),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RequestLogin()),
                  ),
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Request Login ID'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: _continueAsGuest,
                  icon: const Icon(Icons.explore_outlined, size: 18),
                  label: const Text('Continue as Guest (Demo)'),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: Text(
                  'Powered by CARTZ Link',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
