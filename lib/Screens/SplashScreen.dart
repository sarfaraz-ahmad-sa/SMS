import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/Auth_services.dart';
import '../services/session_state.dart';
import '../services/models/tenant.dart';
import '../services/tenant_service.dart';
import '../services/school_account_service.dart';
import '../config/backend_config.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_tenant_service.dart';
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
  final TenantService? _tenantService =
      BackendConfig.isSupabasePrimary ? null : TenantService();
  final SupabaseAuthService? _supabaseAuthService =
      BackendConfig.isSupabasePrimary ? SupabaseAuthService() : null;
  final SupabaseTenantService? _supabaseTenantService =
      BackendConfig.isSupabasePrimary ? SupabaseTenantService() : null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_bootstrap());
    });
  }

  Future<void> _bootstrap() async {
    final startedAt = DateTime.now();
    String? loginMessage;

    try {
      if (BackendConfig.isSupabasePrimary) {
        if (_supabaseAuthService!.currentUser == null) {
          SessionState.instance.markInitialized();
          await _waitForBrandAnimation(startedAt);
          _replace(const MyHomePage(title: 'SEEF School ERP'));
          return;
        }
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
          // Session restore remains valid if activity tracking is unavailable.
        }
        await _waitForBrandAnimation(startedAt);
        _replace(
          session.user.mustChangePassword
              ? const FirstLoginPasswordScreen()
              : const Home(),
        );
        return;
      }
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        SessionState.instance.markInitialized();
        await _waitForBrandAnimation(startedAt);
        _replace(const MyHomePage(title: 'SEEF School ERP'));
        return;
      }

      final session = await _tenantService!.loadSession(firebaseUser);
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
      if (BackendConfig.isSupabasePrimary) {
        await _supabaseAuthService!.signOut();
      } else {
        await _authService.signOut();
      }
      SessionState.instance.clear();
    } on FirebaseAuthException catch (error) {
      loginMessage = error.message ?? 'Your session could not be restored.';
      await _authService.signOut();
      SessionState.instance.clear();
    } catch (_) {
      loginMessage =
          'Could not connect to the school service. Please try again.';
      SessionState.instance.clear();
    }

    await _waitForBrandAnimation(startedAt);
    _replace(MyHomePage(
      title: 'SMS',
      initialMessage: loginMessage,
    ));
  }

  Future<void> _waitForBrandAnimation(DateTime startedAt) async {
    const minimumDuration = Duration(milliseconds: 360);
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
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x160F2740),
                        blurRadius: 26,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Positioned(left: 24, top: 28, child: Icon(Icons.person_rounded, color: AppColors.danger, size: 28)),
                      Positioned(right: 23, top: 28, child: Icon(Icons.person_rounded, color: AppColors.info, size: 28)),
                      Positioned(top: 18, child: Icon(Icons.circle, color: AppColors.warning, size: 18)),
                      Positioned(bottom: 20, child: Icon(Icons.menu_book_rounded, color: AppColors.navigation, size: 36)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'SEEF SCHOOL',
                  style: TextStyle(
                    color: AppColors.navigation,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'School Management App',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 42),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    color: AppColors.navigation,
                    strokeWidth: 2.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}