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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!BackendConfig.isSupabasePrimary) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _activateFirebaseAppCheck();
  }
  if (BackendConfig.shouldInitializeSupabase) {
    await SupabaseBootstrap.initializeClient();
    SupabaseErrorReporter.install();
  }
  runApp(const MyApp());
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
          title: 'SEEF SMS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightFor(state.tenant),
          darkTheme: AppTheme.darkFor(state.tenant),
          themeMode: state.themeMode,
          home: _initialScreen(),
          routes: <String, WidgetBuilder>{
            '/login': (_) => const MyHomePage(title: 'SEEF SMS'),
            '/home': (_) => const Home(),
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
