import 'dart:async';

import 'package:flutter/material.dart';

import '../core/erp/erp_access_policy.dart';
import '../core/erp/erp_catalog.dart';
import '../core/erp/erp_entity.dart';
import '../core/erp/erp_module.dart';
import '../core/erp/tenant_erp_service.dart';
import '../services/Auth_services.dart';
import '../services/models/app_permission.dart';
import '../services/plan_entitlement_service.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';

class MainDrawer extends StatefulWidget {
  final bool embedded;
  final bool compact;
  final String activeRoute;
  final String? activeModuleId;
  final String? activeEntityCollection;
  final VoidCallback? onToggleCompact;
  final VoidCallback? onClose;

  const MainDrawer({
    super.key,
    this.embedded = false,
    this.compact = false,
    this.activeRoute = '',
    this.activeModuleId,
    this.activeEntityCollection,
    this.onToggleCompact,
    this.onClose,
  });

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  final ScrollController _controller = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _query = '';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _queueSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      final next = value.trim().toLowerCase();
      if (next == _query) return;
      setState(() => _query = next);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionState.instance,
      builder: (BuildContext context, Widget? child) {
        final state = SessionState.instance;
        final entitlement = PlanEntitlementService(tenant: state.tenant);
        final modules = ErpCatalog.modules
            .where((ErpModule module) => entitlement.canAccessModule(module.id))
            .where(
              (ErpModule module) => ErpAccessPolicy.canViewModule(
                module,
                state.user,
                state.hasPermission,
              ),
            )
            .where((ErpModule module) {
              if (_query.isEmpty) return true;
              final haystack = '${module.title} ${module.description}'.toLowerCase();
              return haystack.contains(_query) ||
                  module.entities.any(
                    (ErpEntity entity) =>
                        '${entity.title} ${entity.description}'.toLowerCase().contains(_query),
                  );
            })
            .toList(growable: false);

        return ColoredBox(
          color: AppColors.navigation,
          child: SafeArea(
            top: !widget.embedded,
            child: Column(
              children: <Widget>[
                _brandHeader(state),
                if (!widget.compact) _searchBox(),
                Expanded(
                  child: Scrollbar(
                    controller: _controller,
                    thumbVisibility: widget.embedded && !widget.compact,
                    child: ListView(
                      controller: _controller,
                      padding: EdgeInsets.fromLTRB(
                        widget.compact ? 9 : 12,
                        6,
                        widget.compact ? 9 : 12,
                        16,
                      ),
                      children: <Widget>[
                        _routeTile(Icons.dashboard_outlined, 'Dashboard', '/home', replaceRoot: true),
                        _routeTile(Icons.grid_view_rounded, 'All Modules', '/modules'),
                        if (state.hasPermission(AppPermission.profileView))
                          _routeTile(Icons.person_outline_rounded, 'My Profile', '/profile'),
                        if (state.hasPermission(AppPermission.notificationsView))
                          _routeTile(Icons.notifications_none_rounded, 'Notifications', '/notifications'),
                        if (!widget.compact) const _DrawerLabel('SCHOOL ERP'),
                        ...modules.map((ErpModule module) => _moduleTile(module, state)),
                        if (!widget.compact) const _DrawerLabel('WORKSPACE'),
                        if (_canViewApprovals(state))
                          _routeTile(Icons.task_alt_rounded, 'Approval Inbox', '/approvals'),
                        if (state.hasAnyPermission(const <String>[
                          AppPermission.saasAdminView,
                          AppPermission.subscriptionManage,
                          AppPermission.tenantManage,
                        ]))
                          _routeTile(Icons.admin_panel_settings_outlined, 'SaaS Control', '/saas'),
                        if (state.hasPermission(AppPermission.settingsView))
                          _routeTile(Icons.settings_outlined, 'Settings', '/settings'),
                        if (state.hasPermission(AppPermission.usersManage))
                          _routeTile(Icons.manage_accounts_outlined, 'School Accounts', '/accounts'),
                      ],
                    ),
                  ),
                ),
                _footer(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _brandHeader(SessionState state) {
    final tenant = state.tenant;

    if (widget.compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
        child: Column(
          children: <Widget>[
            _brandMark(),
            const SizedBox(height: 10),
            if (widget.onToggleCompact != null)
              _drawerControl(
                tooltip: 'Expand sidebar',
                icon: Icons.keyboard_double_arrow_right_rounded,
                onPressed: widget.onToggleCompact!,
              ),
            if (widget.onClose != null) ...<Widget>[
              const SizedBox(height: 5),
              _drawerControl(
                tooltip: 'Close sidebar',
                icon: Icons.close_rounded,
                onPressed: widget.onClose!,
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
      child: Row(
        children: <Widget>[
          _brandMark(),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'SEEF SCHOOL',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tenant?.name ?? 'School Management',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFCAD6E0), fontSize: 10.5),
                ),
              ],
            ),
          ),
          if (TenantErpService().isDemoMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                'DEMO',
                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
              ),
            ),
          if (widget.onToggleCompact != null) ...<Widget>[
            const SizedBox(width: 3),
            _drawerControl(
              tooltip: 'Mini sidebar',
              icon: Icons.keyboard_double_arrow_left_rounded,
              onPressed: widget.onToggleCompact!,
            ),
          ],
          if (widget.onClose != null) ...<Widget>[
            const SizedBox(width: 2),
            _drawerControl(
              tooltip: widget.embedded ? 'Close sidebar' : 'Close menu',
              icon: Icons.close_rounded,
              onPressed: widget.onClose!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _brandMark() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x16000000), blurRadius: 12, offset: Offset(0, 5)),
        ],
      ),
      child: const Icon(Icons.school_rounded, color: AppColors.navigation, size: 22),
    );
  }

  Widget _drawerControl({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onPressed,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, color: const Color(0xFFE7EEF4), size: 18),
          ),
        ),
      ),
    );
  }

  Widget _searchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 3, 12, 10),
      child: TextField(
        controller: _searchController,
        onChanged: _queueSearch,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Find a module...',
          hintStyle: const TextStyle(color: Color(0xFFB8C6D2), fontSize: 11.5),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFFB8C6D2)),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  onPressed: () {
                    _searchDebounce?.cancel();
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFD7E1E9)),
                ),
          fillColor: Colors.white.withOpacity(0.08),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.34)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        ),
      ),
    );
  }

  Widget _routeTile(IconData icon, String label, String route, {bool replaceRoot = false}) {
    final selected = widget.activeRoute == route;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Tooltip(
        message: widget.compact ? label : '',
        waitDuration: const Duration(milliseconds: 350),
        child: Material(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _navigate(route, replaceRoot: replaceRoot),
            child: SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: widget.compact ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: <Widget>[
                  if (!widget.compact) const SizedBox(width: 13),
                  Icon(
                    icon,
                    size: 19,
                    color: selected ? AppColors.navigation : const Color(0xFFD2DCE5),
                  ),
                  if (!widget.compact) ...<Widget>[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: selected ? AppColors.navigation : const Color(0xFFF2F6F9),
                          fontSize: 12.5,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (selected)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(right: 13),
                        decoration: const BoxDecoration(
                          color: AppColors.navigation,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _moduleTile(ErpModule module, SessionState state) {
    final entities = module.entities
        .where((ErpEntity entity) =>
            ErpAccessPolicy.canViewEntity(entity, state.user, state.hasPermission))
        .toList(growable: false);
    final selected = widget.activeModuleId == module.id;

    if (widget.compact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Tooltip(
          message: module.title,
          waitDuration: const Duration(milliseconds: 350),
          child: Material(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _navigate('/erp-module', arguments: module),
              child: SizedBox(
                height: 44,
                child: Icon(
                  module.icon,
                  size: 19,
                  color: selected ? AppColors.navigation : const Color(0xFFD2DCE5),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        expansionTileTheme: const ExpansionTileThemeData(
          iconColor: Colors.white,
          collapsedIconColor: Color(0xFFCFD9E2),
          textColor: Colors.white,
          collapsedTextColor: Colors.white,
          shape: Border(),
          collapsedShape: Border(),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.09) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ExpansionTile(
          key: PageStorageKey<String>('module-${module.id}'),
          initiallyExpanded: selected,
          tilePadding: const EdgeInsets.symmetric(horizontal: 13),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 8, 7),
          leading: Icon(module.icon, color: const Color(0xFFD2DCE5), size: 18),
          title: Text(
            module.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 12.2, fontWeight: FontWeight.w600),
          ),
          children: <Widget>[
            _subTile(
              icon: Icons.space_dashboard_outlined,
              label: 'Overview',
              selected: selected && widget.activeRoute == '/erp-module',
              onTap: () => _navigate('/erp-module', arguments: module),
            ),
            ...entities.map(
              (ErpEntity entity) => _subTile(
                icon: entity.icon,
                label: entity.title,
                selected: widget.activeEntityCollection == entity.collection,
                onTap: () => _navigate('/erp-entity', arguments: entity),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subTile({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 15, color: selected ? AppColors.navigation : const Color(0xFFBFCCD7)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.navigation : const Color(0xFFE3EAF0),
                    fontSize: 11.3,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(SessionState state) {
    final displayName = state.user?.displayName?.trim();
    final name = displayName?.isNotEmpty == true ? displayName! : 'School User';

    return Container(
      padding: EdgeInsets.fromLTRB(widget.compact ? 8 : 12, 11, widget.compact ? 8 : 10, 13),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.10))),
      ),
      child: widget.compact
          ? Column(
              children: <Widget>[
                Tooltip(
                  message: name,
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: Colors.white,
                    child: Text(
                      name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: AppColors.navigation, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                IconButton(
                  tooltip: 'Logout',
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFFFFC2C2), size: 19),
                ),
              ],
            )
          : Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.white,
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: AppColors.navigation, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        state.user?.roleLabel ?? 'School user',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFB8C6D2), fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Logout',
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFFFFC2C2), size: 19),
                ),
              ],
            ),
    );
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

  void _navigate(String route, {bool replaceRoot = false, Object? arguments}) {
    final navigator = Navigator.of(context);
    if (!widget.embedded) navigator.pop();
    if (arguments == null && widget.activeRoute == route) return;
    if (replaceRoot) {
      navigator.pushNamedAndRemoveUntil(route, (Route<dynamic> _) => false, arguments: arguments);
    } else {
      navigator.pushNamed(route, arguments: arguments);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    if (!widget.embedded) navigator.pop();
    await AuthService().signOut();
    SessionState.instance.clear();
    if (!context.mounted) return;
    navigator.pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }
}

class _DrawerLabel extends StatelessWidget {
  final String label;
  const _DrawerLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 7),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF9FB0BF),
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
