import 'package:flutter/material.dart';

import '../services/models/app_permission.dart';
import '../services/navigation_preferences.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';
import 'MainDrawer.dart';
import 'TenantSwitcher.dart';
import 'school_context_switcher.dart';

class SaasScaffold extends StatelessWidget {
  static const double desktopBreakpoint = 1024;
  static const double tabletBreakpoint = 720;
  static const double expandedSidebarWidth = 260;
  static const double compactSidebarWidth = 78;

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final String activeRoute;
  final String? activeModuleId;
  final String? activeEntityCollection;
  final bool showContextSwitcher;

  const SaasScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const <Widget>[],
    this.floatingActionButton,
    this.activeRoute = '',
    this.activeModuleId,
    this.activeEntityCollection,
    this.showContextSwitcher = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth >= desktopBreakpoint) {
          return _DesktopShell(
            title: title,
            body: body,
            actions: actions,
            floatingActionButton: floatingActionButton,
            activeRoute: activeRoute,
            activeModuleId: activeModuleId,
            activeEntityCollection: activeEntityCollection,
            showContextSwitcher: showContextSwitcher,
          );
        }
        return _MobileTabletShell(
          title: title,
          body: body,
          actions: actions,
          floatingActionButton: floatingActionButton,
          activeRoute: activeRoute,
          activeModuleId: activeModuleId,
          activeEntityCollection: activeEntityCollection,
          showContextSwitcher: showContextSwitcher,
          tablet: constraints.maxWidth >= tabletBreakpoint,
        );
      },
    );
  }
}

