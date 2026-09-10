import 'package:school_management/config/brand_config.dart';
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
import '../Widgets/school_brand.dart';
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
          _replace(const MyHomePage(title: BrandConfig.appName));
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
        _replace(const MyHomePage(title: BrandConfig.appName));
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
      title: BrandConfig.appName,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SchoolBrandMark(size: 104),
                const SizedBox(height: 24),
                Text(
                  BrandConfig.companyName,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'School Management App',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
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
