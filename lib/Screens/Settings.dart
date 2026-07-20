import 'package:flutter/material.dart';

import 'package:school_management/services/session_state.dart';
import 'package:school_management/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: SessionState.instance,
        builder: (context, _) {
          final mode = SessionState.instance.themeMode;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Appearance',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('Light'),
                      secondary: const Icon(Icons.light_mode_outlined),
                      value: ThemeMode.light,
                      groupValue: mode,
                      onChanged: _set,
                    ),
                    const Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark'),
                      secondary: const Icon(Icons.dark_mode_outlined),
                      value: ThemeMode.dark,
                      groupValue: mode,
                      onChanged: _set,
                    ),
                    const Divider(height: 1),
                    RadioListTile<ThemeMode>(
                      title: const Text('System default'),
                      secondary: const Icon(Icons.brightness_auto_outlined),
                      value: ThemeMode.system,
                      groupValue: mode,
                      onChanged: _set,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'CARTZ Link SMS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _set(ThemeMode? mode) {
    if (mode != null) SessionState.instance.setThemeMode(mode);
  }
}
