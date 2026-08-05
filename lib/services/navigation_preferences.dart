import 'package:flutter/foundation.dart';

enum DesktopNavigationMode { expanded, compact, hidden }

/// Keeps the desktop sidebar state stable while users move between routes.
/// The three modes support a full menu, a mini icon rail, and a distraction-
/// free hidden workspace.
class NavigationPreferences extends ChangeNotifier {
  NavigationPreferences._();

  static final NavigationPreferences instance = NavigationPreferences._();

  DesktopNavigationMode _desktopMode = DesktopNavigationMode.expanded;

  DesktopNavigationMode get desktopMode => _desktopMode;

  bool get isDesktopVisible => _desktopMode != DesktopNavigationMode.hidden;
  bool get isDesktopCompact => _desktopMode == DesktopNavigationMode.compact;

  void setDesktopMode(DesktopNavigationMode value) {
    if (_desktopMode == value) return;
    _desktopMode = value;
    notifyListeners();
  }

  void toggleDesktopVisibility() {
    setDesktopMode(
      _desktopMode == DesktopNavigationMode.hidden
          ? DesktopNavigationMode.expanded
          : DesktopNavigationMode.hidden,
    );
  }

  void toggleDesktopCompact() {
    setDesktopMode(
      _desktopMode == DesktopNavigationMode.compact
          ? DesktopNavigationMode.expanded
          : DesktopNavigationMode.compact,
    );
  }
}
