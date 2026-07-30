import 'package:flutter/foundation.dart';

/// Keeps the desktop navigation preference stable while the user moves
/// between named routes. The automatic default still follows screen width.
class NavigationPreferences extends ChangeNotifier {
  NavigationPreferences._();

  static final NavigationPreferences instance = NavigationPreferences._();

  bool? _desktopExpanded;

  bool desktopExpandedFor(double width) {
    return _desktopExpanded ?? width >= 1320;
  }

  void toggleDesktop(double width) {
    _desktopExpanded = !desktopExpandedFor(width);
    notifyListeners();
  }

  void setDesktopExpanded(bool value) {
    if (_desktopExpanded == value) return;
    _desktopExpanded = value;
    notifyListeners();
  }

  void useAutomaticSizing() {
    if (_desktopExpanded == null) return;
    _desktopExpanded = null;
    notifyListeners();
  }
}
