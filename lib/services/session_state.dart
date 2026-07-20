import 'package:flutter/material.dart';

import 'UserModel.dart';
import 'models/tenant.dart';

/// App-wide session state: who is signed in, which tenant they belong to,
/// and the active theme mode.
///
/// Implemented as a [ChangeNotifier] singleton (no external state-management
/// package required). Read it anywhere via `SessionState.instance`, and rebuild
/// on changes with `ListenableBuilder(listenable: SessionState.instance, ...)`.
class SessionState extends ChangeNotifier {
  SessionState._();
  static final SessionState instance = SessionState._();

  UserModel? _user;
  Tenant? _tenant;
  ThemeMode _themeMode = ThemeMode.light; // default to light

  UserModel? get user => _user;
  Tenant? get tenant => _tenant;
  ThemeMode get themeMode => _themeMode;
  bool get isSignedIn => _user != null;

  void setSession({required UserModel user, Tenant? tenant}) {
    _user = user;
    _tenant = tenant;
    notifyListeners();
  }

  void clear() {
    _user = null;
    _tenant = null;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
