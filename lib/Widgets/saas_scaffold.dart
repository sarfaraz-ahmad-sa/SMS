import 'package:flutter/material.dart';

import '../services/models/app_permission.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';
import 'MainDrawer.dart';
import 'TenantSwitcher.dart';
import 'school_context_switcher.dart';

class SaasScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final String activeRoute;
  final bool showContextSwitcher;

  const SaasScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const <Widget>[],
    this.floatingActionButton,
    this.activeRoute = '',
    this.showContextSwitcher = true,
  });

  @override
  State<SaasScaffold> createState() => _SaasScaffoldState();
}

class _SaasScaffoldState extends State<SaasScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth >= 1120) return _desktop(context);
        if (constraints.maxWidth >= 720) return _tablet(context);
        return _mobile(context);
      },
    );
  }

  Widget _desktop(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.floatingActionButton,
      body: Row(
        children: <Widget>[
          SizedBox(
  width: 292,
  child: Material(
    color: Theme.of(context).colorScheme.surface,
    child: MainDrawer(embedded: true),
  ),
),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: <Widget>[
                _TopBar(
                  title: widget.title,
                  actions: widget.actions,
                  showContextSwitcher: widget.showContextSwitcher,
                ),
                const Divider(height: 1),
                Expanded(child: widget.body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tablet(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const Drawer(child: MainDrawer()),
      appBar: AppBar(
        title: Text(widget.title),
        actions: _compactActions(context),
      ),
      floatingActionButton: widget.floatingActionButton,
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: _selectedIndex,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: IconButton(
                tooltip: 'All modules',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: Text('Home'),
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
            ],
            onDestinationSelected: _onDestinationSelected,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: widget.body),
        ],
      ),
    );
  }

  Widget _mobile(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const Drawer(child: MainDrawer()),
      appBar: AppBar(
        title: Text(widget.title),
        actions: _compactActions(context),
      ),
      floatingActionButton: widget.floatingActionButton,
      body: widget.body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
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
            icon: Icon(Icons.menu_rounded),
            label: 'More',
          ),
        ],
        onDestinationSelected: (int index) {
          if (index == 3) {
            _scaffoldKey.currentState?.openDrawer();
            return;
          }
          _onDestinationSelected(index);
        },
      ),
    );
  }

  List<Widget> _compactActions(BuildContext context) {
    final state = SessionState.instance;
    return <Widget>[
      if (widget.showContextSwitcher)
        const SchoolContextSwitcher(compact: true),
      const TenantSwitcher(compact: true),
      ...widget.actions,
      if (state.hasPermission(AppPermission.notificationsView) &&
          widget.activeRoute != '/notifications')
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => _navigate('/notifications'),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
    ];
  }

  int get _selectedIndex {
    switch (widget.activeRoute) {
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

  void _onDestinationSelected(int index) {
    const routes = <String>['/home', '/search', '/notifications', '/settings'];
    _navigate(routes[index]);
  }

  void _navigate(String route) {
    if (widget.activeRoute == route) return;
    if (route == '/home') {
      Navigator.pushNamedAndRemoveUntil(context, route, (Route<dynamic> _) => false);
      return;
    }
    Navigator.pushNamed(context, route);
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
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (showContextSwitcher) const SchoolContextSwitcher(),
            if (showContextSwitcher) const SizedBox(width: 8),
            const TenantSwitcher(compact: true),
            IconButton(
              tooltip: 'Global search',
              onPressed: () => Navigator.pushNamed(context, '/search'),
              icon: const Icon(Icons.search_rounded),
            ),
            if (state.hasPermission(AppPermission.notificationsView))
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            IconButton(
              tooltip: 'Toggle theme',
              onPressed: SessionState.instance.toggleTheme,
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}
