import 'package:flutter/material.dart';

import '../Screens/Enterprise/ErpEntityListScreen.dart';
import '../Screens/Enterprise/ErpModuleScreen.dart';
import '../Screens/LoginPage.dart';
import '../Screens/Notifications.dart';
import '../Screens/Profile.dart';
import '../Screens/Settings.dart';
import '../Screens/home.dart';
import '../core/erp/erp_access_policy.dart';
import '../core/erp/erp_catalog.dart';
import '../core/erp/erp_entity.dart';
import '../core/erp/erp_module.dart';
import '../core/erp/tenant_erp_service.dart';
import '../services/Auth_services.dart';
import '../services/models/app_permission.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';
import 'TenantSwitcher.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionState.instance,
      builder: (BuildContext context, Widget? child) {
        final state = SessionState.instance;
        final user = state.user;
        final tenant = state.tenant;

        final modules = ErpCatalog.modules
            .where(
              (ErpModule module) => ErpAccessPolicy.canViewModule(
                module,
                user,
                state.hasPermission,
              ),
            )
            .toList(growable: false);

        return Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const Spacer(),
                      if (TenantErpService().isDemoMode)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'DEMO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName?.trim().isNotEmpty == true
                        ? user!.displayName!.trim()
                        : 'User',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tenant?.name ?? 'SEEF SMS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.88),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.roleLabel ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 12,
                    ),
                  ),
                  if (state.canSwitchTenant) ...<Widget>[
                    const SizedBox(height: 12),
                    const TenantSwitcher(),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  _tile(
                    context,
                    Icons.dashboard_outlined,
                    'Dashboard',
                    () => _replace(context, const Home()),
                  ),
                  if (state.hasPermission(AppPermission.profileView))
                    _tile(
                      context,
                      Icons.person_outline,
                      'My Profile',
                      () => _go(context, const ProfileScreen()),
                    ),
                  if (state.hasPermission(AppPermission.notificationsView))
                    _tile(
                      context,
                      Icons.notifications_none_rounded,
                      'Notifications',
                      () => _go(context, const NotificationsScreen()),
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
                              (ErpEntity entity) =>
                                  ErpAccessPolicy.canViewEntity(
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
                  if (state.hasPermission(AppPermission.settingsView))
                    _tile(
                      context,
                      Icons.settings_outlined,
                      'Settings',
                      () => _go(context, const SettingsScreen()),
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
      childrenPadding: const EdgeInsets.only(left: 12, bottom: 4),
      leading: Icon(module.icon, color: module.color),
      title: Text(
        module.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
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
          onTap: () => _go(
            context,
            ErpModuleScreen(module: module),
          ),
        ),
        ...entities.map(
          (ErpEntity entity) => ListTile(
            dense: true,
            leading: Icon(
              entity.icon,
              color: entity.color,
              size: 20,
            ),
            title: Text(entity.title),
            trailing: const Icon(Icons.chevron_right, size: 17),
            onTap: () => _go(
              context,
              ErpEntityListScreen(entity: entity),
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
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
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
    Color color = AppColors.primary,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  void _replace(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.pop(context);
    await AuthService().signOut();
    SessionState.instance.clear();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const MyHomePage(title: 'CARTZ Link SMS'),
      ),
      (Route<dynamic> route) => false,
    );
  }
}
