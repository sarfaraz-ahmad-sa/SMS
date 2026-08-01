import 'package:firebase_core/firebase_core.dart';
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
import 'Screens/home.dart';
import 'core/erp/erp_entity.dart';
import 'core/erp/erp_module.dart';
import 'firebase_options.dart';
import 'services/session_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
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
          home: const SplashScreen(),
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
