import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:school_management/Screens/SplashScreen.dart';
import 'package:school_management/services/session_state.dart';
import 'package:school_management/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase once, here, using the generated options.
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
          title: 'CARTZ Link SMS',
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
