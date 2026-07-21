import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'Screens/SplashScreen.dart';
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
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionState.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'SMS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: SessionState.instance.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
