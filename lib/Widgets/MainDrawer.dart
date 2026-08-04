import 'package:flutter/material.dart';

import '../core/erp/erp_access_policy.dart';
import '../core/erp/erp_catalog.dart';
import '../core/erp/erp_entity.dart';
import '../core/erp/erp_module.dart';
import '../core/erp/tenant_erp_service.dart';
import '../services/Auth_services.dart';
import '../services/models/app_permission.dart';
import '../services/models/tenant.dart';
import '../services/plan_entitlement_service.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';
import 'TenantSwitcher.dart';

class MainDrawer extends StatefulWidget {
  final bool embedded;
  final bool compact;
  final String activeRoute;
  final String? activeModuleId;
  final String? activeEntityCollection;
  final VoidCallback? onToggleCompact;

  const MainDrawer({
    super.key,
    this.embedded = false,
    this.compact = false,
    this.activeRoute = '',
    this.activeModuleId,
    this.activeEntityCollection,
    this.onToggleCompact,
  });

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  final ScrollController _scrollController = ScrollController();
  String _query = '';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionState.instance,
      builder: (BuildContext context, Widget? child) {
        final state = SessionState.instance;
        final user = state.user;
        final tenant = state.tenant;
        final entitlement = PlanEntitlementService(tenant: tenant);

        final allModules = ErpCatalog.modules
            .where(
              (ErpModule module) => ErpAccessPolicy.canViewModule(
                module,
                user,
                state.hasPermission,
              ),
            )
            .where((ErpModule module) => entitlement.canAccessModule(module.id))
            .toList(growable: false);

        final modules = _query.isEmpty
            ? allModules
            : allModules.where((ErpModule module) {
                final moduleMatch = '${module.title} ${module.description}'
                    .toLowerCase()
                    .contains(_query);
                final entityMatch = module.entities.any(
                  (ErpEntity entity) => '${entity.title} ${entity.description}'
                      .toLowerCase()
                      .contains(_query),
                );
                return moduleMatch || entityMatch;
              }).toList(growable: false);

        if (widget.compact) {
          return _buildCompact(context, state, tenant, modules);
        }
        return _buildExpanded(
            context, state, tenant, modules, allModules.length);
      },
    );
  }

  Widget _buildExpanded(
    BuildContext context,
    SessionState state,
    Tenant? tenant,
    List<ErpModule> modules,
    int totalModuleCount,
  ) {
    return Column(
      children: <Widget>[
        _DrawerHeader(
          tenant: tenant,
          compact: false,
          onToggleCompact: widget.onToggleCompact,
          embedded: widget.embedded,
        ),
        if (totalModuleCount > 5)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              onChanged: (String value) {
                setState(() => _query = value.trim().toLowerCase());
              },
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Find a module...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
              ),
            ),
          ),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: ListView(
              controller: _scrollController,
              primary: false,
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 16),
              children: <Widget>[
                _tile(
                  context,
                  Icons.dashboard_outlined,
                  'Dashboard',
                  '/home',
                  replaceRoot: true,
                ),
                if (state.hasPermission(AppPermission.profileView))
                  _tile(
                    context,
                    Icons.person_outline_rounded,
                    'My Profile',
                    '/profile',
                  ),
                if (state.hasPermission(AppPermission.notificationsView))
                  _tile(
                    context,
                    Icons.notifications_none_rounded,
                    'Notifications',
                    '/notifications',
                  ),
                if (state.hasAnyPermission(const <String>[
                  AppPermission.saasAdminView,
                  AppPermission.subscriptionManage,
                  AppPermission.tenantManage,
                ])) ...<Widget>[
                  _tile(
                    context,
                    Icons.grid_view_rounded,
                    'SaaS Control Center',
                    '/saas',
                  ),
                  _tile(
                    context,
                    Icons.rocket_launch_outlined,
                    'School Onboarding',
                    '/onboarding',
                  ),
                ],
                if (_canViewApprovals(state))
                  _tile(
                    context,
                    Icons.approval_outlined,
                    'Approval Inbox',
                    '/approvals',
                  ),
                if (modules.isNotEmpty) ...<Widget>[
                  const Divider(height: 22),
                  _section('School ERP'),
                  ...modules.map(
                    (ErpModule module) => _moduleMenu(
                      context,
                      module,
                      _visibleEntities(module, state),
                    ),
                  ),
                ] else if (_query.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: <Widget>[
                        Icon(Icons.search_off_rounded, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'No matching modules',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 22),
                _section('Workspace'),
                if (state.hasPermission(AppPermission.settingsView))
                  _tile(
                    context,
                    Icons.settings_outlined,
                    'Settings',
                    '/settings',
                  ),
                if (state.hasPermission(AppPermission.usersManage))
                  _tile(
                    context,
                    Icons.manage_accounts_outlined,
                    'School Accounts',
                    '/accounts',
                  ),
                _actionTile(
                  context,
                  Icons.logout_rounded,
                  'Logout',
                  () => _logout(context),
                  color: AppColors.danger,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompact(
    BuildContext context,
    SessionState state,
    Tenant? tenant,
    List<ErpModule> modules,
  ) {
    return Column(
      children: <Widget>[
        _DrawerHeader(
          tenant: tenant,
          compact: true,
          onToggleCompact: widget.onToggleCompact,
          embedded: widget.embedded,
        ),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: ListView(
              controller: _scrollController,
              primary: false,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              children: <Widget>[
                _compactRouteButton(
                  context,
                  icon: Icons.dashboard_outlined,
                  tooltip: 'Dashboard',
                  route: '/home',
                  replaceRoot: true,
                ),
                if (state.hasPermission(AppPermission.profileView))
                  _compactRouteButton(
                    context,
                    icon: Icons.person_outline_rounded,
                    tooltip: 'My Profile',
                    route: '/profile',
                  ),
                if (state.hasPermission(AppPermission.notificationsView))
                  _compactRouteButton(
                    context,
                    icon: Icons.notifications_none_rounded,
                    tooltip: 'Notifications',
                    route: '/notifications',
                  ),
                if (state.hasAnyPermission(const <String>[
                  AppPermission.saasAdminView,
                  AppPermission.subscriptionManage,
                  AppPermission.tenantManage,
                ]))
                  _compactRouteButton(
                    context,
                    icon: Icons.grid_view_rounded,
                    tooltip: 'SaaS Control Center',
                    route: '/saas',
                  ),
                if (_canViewApprovals(state))
                  _compactRouteButton(
                    context,
                    icon: Icons.approval_outlined,
                    tooltip: 'Approval Inbox',
                    route: '/approvals',
                  ),
                const Divider(height: 20),
                ...modules.map(
                  (ErpModule module) => _compactModuleButton(
                    context,
                    module,
                    _visibleEntities(module, state),
                  ),
                ),
                const Divider(height: 20),
                if (state.hasPermission(AppPermission.settingsView))
                  _compactRouteButton(
                    context,
                    icon: Icons.settings_outlined,
                    tooltip: 'Settings',
                    route: '/settings',
                  ),
                if (state.hasPermission(AppPermission.usersManage))
                  _compactRouteButton(
                    context,
                    icon: Icons.manage_accounts_outlined,
                    tooltip: 'School Accounts',
                    route: '/accounts',
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: IconButton(
                    tooltip: 'Logout',
                    onPressed: () => _logout(context),
                    color: AppColors.danger,
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<ErpEntity> _visibleEntities(ErpModule module, SessionState state) {
    return module.entities
        .where(
          (ErpEntity entity) => ErpAccessPolicy.canViewEntity(
            entity,
            state.user,
            state.hasPermission,
          ),
        )
        .toList(growable: false);
  }

  bool _canViewApprovals(SessionState state) {
    return state.hasAnyPermission(const <String>[
      AppPermission.saasAdminManage,
      AppPermission.accountingManage,
      AppPermission.feesManage,
      AppPermission.payrollManage,
      AppPermission.examsManage,
      AppPermission.studentsManage,
      AppPermission.leaveManage,
    ]);
  }

  Widget _moduleMenu(
    BuildContext context,
    ErpModule module,
    List<ErpEntity> entities,
  ) {
    final moduleActive = widget.activeModuleId == module.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: moduleActive
            ? module.color.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.08,
              )
            : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        key: PageStorageKey<String>('drawer-${module.id}'),
        initiallyExpanded: moduleActive,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
        leading: Icon(module.icon, color: module.color, size: 22),
        title: Text(
          module.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        children: <Widget>[
          _subTile(
            context,
            icon: Icons.dashboard_customize_outlined,
            label: 'Module Overview',
            selected: moduleActive && widget.activeRoute == '/erp-module',
            color: module.color,
            onTap: () => _named(
              context,
              '/erp-module',
              arguments: module,
            ),
          ),
          ...entities.map(
            (ErpEntity entity) => _subTile(
              context,
              icon: entity.icon,
              label: entity.title,
              selected: widget.activeEntityCollection == entity.collection,
              color: entity.color,
              onTap: () => _named(
                context,
                '/erp-entity',
                arguments: entity,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactModuleButton(
    BuildContext context,
    ErpModule module,
    List<ErpEntity> entities,
  ) {
    final selected = widget.activeModuleId == module.id;
    final background = selected
        ? module.color.withOpacity(
            Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.12,
          )
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: PopupMenuButton<_CompactTarget>(
        tooltip: module.title,
        position: PopupMenuPosition.under,
        onSelected: (_CompactTarget target) {
          _named(context, target.route, arguments: target.arguments);
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<_CompactTarget>>[
          PopupMenuItem<_CompactTarget>(
            value: _CompactTarget('/erp-module', module),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(module.icon, color: module.color),
              title: Text(
                module.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Module overview'),
            ),
          ),
          if (entities.isNotEmpty) const PopupMenuDivider(),
          ...entities.map(
            (ErpEntity entity) => PopupMenuItem<_CompactTarget>(
              value: _CompactTarget('/erp-entity', entity),
              child: Row(
                children: <Widget>[
                  Icon(entity.icon, color: entity.color, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entity.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        child: Tooltip(
          message: module.title,
          child: Ink(
            height: 48,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(module.icon, color: module.color, size: 23),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    String route, {
    bool replaceRoot = false,
  }) {
    final selected = widget.activeRoute == route;
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: ListTile(
        selected: selected,
        selectedTileColor: primary.withOpacity(
          Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.09,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: selected ? primary : null),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
        trailing: selected
            ? Icon(Icons.circle, size: 7, color: primary)
            : const Icon(Icons.chevron_right_rounded, size: 18),
        onTap: () => _named(context, route, replaceRoot: replaceRoot),
      ),
    );
  }

  Widget _actionTile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _subTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      selected: selected,
      selectedTileColor: color.withOpacity(
        Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.09,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(icon, color: color, size: 19),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded, color: color, size: 17)
          : const Icon(Icons.chevron_right_rounded, size: 16),
      onTap: onTap,
    );
  }

  Widget _compactRouteButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required String route,
    bool replaceRoot = false,
  }) {
    final selected = widget.activeRoute == route;
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: selected
              ? primary.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.12,
                )
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _named(context, route, replaceRoot: replaceRoot),
            child: SizedBox(
              height: 48,
              child: Icon(icon, color: selected ? primary : null),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 5),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  void _named(
    BuildContext context,
    String route, {
    bool replaceRoot = false,
    Object? arguments,
  }) {
    final navigator = Navigator.of(context);
    if (!widget.embedded) navigator.pop();

    if (arguments == null && widget.activeRoute == route) return;

    if (replaceRoot) {
      navigator.pushNamedAndRemoveUntil(
        route,
        (Route<dynamic> _) => false,
        arguments: arguments,
      );
      return;
    }
    navigator.pushNamed(route, arguments: arguments);
  }

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    if (!widget.embedded) navigator.pop();
    await AuthService().signOut();
    SessionState.instance.clear();
    if (!context.mounted) return;
    navigator.pushNamedAndRemoveUntil(
      '/login',
      (Route<dynamic> route) => false,
    );
  }
}

class _CompactTarget {
  final String route;
  final Object arguments;

  const _CompactTarget(this.route, this.arguments);
}

class _DrawerHeader extends StatelessWidget {
  final Tenant? tenant;
  final bool compact;
  final VoidCallback? onToggleCompact;
  final bool embedded;

  const _DrawerHeader({
    required this.tenant,
    required this.compact,
    required this.onToggleCompact,
    required this.embedded,
  });

  @override
  Widget build(BuildContext context) {
    final state = SessionState.instance;
    final user = state.user;
    final scheme = Theme.of(context).colorScheme;

    if (compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        color: scheme.primaryContainer,
        child: Column(
          children: <Widget>[
            _TenantLogo(tenant: tenant, compact: true),
            const SizedBox(height: 10),
            IconButton(
              tooltip: 'Expand navigation',
              onPressed: onToggleCompact,
              color: scheme.onPrimaryContainer,
              icon: const Icon(Icons.keyboard_double_arrow_right_rounded),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        embedded ? 16 : MediaQuery.paddingOf(context).top + 16,
        12,
        16,
      ),
      color: scheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _TenantLogo(tenant: tenant),
              const Spacer(),
              if (TenantErpService().isDemoMode)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.surface.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'DEMO',
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (onToggleCompact != null)
                IconButton(
                  tooltip: 'Collapse navigation',
                  onPressed: onToggleCompact,
                  color: scheme.onPrimaryContainer,
                  icon: const Icon(Icons.keyboard_double_arrow_left_rounded),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tenant?.name ?? 'SEEF',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            user?.displayName?.trim().isNotEmpty == true
                ? user!.displayName!.trim()
                : 'User',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            user?.roleLabel ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onPrimaryContainer.withOpacity(0.72),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              _HeaderPill(label: tenant?.subscription.planLabel ?? 'No plan'),
              const SizedBox(width: 6),
              _HeaderPill(
                label: tenant?.subscription.isUsable == true
                    ? 'ACTIVE'
                    : 'ACTION REQUIRED',
              ),
            ],
          ),
          if (state.canSwitchTenant) ...<Widget>[
            const SizedBox(height: 12),
            const TenantSwitcher(),
          ],
        ],
      ),
    );
  }
}

class _TenantLogo extends StatelessWidget {
  final Tenant? tenant;
  final bool compact;

  const _TenantLogo({required this.tenant, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.0 : 54.0;
    final url = tenant?.logoUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        child: Container(
          width: size,
          height: size,
          color: Colors.white,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.school_outlined,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.white24,
      child: Icon(
        Icons.school_outlined,
        color: Colors.white,
        size: compact ? 23 : 29,
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final String label;

  const _HeaderPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.surface.withOpacity(0.62),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.outlineVariant.withOpacity(0.55)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: scheme.onPrimaryContainer,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
