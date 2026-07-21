import 'package:flutter/material.dart';

import 'UserModel.dart';
import 'models/tenant.dart';

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
  List<Tenant> get availableTenants => List<Tenant>.unmodifiable(_availableTenants);
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
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
