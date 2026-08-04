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
  static const double expandedSidebarWidth = 288;
  static const double compactSidebarWidth = 84;

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
        final width = constraints.maxWidth;
        if (width >= desktopBreakpoint) {
          return _DesktopShell(
            width: width,
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
        if (width >= tabletBreakpoint) {
          return _TabletShell(
            width: width,
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
        return _MobileShell(
          title: title,
          body: body,
          actions: actions,
          floatingActionButton: floatingActionButton,
          activeRoute: activeRoute,
          activeModuleId: activeModuleId,
          activeEntityCollection: activeEntityCollection,
          showContextSwitcher: showContextSwitcher,
        );
      },
    );
  }
}

class _DesktopShell extends StatelessWidget {
  final double width;
  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final String activeRoute;
  final String? activeModuleId;
  final String? activeEntityCollection;
  final bool showContextSwitcher;

  const _DesktopShell({
    required this.width,
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
    return ListenableBuilder(
      listenable: NavigationPreferences.instance,
      builder: (BuildContext context, Widget? child) {
        final expanded = NavigationPreferences.instance.desktopExpandedFor(
          width,
        );
        final sidebarWidth = expanded
            ? SaasScaffold.expandedSidebarWidth
            : SaasScaffold.compactSidebarWidth;

        return Scaffold(
          floatingActionButton: floatingActionButton,
          body: SafeArea(
            child: Row(
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: sidebarWidth,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: MainDrawer(
                    embedded: true,
                    compact: !expanded,
                    activeRoute: activeRoute,
                    activeModuleId: activeModuleId,
                    activeEntityCollection: activeEntityCollection,
                    onToggleCompact: () =>
                        NavigationPreferences.instance.toggleDesktop(width),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      _TopBar(
                        title: title,
                        actions: actions,
                        showContextSwitcher: showContextSwitcher,
                      ),
                      const Divider(height: 1),
                      Expanded(child: body),
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

class _TabletShell extends StatefulWidget {
  final double width;
  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final String activeRoute;
  final String? activeModuleId;
  final String? activeEntityCollection;
  final bool showContextSwitcher;

  const _TabletShell({
    required this.width,
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
  State<_TabletShell> createState() => _TabletShellState();
}

class _TabletShellState extends State<_TabletShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final extendedRail = widget.width >= 900;
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width: MediaQuery.sizeOf(context).width * 0.88,
        child: MainDrawer(
          activeRoute: widget.activeRoute,
          activeModuleId: widget.activeModuleId,
          activeEntityCollection: widget.activeEntityCollection,
        ),
      ),
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: _appBarActions(context, widget.actions),
      ),
      floatingActionButton: widget.floatingActionButton,
      body: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            NavigationRail(
              extended: extendedRail,
              minExtendedWidth: 188,
              selectedIndex: _selectedIndex(widget.activeRoute),
              labelType: extendedRail
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.selected,
              leading: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: IconButton.filledTonal(
                  tooltip: 'All modules',
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  icon: const Icon(Icons.grid_view_rounded),
                ),
              ),
              destinations: _railDestinations,
              onDestinationSelected: (int index) {
                _navigate(context, _tabletRoutes[index], widget.activeRoute);
              },
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: <Widget>[
                  if (widget.showContextSwitcher) const _ContextStrip(),
                  Expanded(child: widget.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileShell extends StatefulWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final String activeRoute;
  final String? activeModuleId;
  final String? activeEntityCollection;
  final bool showContextSwitcher;

  const _MobileShell({
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
  State<_MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<_MobileShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final state = SessionState.instance;
    final canPop = Navigator.canPop(context);
    final hasPageAction = widget.actions.isNotEmpty;
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width: MediaQuery.sizeOf(context).width * 0.88,
        child: MainDrawer(
          activeRoute: widget.activeRoute,
          activeModuleId: widget.activeModuleId,
          activeEntityCollection: widget.activeEntityCollection,
        ),
      ),
      appBar: AppBar(
        leadingWidth: 62,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          child: IconButton.filledTonal(
            tooltip: canPop ? 'Back' : 'Open modules',
            onPressed: canPop
                ? () => Navigator.pop(context)
                : () => _scaffoldKey.currentState?.openDrawer(),
            icon: Icon(canPop ? Icons.arrow_back_rounded : Icons.menu_rounded),
          ),
        ),
        titleSpacing: 10,
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          ...widget.actions.take(1),
          if (!hasPageAction)
            IconButton(
              tooltip: 'Search',
              onPressed: () =>
                  _navigate(context, '/search', widget.activeRoute),
              icon: const Icon(Icons.search_rounded, size: 23),
            ),
          if (!hasPageAction &&
              state.hasPermission(AppPermission.notificationsView) &&
              widget.activeRoute != '/notifications')
            IconButton(
              tooltip: 'Notifications',
              onPressed: () =>
                  _navigate(context, '/notifications', widget.activeRoute),
              icon: const Icon(Icons.notifications_none_rounded, size: 23),
            ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            if (widget.showContextSwitcher) const _ContextStrip(),
            Expanded(child: widget.body),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.navigation.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 68,
            selectedIndex: _mobileSelectedIndex(widget.activeRoute),
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search_rounded),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_none_rounded),
                selectedIcon: Icon(Icons.notifications_rounded),
                label: 'Alerts',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Modules',
              ),
            ],
            onDestinationSelected: (int index) {
              if (index == 3) {
                _scaffoldKey.currentState?.openDrawer();
                return;
              }
              _navigate(context, _mobileRoutes[index], widget.activeRoute);
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final bool showContextSwitcher;

  const _TopBar({
    required this.title,
    required this.actions,
    required this.showContextSwitcher,
  });

  @override
  Widget build(BuildContext context) {
    final state = SessionState.instance;
    return SizedBox(
      height: 70,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final compact = constraints.maxWidth < 820;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
            child: Row(
              children: <Widget>[
                if (Navigator.canPop(context)) ...<Widget>[
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 18 : 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (showContextSwitcher)
                  SchoolContextSwitcher(compact: compact),
                if (showContextSwitcher && !compact) const SizedBox(width: 8),
                const TenantSwitcher(compact: true),
                IconButton(
                  tooltip: 'Global search',
                  onPressed: () => Navigator.pushNamed(context, '/search'),
                  icon: const Icon(Icons.search_rounded),
                ),
                if (state.hasPermission(AppPermission.notificationsView))
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () =>
                        Navigator.pushNamed(context, '/notifications'),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                if (!compact)
                  IconButton(
                    tooltip: 'Toggle theme',
                    onPressed: SessionState.instance.toggleTheme,
                    icon: Icon(
                      Theme.of(context).brightness == Brightness.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                  ),
                ...actions.take(compact ? 1 : actions.length),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ContextStrip extends StatelessWidget {
  const _ContextStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.page,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
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
    );
  }
}

List<Widget> _appBarActions(BuildContext context, List<Widget> actions) {
  final state = SessionState.instance;
  return <Widget>[
    ...actions.take(2),
    IconButton(
      tooltip: 'Search',
      onPressed: () => Navigator.pushNamed(context, '/search'),
      icon: const Icon(Icons.search_rounded),
    ),
    if (state.hasPermission(AppPermission.notificationsView))
      IconButton(
        tooltip: 'Notifications',
        onPressed: () => Navigator.pushNamed(context, '/notifications'),
        icon: const Icon(Icons.notifications_none_rounded),
      ),
  ];
}

const List<NavigationRailDestination> _railDestinations =
    <NavigationRailDestination>[
  NavigationRailDestination(
    icon: Icon(Icons.dashboard_outlined),
    selectedIcon: Icon(Icons.dashboard_rounded),
    label: Text('Dashboard'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.search_outlined),
    selectedIcon: Icon(Icons.search_rounded),
    label: Text('Search'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.notifications_none_rounded),
    selectedIcon: Icon(Icons.notifications_rounded),
    label: Text('Alerts'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.settings_outlined),
    selectedIcon: Icon(Icons.settings_rounded),
    label: Text('Settings'),
  ),
];

const List<String> _tabletRoutes = <String>[
  '/home',
  '/search',
  '/notifications',
  '/settings',
];

const List<String> _mobileRoutes = <String>[
  '/home',
  '/search',
  '/notifications',
];

int _selectedIndex(String activeRoute) {
  switch (activeRoute) {
    case '/search':
      return 1;
    case '/notifications':
      return 2;
    case '/settings':
      return 3;
    default:
      return 0;
  }
}

int _mobileSelectedIndex(String activeRoute) {
  switch (activeRoute) {
    case '/search':
      return 1;
    case '/notifications':
      return 2;
    case '/home':
      return 0;
    default:
      return 3;
  }
}

void _navigate(BuildContext context, String route, String activeRoute) {
  if (route == activeRoute) return;
  if (route == '/home') {
    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      (Route<dynamic> _) => false,
    );
    return;
  }
  Navigator.pushNamed(context, route);
}
