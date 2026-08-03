import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'UserModel.dart';
import 'models/tenant.dart';
import '../config/backend_config.dart';
import 'supabase_bootstrap.dart';

class SessionState extends ChangeNotifier {
  SessionState._();

  static final SessionState instance = SessionState._();

  UserModel? _user;
  Tenant? _tenant;
  List<Tenant> _availableTenants = const <Tenant>[];
  String? _activeCampusId;
  String? _activeAcademicYearId;
  bool _initialized = false;
  bool _switchingTenant = false;
  ThemeMode _themeMode = ThemeMode.light;

  UserModel? get user => _user;
  Tenant? get tenant => _tenant;
  List<Tenant> get availableTenants =>
      List<Tenant>.unmodifiable(_availableTenants);
  String? get activeCampusId => _activeCampusId;
  String? get activeAcademicYearId => _activeAcademicYearId;
  bool get initialized => _initialized;
  bool get switchingTenant => _switchingTenant;
  ThemeMode get themeMode => _themeMode;

  bool get isSignedIn => _user != null && _tenant != null;
  bool get canSwitchTenant => _availableTenants.length > 1;

  void setSession({
    required UserModel user,
    required Tenant tenant,
    List<Tenant>? availableTenants,
    String? activeCampusId,
    String? activeAcademicYearId,
  }) {
    _user = user;
    _tenant = tenant;
    if (availableTenants != null) {
      _availableTenants = List<Tenant>.unmodifiable(availableTenants);
    } else if (_availableTenants.isEmpty) {
      _availableTenants = <Tenant>[tenant];
    }
    _activeCampusId = activeCampusId ??
        (user.campusIds.isNotEmpty ? user.campusIds.first : null);
    _activeAcademicYearId = activeAcademicYearId ?? tenant.activeAcademicYearId;
    _themeMode = _themeModeFromName(user.themeMode);
    _initialized = true;
    _switchingTenant = false;
    notifyListeners();
  }

  void updateTenant(Tenant tenant) {
    if (_tenant?.id != tenant.id) {
      throw StateError('Cannot replace the active school with another tenant.');
    }
    _tenant = tenant;
    _availableTenants = _availableTenants
        .map((Tenant item) => item.id == tenant.id ? tenant : item)
        .toList(growable: false);
    _activeAcademicYearId = tenant.activeAcademicYearId;
    notifyListeners();
  }

  void updateUser(UserModel user) {
    if (_user?.uid != user.uid) {
      throw StateError('Cannot replace the active session with another user.');
    }
    _user = user;
    notifyListeners();
  }

  void setSwitchingTenant(bool value) {
    _switchingTenant = value;
    notifyListeners();
  }

  void setActiveCampus(String? campusId) {
    if (campusId != null &&
        _user != null &&
        _user!.campusIds.isNotEmpty &&
        !_user!.campusIds.contains(campusId)) {
      throw StateError('You do not have access to this campus.');
    }
    _activeCampusId = campusId;
    notifyListeners();
  }

  void setActiveAcademicYear(String? academicYearId) {
    _activeAcademicYearId = academicYearId;
    notifyListeners();
  }

  bool hasPermission(String permission) {
    return _user?.hasPermission(permission) ?? false;
  }

  bool hasAnyPermission(Iterable<String> permissions) {
    return _user?.hasAnyPermission(permissions) ?? false;
  }

  void markInitialized() {
    if (_initialized) return;
    _initialized = true;
    notifyListeners();
  }

  void clear() {
    _user = null;
    _tenant = null;
    _availableTenants = const <Tenant>[];
    _activeCampusId = null;
    _activeAcademicYearId = null;
    _initialized = true;
    _switchingTenant = false;
    notifyListeners();
  }

  void toggleTheme() {
    setThemeMode(
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    if (_user != null) {
      _user = _user!.copyWith(themeMode: mode.name);
    }
    notifyListeners();
    if (BackendConfig.isSupabasePrimary) {
      final uid = SupabaseBootstrap.client.auth.currentUser?.id;
      if (uid != null) {
        unawaited(
          SupabaseBootstrap.client
              .from('profiles')
              .update(<String, dynamic>{
                'theme_mode': mode.name,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('user_id', uid)
              .then<void>((_) {})
              .catchError((Object _) {}),
        );
      }
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      unawaited(
        FirebaseFirestore.instance.collection('users').doc(uid).set(
          <String, dynamic>{
            'themeMode': mode.name,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        ).catchError((Object _) {}),
      );
    }
  }

  ThemeMode _themeModeFromName(String value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light,
    };
  }
}
