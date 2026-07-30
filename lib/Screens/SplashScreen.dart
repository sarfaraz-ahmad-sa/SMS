import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/Auth_services.dart';
import '../services/session_state.dart';
import '../services/models/tenant.dart';
import '../services/tenant_service.dart';
import '../services/school_account_service.dart';
import '../theme/app_theme.dart';
import 'FirstLoginPasswordScreen.dart';
import 'LoginPage.dart';
import 'home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  final AuthService _authService = AuthService();
  final TenantService _tenantService = TenantService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final startedAt = DateTime.now();
    String? loginMessage;

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        SessionState.instance.markInitialized();
        await _waitForBrandAnimation(startedAt);
        _replace(const MyHomePage(title: 'CARTZ Link School ERP'));
        return;
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

      try {
        await SchoolAccountService().recordSuccessfulLogin(session.tenant.id);
      } catch (_) {
        // Session restore remains valid if login activity tracking is unavailable.
      }

      await _waitForBrandAnimation(startedAt);
      _replace(
        session.user.mustChangePassword
            ? const FirstLoginPasswordScreen()
            : const Home(),
      );
      return;
    } on TenantAccessException catch (error) {
      loginMessage = error.message;
      await _authService.signOut();
      SessionState.instance.clear();
    } on FirebaseAuthException catch (error) {
      loginMessage = error.message ?? 'Your session could not be restored.';
      await _authService.signOut();
      SessionState.instance.clear();
    } catch (_) {
      loginMessage = 'Could not connect to the school service. Please try again.';
      SessionState.instance.clear();
    }

    await _waitForBrandAnimation(startedAt);
    _replace(MyHomePage(
      title: 'SMS',
      initialMessage: loginMessage,
    ));
  }

  Future<void> _waitForBrandAnimation(DateTime startedAt) async {
    const minimumDuration = Duration(milliseconds: 1100);
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < minimumDuration) {
      await Future<void>.delayed(minimumDuration - elapsed);
    }
  }

  void _replace(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        width: double.infinity,
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 72,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'CARTZ Link',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'School ERP & SaaS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
