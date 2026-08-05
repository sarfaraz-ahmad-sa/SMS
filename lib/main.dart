import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'Screens/AccountManagement.dart';
import 'Screens/Enterprise/ErpEntityListScreen.dart';
import 'Screens/Enterprise/ErpModuleScreen.dart';
import 'Screens/FirstLoginPasswordScreen.dart';
import 'Screens/GlobalSearch.dart';
import 'Screens/LoginPage.dart';
import 'Screens/ModulesHub.dart';
import 'Screens/Notifications.dart';
import 'Screens/Profile.dart';
import 'Screens/Saas/approval_inbox_screen.dart';
import 'Screens/Saas/saas_control_center_screen.dart';
import 'Screens/Saas/tenant_onboarding_screen.dart';
import 'Screens/Settings.dart';
import 'Screens/SplashScreen.dart';
import 'Screens/Supabase/supabase_auth_pilot_screen.dart';
import 'Screens/Supabase/supabase_password_setup_screen.dart';
import 'Screens/home.dart';
import 'config/backend_config.dart';
import 'core/erp/erp_entity.dart';
import 'core/erp/erp_module.dart';
import 'firebase_options.dart';
import 'services/session_state.dart';
import 'services/supabase_bootstrap.dart';
import 'services/supabase_error_reporter.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BackendBootstrapHost());
}

class _BackendBootstrapHost extends StatefulWidget {
  const _BackendBootstrapHost();

  @override
  State<_BackendBootstrapHost> createState() => _BackendBootstrapHostState();
}

class _BackendBootstrapHostState extends State<_BackendBootstrapHost> {
  late Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _initializeBackends();
  }

  Future<void> _initializeBackends() async {
    final tasks = <Future<void>>[];
    if (!BackendConfig.isSupabasePrimary) {
      tasks.add(() async {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        await _activateFirebaseAppCheck();
      }());
    }
    if (BackendConfig.shouldInitializeSupabase) {
      tasks.add(() async {
        await SupabaseBootstrap.initializeClient();
        SupabaseErrorReporter.install();
      }());
    }
    await Future.wait(tasks);
  }

  void _retry() {
    setState(() => _bootstrapFuture = _initializeBackends());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return const MyApp();
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightFor(null),
          home: Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: snapshot.hasError
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.cloud_off_rounded,
                              size: 46,
                              color: AppColors.danger,
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Could not start the school workspace.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _retry,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                          ],
                        )
                      : const _FastStartupView(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FastStartupView extends StatelessWidget {
  const _FastStartupView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.navigation,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: SizedBox(
            width: 72,
            height: 72,
            child: Icon(Icons.school_rounded, color: Colors.white, size: 34),
          ),
        ),
        SizedBox(height: 18),
        Text(
          'SEEF School ERP',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 6),
        Text(
          'Starting your workspace…',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        SizedBox(height: 22),
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.3),
        ),
      ],
    );
  }
}

Future<void> _activateFirebaseAppCheck() async {
  const webSiteKey = String.fromEnvironment(
    'FIREBASE_APPCHECK_RECAPTCHA_KEY',
  );

  if (kIsWeb && webSiteKey.isEmpty) {
    if (kReleaseMode) {
      throw StateError(
        'FIREBASE_APPCHECK_RECAPTCHA_KEY is required for production web builds.',
      );
    }
    // Local web development can still render the unauthenticated demo. Supply
    // the dart define when exercising Firebase-backed flows.
    return;
  }

  await FirebaseAppCheck.instance.activate(
    webProvider: kIsWeb ? ReCaptchaV3Provider(webSiteKey) : null,
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode
        ? AppleProvider.debug
        : AppleProvider.appAttestWithDeviceCheckFallback,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionState.instance,
      builder: (BuildContext context, Widget? child) {
        final state = SessionState.instance;
        return MaterialApp(
          title: 'SEEF School ERP',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightFor(state.tenant),
          darkTheme: AppTheme.darkFor(state.tenant),
          themeMode: state.themeMode,
          home: _initialScreen(),
          routes: <String, WidgetBuilder>{
            '/login': (_) => const MyHomePage(title: 'SEEF School ERP'),
            '/home': (_) => const Home(),
            '/modules': (_) => const ModulesHubScreen(),
            '/secure-account': (_) => const FirstLoginPasswordScreen(),
            '/profile': (_) => const ProfileScreen(),
            '/notifications': (_) => const NotificationsScreen(),
            '/settings': (_) => const SettingsScreen(),
            '/search': (_) => const GlobalSearchScreen(),
            '/accounts': (_) => const AccountManagementScreen(),
            '/saas': (_) => const SaasControlCenterScreen(),
            '/onboarding': (_) => const TenantOnboardingScreen(),
            '/approvals': (_) => const ApprovalInboxScreen(),
            '/supabase-auth': (_) => const SupabaseAuthPilotScreen(),
            '/supabase-password-setup': (_) =>
                const SupabasePasswordSetupScreen(),
          },
          onGenerateRoute: (RouteSettings settings) {
            if (settings.name == '/erp-module' &&
                settings.arguments is ErpModule) {
              final module = settings.arguments! as ErpModule;
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => ErpModuleScreen(module: module),
              );
            }
            if (settings.name == '/erp-entity' &&
                settings.arguments is ErpEntity) {
              final entity = settings.arguments! as ErpEntity;
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => ErpEntityListScreen(entity: entity),
              );
            }
            return null;
          },
        );
      },
    );
  }
}

Widget _initialScreen() {
  if (BackendConfig.isSupabasePrimary) {
    final uri = Uri.base;
    final fragment = uri.fragment;
    final callbackType = uri.queryParameters['type'];
    final isPasswordCallback =
        uri.queryParameters['code']?.isNotEmpty == true ||
            callbackType == 'invite' ||
            callbackType == 'recovery' ||
            fragment.contains('type=invite') ||
            fragment.contains('type=recovery');
    if (isPasswordCallback) return const SupabasePasswordSetupScreen();
    return const SplashScreen();
  }
  if (!BackendConfig.enableSupabaseAuthPilot) return const SplashScreen();

  final uri = Uri.base;
  final fragment = uri.fragment;
  final fragmentPath = fragment.split('?').first;
  if (fragmentPath == '/supabase-password-setup') {
    return const SupabasePasswordSetupScreen();
  }
  final callbackType = uri.queryParameters['type'];
  final isPasswordCallback = uri.queryParameters['code']?.isNotEmpty == true ||
      callbackType == 'invite' ||
      callbackType == 'recovery' ||
      fragment.contains('type=invite') ||
      fragment.contains('type=recovery');
  if (isPasswordCallback) return const SupabasePasswordSetupScreen();
  if (fragmentPath == '/supabase-auth') {
    return const SupabaseAuthPilotScreen();
  }
  return const SplashScreen();
}
