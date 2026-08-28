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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.18)
                : const Color(0xFF101B40).withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
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
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
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
                    suffixIcon: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
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
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        initials.isEmpty ? 'U' : initials,
                        style: TextStyle(
                          color: scheme.onPrimaryContainer,
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
                              style: TextStyle(fontSize: 10.2, color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 17, color: scheme.onSurfaceVariant),
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
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? scheme.primaryContainer : scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: onPressed,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Icon(
              icon,
              size: 20,
              color: onPressed == null
                  ? Theme.of(context).disabledColor
                  : active
                      ? scheme.primary
                      : scheme.onSurface,
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
    final scheme = Theme.of(context).colorScheme;
    final displayName = state.user?.displayName?.trim();
    final name = displayName?.isNotEmpty == true ? displayName! : 'User';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .take(2)
        .map((String part) => part[0].toUpperCase())
        .join();
    final showSearch = !widget.tablet && widget.activeRoute != '/search';
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
        toolbarHeight: 66,
        backgroundColor: scheme.surface,
        leadingWidth: 58,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            tooltip: canPop ? 'Back' : 'Open menu',
            onPressed: canPop ? () => Navigator.pop(context) : _openDrawer,
            icon: Icon(
              canPop ? Icons.arrow_back_rounded : Icons.menu_rounded,
              size: 22,
            ),
          ),
        ),
        titleSpacing: 6,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.tablet
                  ? widget.title
                  : (state.tenant?.name ?? 'SEEF School'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(
              widget.tablet ? 'School management workspace' : widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          if (widget.actions.isNotEmpty)
            ...widget.actions.take(1),
          IconButton(
            tooltip: 'Switch theme',
            onPressed: state.toggleTheme,
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              size: 20,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: name,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _navigate(context, '/profile', widget.activeRoute),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  child: Text(
                    initials.isEmpty ? 'U' : initials,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: showSearch
            ? PreferredSize(
                preferredSize: const Size.fromHeight(68),
                child: _MobileDiscoveryBar(
                  onSearch: () => _navigate(context, '/search', widget.activeRoute),
                ),
              )
            : null,
      ),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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

class _MobileDiscoveryBar extends StatelessWidget {
  final VoidCallback onSearch;

  const _MobileDiscoveryBar({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
        child: SearchBar(
          onTap: onSearch,
          hintText: 'Search your school',
          leading: const Icon(Icons.search_rounded, size: 22),
          trailing: <Widget>[
            IconButton(
              tooltip: 'Search filters',
              onPressed: onSearch,
              icon: const Icon(Icons.tune_rounded, size: 20),
            ),
          ],
          elevation: const WidgetStatePropertyAll<double>(0),
          backgroundColor: WidgetStatePropertyAll<Color>(
            scheme.surfaceContainerHighest,
          ),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: scheme.outlineVariant),
          ),
          constraints: const BoxConstraints(minHeight: 52, maxHeight: 52),
          padding: const WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: 16),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle>(
            TextStyle(color: scheme.onSurface, fontSize: 14),
          ),
          hintStyle: WidgetStatePropertyAll<TextStyle>(
            TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
          ),
        ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const items = <_BottomItem>[
      _BottomItem(Icons.home_outlined, Icons.home_rounded, 'Home', '/home'),
      _BottomItem(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Modules', '/modules'),
      _BottomItem(Icons.search_rounded, Icons.search_rounded, 'Search', '/search'),
      _BottomItem(Icons.notifications_none_rounded, Icons.notifications_rounded, 'Alerts', '/notifications'),
      _BottomItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile', '/profile'),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.26)
                : const Color(0xFF101B40).withOpacity(0.075),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: selected,
        height: 70,
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        onDestinationSelected: (int index) {
          final item = items[index];
          if (item.route == '/modules' && activeRoute == '/modules') {
            onOpenMenu();
            return;
          }
          _navigate(context, item.route, activeRoute);
        },
        destinations: items
            .map(
              (_BottomItem item) => NavigationDestination(
                icon: Icon(item.icon, size: 21),
                selectedIcon: Icon(item.selectedIcon, size: 21),
                label: item.label,
              ),
            )
            .toList(growable: false),
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
    Navigator.pushReplacementNamed(context, route);
    return;
  }
  Navigator.pushNamed(context, route);
}
