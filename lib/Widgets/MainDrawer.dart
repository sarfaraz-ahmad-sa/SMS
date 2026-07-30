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

class MainDrawer extends StatelessWidget {
  final bool embedded;

  const MainDrawer({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionState.instance,
      builder: (BuildContext context, Widget? child) {
        final state = SessionState.instance;
        final user = state.user;
        final tenant = state.tenant;
        final entitlement = PlanEntitlementService(tenant: tenant);

        final modules = ErpCatalog.modules
            .where(
              (ErpModule module) => ErpAccessPolicy.canViewModule(
                module,
                user,
                state.hasPermission,
              ),
            )
            .where((ErpModule module) => entitlement.canAccessModule(module.id))
            .toList(growable: false);

        return Column(
          children: <Widget>[
            _DrawerHeader(tenant: tenant),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: <Widget>[
                  _tile(
                    context,
                    Icons.dashboard_outlined,
                    'Dashboard',
                    () => _named(context, '/home', replaceRoot: true),
                  ),
                  if (state.hasPermission(AppPermission.profileView))
                    _tile(
                      context,
                      Icons.person_outline,
                      'My Profile',
                      () => _named(context, '/profile'),
                    ),
                  if (state.hasPermission(AppPermission.notificationsView))
                    _tile(
                      context,
                      Icons.notifications_none_rounded,
                      'Notifications',
                      () => _named(context, '/notifications'),
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
                      () => _named(context, '/saas'),
                    ),
                    _tile(
                      context,
                      Icons.rocket_launch_outlined,
                      'School Onboarding',
                      () => _named(context, '/onboarding'),
                    ),
                  ],
                  if (state.hasAnyPermission(const <String>[
                    AppPermission.saasAdminManage,
                    AppPermission.accountingManage,
                    AppPermission.feesManage,
                    AppPermission.payrollManage,
                    AppPermission.examsManage,
                    AppPermission.studentsManage,
                    AppPermission.leaveManage,
                  ]))
                    _tile(
                      context,
                      Icons.approval_outlined,
                      'Approval Inbox',
                      () => _named(context, '/approvals'),
                    ),
                  if (modules.isNotEmpty) ...<Widget>[
                    const Divider(),
                    _section('School ERP'),
                    ...modules.map(
                      (ErpModule module) => _moduleMenu(
                        context,
                        module,
                        module.entities
                            .where(
                              (ErpEntity entity) => ErpAccessPolicy.canViewEntity(
                                entity,
                                user,
                                state.hasPermission,
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ],
                  const Divider(),
                  _section('Workspace'),
                  if (state.hasPermission(AppPermission.settingsView))
                    _tile(
                      context,
                      Icons.settings_outlined,
                      'Settings',
                      () => _named(context, '/settings'),
                    ),
                  if (state.hasPermission(AppPermission.usersManage))
                    _tile(
                      context,
                      Icons.manage_accounts_outlined,
                      'School Accounts',
                      () => _named(context, '/accounts'),
                    ),
                  _tile(
                    context,
                    Icons.logout,
                    'Logout',
                    () => _logout(context),
                    color: AppColors.danger,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _moduleMenu(
    BuildContext context,
    ErpModule module,
    List<ErpEntity> entities,
  ) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.only(left: 10, bottom: 4),
      leading: Icon(module.icon, color: module.color),
      title: Text(
        module.title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      children: <Widget>[
        ListTile(
          dense: true,
          leading: Icon(
            Icons.dashboard_customize_outlined,
            color: module.color,
            size: 20,
          ),
          title: const Text('Module Overview'),
          onTap: () => _named(
            context,
            '/erp-module',
            arguments: module,
          ),
        ),
        ...entities.map(
          (ErpEntity entity) => ListTile(
            dense: true,
            leading: Icon(entity.icon, color: entity.color, size: 19),
            title: Text(entity.title),
            trailing: const Icon(Icons.chevron_right, size: 17),
            onTap: () => _named(
              context,
              '/erp-entity',
              arguments: entity,
            ),
          ),
        ),
      ],
    );
  }

  Widget _section(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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

  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  void _named(
    BuildContext context,
    String route, {
    bool replaceRoot = false,
    Object? arguments,
  }) {
    final navigator = Navigator.of(context);
    if (!embedded) navigator.pop();
    if (replaceRoot) {
      navigator.pushNamedAndRemoveUntil(
        route,
        (Route<dynamic> _) => false,
        arguments: arguments,
      );
    } else {
      navigator.pushNamed(route, arguments: arguments);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    if (!embedded) navigator.pop();
    await AuthService().signOut();
    SessionState.instance.clear();
    if (!context.mounted) return;
    navigator.pushNamedAndRemoveUntil(
      '/login',
      (Route<dynamic> route) => false,
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final Tenant? tenant;

  const _DrawerHeader({required this.tenant});

  @override
  Widget build(BuildContext context) {
    final state = SessionState.instance;
    final user = state.user;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, embeddedTopPadding(context), 18, 18),
      decoration: BoxDecoration(
        gradient: AppColors.tenantGradient(tenant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _TenantLogo(tenant: tenant),
              const Spacer(),
              if (TenantErpService().isDemoMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'DEMO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tenant?.name ?? 'CARTZ Link School ERP',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
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
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            user?.roleLabel ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
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

  double embeddedTopPadding(BuildContext context) {
    return MediaQuery.paddingOf(context).top + 18;
  }
}

class _TenantLogo extends StatelessWidget {
  final Tenant? tenant;

  const _TenantLogo({required this.tenant});

  @override
  Widget build(BuildContext context) {
    final url = tenant?.logoUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 54,
          height: 54,
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
    return const CircleAvatar(
      radius: 27,
      backgroundColor: Colors.white24,
      child: Icon(Icons.school_outlined, color: Colors.white, size: 29),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final String label;

  const _HeaderPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
