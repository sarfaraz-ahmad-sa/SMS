import 'package:flutter/material.dart';

import '../Widgets/saas_scaffold.dart';

import '../core/erp/tenant_erp_service.dart';
import '../services/models/user_role.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SaasScaffold(
      title: 'Settings & Administration',
      activeRoute: '/settings',
      body: ListenableBuilder(
        listenable: SessionState.instance,
        builder: (BuildContext context, Widget? child) {
          final state = SessionState.instance;
          final mode = state.themeMode;
          final tenant = state.tenant;
          final user = state.user;
          final demoMode = TenantErpService().isDemoMode;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  _SectionTitle(
                    title: 'Active School Context',
                    subtitle: 'The tenant, campus and academic year used by every module.',
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    child: Column(
                      children: <Widget>[
                        _SettingTile(
                          icon: Icons.school_outlined,
                          title: tenant?.name ?? 'No active school',
                          subtitle: tenant?.code == null
                              ? 'Tenant not configured'
                              : 'School code: ${tenant!.code}',
                        ),
                        const Divider(height: 1),
                        _SettingTile(
                          icon: Icons.location_city_outlined,
                          title: state.activeCampusId ?? 'All authorized campuses',
                          subtitle: 'Active campus scope',
                        ),
                        const Divider(height: 1),
                        _SettingTile(
                          icon: Icons.calendar_month_outlined,
                          title: state.activeAcademicYearId ??
                              'Academic year not selected',
                          subtitle: 'Active academic year',
                        ),
                        const Divider(height: 1),
                        _SettingTile(
                          icon: Icons.workspace_premium_outlined,
                          title: tenant?.subscription.planLabel ?? 'No plan',
                          subtitle: tenant?.subscription.isUsable == true
                              ? 'Subscription active'
                              : 'Subscription requires attention',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    title: 'Appearance',
                    subtitle: 'Choose the interface theme saved to your account.',
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    child: Column(
                      children: <Widget>[
                        RadioListTile<ThemeMode>(
                          title: const Text('Light'),
                          secondary: const Icon(Icons.light_mode_outlined),
                          value: ThemeMode.light,
                          groupValue: mode,
                          onChanged: _setTheme,
                        ),
                        const Divider(height: 1),
                        RadioListTile<ThemeMode>(
                          title: const Text('Dark'),
                          secondary: const Icon(Icons.dark_mode_outlined),
                          value: ThemeMode.dark,
                          groupValue: mode,
                          onChanged: _setTheme,
                        ),
                        const Divider(height: 1),
                        RadioListTile<ThemeMode>(
                          title: const Text('System default'),
                          secondary: const Icon(Icons.brightness_auto_outlined),
                          value: ThemeMode.system,
                          groupValue: mode,
                          onChanged: _setTheme,
                        ),
                      ],
                    ),
                  ),
                  if (demoMode && user != null) ...<Widget>[
                    const SizedBox(height: 24),
                    const _SectionTitle(
                      title: 'Demo Role Preview',
                      subtitle:
                          'Preview exactly which modules each school role can access.',
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            DropdownButtonFormField<UserRole>(
                              value: user.role,
                              decoration: const InputDecoration(
                                labelText: 'Preview role',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              items: UserRole.values
                                  .map(
                                    (UserRole role) =>
                                        DropdownMenuItem<UserRole>(
                                      value: role,
                                      child: Text(role.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (UserRole? role) {
                                if (role == null) return;
                                state.updateUser(
                                  user.copyWith(
                                    displayName: '${role.label} (Demo)',
                                    roles: <UserRole>[role],
                                    permissions: <String>{},
                                    deniedPermissions: <String>{},
                                  ),
                                );
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Dashboard access changed to ${role.label}.',
                                      ),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                              },
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                state.updateUser(
                                  user.copyWith(
                                    displayName: 'School Owner',
                                    roles: const <UserRole>[
                                      UserRole.schoolOwner,
                                    ],
                                    permissions: const <String>{'*'},
                                    deniedPermissions: const <String>{},
                                  ),
                                );
                              },
                              icon: const Icon(Icons.restart_alt),
                              label: const Text('Restore Full Demo Access'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    title: 'Production Controls',
                    subtitle: 'Operational controls required before live school use.',
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    child: Column(
                      children: const <Widget>[
                        _ControlTile(
                          icon: Icons.security_outlined,
                          title: 'Role-based access control',
                          subtitle: 'Enabled through tenant roles and permissions.',
                          ready: true,
                        ),
                        Divider(height: 1),
                        _ControlTile(
                          icon: Icons.domain_outlined,
                          title: 'Tenant isolation',
                          subtitle: 'All operational collections are school scoped.',
                          ready: true,
                        ),
                        Divider(height: 1),
                        _ControlTile(
                          icon: Icons.history_outlined,
                          title: 'Archive and record metadata',
                          subtitle: 'Records are archived instead of hard deleted.',
                          ready: true,
                        ),
                        Divider(height: 1),
                        _ControlTile(
                          icon: Icons.verified_user_outlined,
                          title: 'Trusted account and approval backend',
                          subtitle:
                              'Cloud Functions protect user provisioning, quotas, approvals and audit events.',
                          ready: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Center(
                    child: Text(
                      'CARTZ Link School ERP SaaS',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _setTheme(ThemeMode? mode) {
    if (mode != null) SessionState.instance.setThemeMode(mode);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
    );
  }
}

class _ControlTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool ready;

  const _ControlTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ready,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: ready ? AppColors.success : AppColors.warning),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (ready ? AppColors.success : AppColors.warning).withOpacity(0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          ready ? 'READY' : 'BACKEND',
          style: TextStyle(
            color: ready ? AppColors.success : AppColors.warning,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