class _DesktopShell extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final String activeRoute;
  final String? activeModuleId;
  final String? activeEntityCollection;
  final bool showContextSwitcher;

  const _DesktopShell({
    required this.title,
    required this.body,
    required this.actions,
    required this.floatingActionButton,
    required this.activeRoute,
    required this.activeModuleId,
    required this.activeEntityCollection,
    required this.showContextSwitcher,
  });

  @override
  Widget build(BuildContext context) {
    final navigation = NavigationPreferences.instance;
    return ListenableBuilder(
      listenable: navigation,
      builder: (BuildContext context, Widget? child) {
        final visible = navigation.isDesktopVisible;
        final compact = navigation.isDesktopCompact;
        final sidebarWidth = !visible
            ? 0.0
            : compact
                ? SaasScaffold.compactSidebarWidth
                : SaasScaffold.expandedSidebarWidth;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          floatingActionButton: floatingActionButton,
          body: SafeArea(
            child: Row(
              children: <Widget>[
                if (visible)
                  SizedBox(
                    width: sidebarWidth,
                    child: MainDrawer(
                      embedded: true,
                      compact: compact,
                      activeRoute: activeRoute,
                      activeModuleId: activeModuleId,
                      activeEntityCollection: activeEntityCollection,
                      onToggleCompact: navigation.toggleDesktopCompact,
                      onClose: () => navigation.setDesktopMode(DesktopNavigationMode.hidden),
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      _DesktopTopBar(
                        title: title,
                        actions: actions,
                        showContextSwitcher: showContextSwitcher,
                        sidebarVisible: visible,
                        sidebarCompact: compact,
                        onToggleSidebar: navigation.toggleDesktopVisibility,
                      ),
                      Expanded(
                        child: ColoredBox(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: body,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final bool showContextSwitcher;
  final bool sidebarVisible;
  final bool sidebarCompact;
  final VoidCallback onToggleSidebar;

  const _DesktopTopBar({
    required this.title,
    required this.actions,
    required this.showContextSwitcher,
    required this.sidebarVisible,
    required this.sidebarCompact,
    required this.onToggleSidebar,
  });

  @override
  Widget build(BuildContext context) {
    final state = SessionState.instance;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final showContextControls = showContextSwitcher && viewportWidth >= 1450;
    final showProfileDetails = viewportWidth >= 1240;
    final showCustomActions = viewportWidth >= 1320;
    final displayName = state.user?.displayName?.trim();
    final name = displayName?.isNotEmpty == true ? displayName! : 'User';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .take(2)
        .map((String part) => part[0].toUpperCase())
        .join();

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x080F2740), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: <Widget>[
          _TopBarActionButton(
            tooltip: sidebarVisible ? 'Close sidebar' : 'Open sidebar',
            icon: sidebarVisible ? Icons.menu_open_rounded : Icons.menu_rounded,
            onPressed: onToggleSidebar,
            active: !sidebarVisible,
          ),
          const SizedBox(width: 8),
          if (Navigator.canPop(context)) ...<Widget>[
            _TopBarActionButton(
              tooltip: 'Back',
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: viewportWidth >= 1320
                ? sidebarCompact
                    ? 205
                    : 230
                : 155,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  sidebarVisible
                      ? sidebarCompact
                          ? 'Mini workspace navigation'
                          : 'School management workspace'
                      : 'Focus mode · sidebar hidden',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: TextField(
                  readOnly: true,
                  onTap: () => Navigator.pushNamed(context, '/search'),
                  decoration: InputDecoration(
                    hintText: 'Search students, teachers, modules or documents...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          if (showContextControls) ...<Widget>[
            const SchoolContextSwitcher(compact: true),
            const SizedBox(width: 8),
            const TenantSwitcher(compact: true),
            const SizedBox(width: 6),
          ],
          _TopBarActionButton(
            tooltip: 'Notifications',
            icon: Icons.notifications_none_rounded,
            onPressed: state.hasPermission(AppPermission.notificationsView)
                ? () => Navigator.pushNamed(context, '/notifications')
                : null,
          ),
          const SizedBox(width: 5),
          _TopBarActionButton(
            tooltip: 'Switch theme',
            icon: Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            onPressed: state.toggleTheme,
          ),
          if (showCustomActions && actions.isNotEmpty) ...<Widget>[
            const SizedBox(width: 5),
            ...actions.take(2),
          ],
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.pastelGold,
                      child: Text(
                        initials.isEmpty ? 'U' : initials,
                        style: const TextStyle(
                          color: AppColors.navigation,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (showProfileDetails) ...<Widget>[
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 118),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.2, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              state.user?.roleLabel ?? 'School user',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10.2, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 17, color: AppColors.textSecondary),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;

  const _TopBarActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? AppColors.pastelBlue : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: onPressed == null
                  ? Theme.of(context).disabledColor
                  : active
                      ? AppColors.navigation
                      : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileTabletShell extends StatefulWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final String activeRoute;
  final String? activeModuleId;
  final String? activeEntityCollection;
  final bool showContextSwitcher;
  final bool tablet;

  const _MobileTabletShell({
    required this.title,
    required this.body,
    required this.actions,
    required this.floatingActionButton,
    required this.activeRoute,
    required this.activeModuleId,
    required this.activeEntityCollection,
    required this.showContextSwitcher,
    required this.tablet,
  });

  @override
  State<_MobileTabletShell> createState() => _MobileTabletShellState();
}

class _MobileTabletShellState extends State<_MobileTabletShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    final state = SessionState.instance;
    final canPop = Navigator.canPop(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawerScrimColor: const Color(0x7A172331),
      drawer: Drawer(
        elevation: 0,
        width: widget.tablet ? 360 : MediaQuery.sizeOf(context).width * 0.90,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: MainDrawer(
          activeRoute: widget.activeRoute,
          activeModuleId: widget.activeModuleId,
          activeEntityCollection: widget.activeEntityCollection,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
      appBar: AppBar(
        leadingWidth: 54,
        leading: IconButton(
          tooltip: canPop ? 'Back' : 'Open menu',
          onPressed: canPop ? () => Navigator.pop(context) : _openDrawer,
          icon: Icon(
            canPop ? Icons.arrow_back_ios_new_rounded : Icons.menu_rounded,
            size: 20,
          ),
        ),
        titleSpacing: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (widget.tablet)
              const Text(
                'School management workspace',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: <Widget>[
          if (canPop)
            IconButton(
              tooltip: 'Open menu',
              onPressed: _openDrawer,
              icon: const Icon(Icons.menu_open_rounded, size: 21),
            ),
          IconButton(
            tooltip: 'Search',
            onPressed: () => _navigate(context, '/search', widget.activeRoute),
            icon: const Icon(Icons.search_rounded, size: 21),
          ),
          if (widget.actions.isNotEmpty)
            ...widget.actions.take(1)
          else if (state.hasPermission(AppPermission.notificationsView))
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => _navigate(context, '/notifications', widget.activeRoute),
              icon: const Icon(Icons.notifications_none_rounded, size: 21),
            ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            if (widget.showContextSwitcher && widget.tablet)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: const SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      SchoolContextSwitcher(),
                      SizedBox(width: 8),
                      TenantSwitcher(),
                    ],
                  ),
                ),
              ),
            Expanded(child: widget.body),
          ],
        ),
      ),
      bottomNavigationBar: _SolidBottomNavigation(
        activeRoute: widget.activeRoute,
        onOpenMenu: _openDrawer,
      ),
    );
  }
}

class _SolidBottomNavigation extends StatelessWidget {
  final String activeRoute;
  final VoidCallback onOpenMenu;

  const _SolidBottomNavigation({required this.activeRoute, required this.onOpenMenu});

  @override
  Widget build(BuildContext context) {
    final selected = _mobileSelectedIndex(activeRoute);
    const items = <_BottomItem>[
      _BottomItem(Icons.home_outlined, Icons.home_rounded, 'Home', '/home'),
      _BottomItem(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Modules', '/modules'),
      _BottomItem(Icons.search_rounded, Icons.search_rounded, 'Search', '/search'),
      _BottomItem(Icons.notifications_none_rounded, Icons.notifications_rounded, 'Alerts', '/notifications'),
      _BottomItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile', '/profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x140F2740), blurRadius: 20, offset: Offset(0, -6)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            children: List<Widget>.generate(items.length, (int index) {
              final item = items[index];
              final isSelected = index == selected;
              final isCenter = index == 2;
              return Expanded(
                child: Semantics(
                  selected: isSelected,
                  button: true,
                  label: item.label,
                  child: InkWell(
                    onTap: () {
                      if (item.route == '/modules' && activeRoute == '/modules') {
                        onOpenMenu();
                        return;
                      }
                      _navigate(context, item.route, activeRoute);
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        if (isSelected && !isCenter)
                          const Positioned(
                            top: 0,
                            child: SizedBox(
                              width: 28,
                              height: 3,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.navigation,
                                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
                                ),
                              ),
                            ),
                          ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              width: isCenter ? 43 : 34,
                              height: isCenter ? 43 : 32,
                              decoration: BoxDecoration(
                                color: isCenter
                                    ? AppColors.navigation
                                    : isSelected
                                        ? AppColors.pastelBlue
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(isCenter ? 14 : 10),
                                boxShadow: isCenter
                                    ? const <BoxShadow>[
                                        BoxShadow(
                                          color: Color(0x30435C73),
                                          blurRadius: 12,
                                          offset: Offset(0, 5),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                isSelected ? item.selectedIcon : item.icon,
                                size: isCenter ? 21 : 19,
                                color: isCenter
                                    ? Colors.white
                                    : isSelected
                                        ? AppColors.navigation
                                        : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 9.4,
                                height: 1,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                color: isCenter
                                    ? AppColors.navigation
                                    : isSelected
                                        ? AppColors.navigation
                                        : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  const _BottomItem(this.icon, this.selectedIcon, this.label, this.route);
}

int _mobileSelectedIndex(String activeRoute) {
  if (activeRoute == '/home') return 0;
  if (activeRoute == '/search') return 2;
  if (activeRoute == '/notifications') return 3;
  if (activeRoute == '/profile' || activeRoute == '/settings' || activeRoute == '/accounts') {
    return 4;
  }
  return 1;
}

void _navigate(BuildContext context, String route, String activeRoute) {
  if (route == activeRoute) return;
  const primaryRoutes = <String>{
    '/home',
    '/modules',
    '/search',
    '/notifications',
    '/profile',
  };
  if (primaryRoutes.contains(route)) {
    Navigator.pushNamedAndRemoveUntil(context, route, (Route<dynamic> _) => false);
    return;
  }
  Navigator.pushNamed(context, route);
}
