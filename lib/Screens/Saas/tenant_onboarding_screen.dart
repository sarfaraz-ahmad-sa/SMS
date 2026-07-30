import 'package:flutter/material.dart';

import '../../Widgets/PermissionGate.dart';
import '../../Widgets/saas_scaffold.dart';
import '../../core/erp/erp_catalog.dart';
import '../../core/erp/tenant_erp_service.dart';
import '../../services/models/app_permission.dart';
import '../../services/session_state.dart';
import '../../theme/app_theme.dart';
import '../Enterprise/ErpEntityListScreen.dart';
import '../Enterprise/SchoolProfileScreen.dart';
import '../AccountManagement.dart';

class TenantOnboardingScreen extends StatefulWidget {
  const TenantOnboardingScreen({super.key});

  @override
  State<TenantOnboardingScreen> createState() => _TenantOnboardingScreenState();
}

class _TenantOnboardingScreenState extends State<TenantOnboardingScreen> {
  late Future<List<_OnboardingStep>> _stepsFuture;

  @override
  void initState() {
    super.initState();
    _stepsFuture = _loadSteps();
  }

  Future<List<_OnboardingStep>> _loadSteps() async {
    final service = TenantErpService();
    final state = SessionState.instance;
    final tenant = state.tenant;

    Future<int> count(String collection) async {
      try {
        return await service.count(collection);
      } catch (_) {
        return 0;
      }
    }

    final counts = await Future.wait<int>(<Future<int>>[
      count('campuses'),
      count('academic_years'),
      count('classes'),
      count('sections'),
      count('subjects'),
      count('fee_structures'),
      count('teachers'),
      count('students'),
    ]);

    return <_OnboardingStep>[
      _OnboardingStep(
        title: 'School profile and branding',
        subtitle: 'Name, code, logo, colour, timezone and currency.',
        icon: Icons.school_outlined,
        completed: tenant != null &&
            tenant.name.trim().isNotEmpty &&
            tenant.timezone.trim().isNotEmpty &&
            tenant.currency.trim().isNotEmpty,
        destination: const SchoolProfileScreen(),
      ),
      _entityStep(
        'Campus setup',
        'Create the main campus and any branches.',
        Icons.location_city_outlined,
        'campuses',
        counts[0] > 0,
      ),
      _entityStep(
        'Academic year',
        'Configure the active academic session.',
        Icons.calendar_month_outlined,
        'academic_years',
        counts[1] > 0,
      ),
      _entityStep(
        'Classes and sections',
        'Build the school hierarchy used by students and timetables.',
        Icons.account_tree_outlined,
        'classes',
        counts[2] > 0 && counts[3] > 0,
      ),
      _entityStep(
        'Subjects and grading',
        'Configure subjects and grading schemes.',
        Icons.menu_book_outlined,
        'subjects',
        counts[4] > 0,
      ),
      _entityStep(
        'Fee structure',
        'Define tuition, transport and other fee heads.',
        Icons.payments_outlined,
        'fee_structures',
        counts[5] > 0,
      ),
      _entityStep(
        'Teachers and staff',
        'Create teaching and operational staff records.',
        Icons.groups_outlined,
        'teachers',
        counts[6] > 0,
      ),
      _entityStep(
        'Students and guardians',
        'Import or create students before launch.',
        Icons.person_add_alt_1_outlined,
        'students',
        counts[7] > 0,
      ),
      _OnboardingStep(
        title: 'User accounts and invitations',
        subtitle: 'Create secure logins and assign role-based access.',
        icon: Icons.manage_accounts_outlined,
        completed: false,
        destination: const AccountManagementScreen(),
      ),
      _OnboardingStep(
        title: 'Launch review',
        subtitle: 'Verify subscription, security, integrations and backups.',
        icon: Icons.rocket_launch_outlined,
        completed: counts.take(7).every((int value) => value > 0),
        route: '/saas',
      ),
    ];
  }

  _OnboardingStep _entityStep(
    String title,
    String subtitle,
    IconData icon,
    String collection,
    bool completed,
  ) {
    final entity = ErpCatalog.entityByCollection(collection);
    return _OnboardingStep(
      title: title,
      subtitle: subtitle,
      icon: icon,
      completed: completed,
      destination: entity == null ? null : ErpEntityListScreen(entity: entity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canView = SessionState.instance.hasAnyPermission(const <String>[
      AppPermission.saasAdminView,
      AppPermission.schoolSetupView,
      AppPermission.schoolSetupManage,
      AppPermission.tenantManage,
    ]);
    if (!canView) {
      return const SaasScaffold(
        title: 'School Onboarding',
        activeRoute: '/onboarding',
        body: PermissionDeniedView(),
      );
    }
    return SaasScaffold(
      title: 'School Onboarding',
      activeRoute: '/onboarding',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: FutureBuilder<List<_OnboardingStep>>(
            future: _stepsFuture,
            builder: (
              BuildContext context,
              AsyncSnapshot<List<_OnboardingStep>> snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final steps = snapshot.data ?? const <_OnboardingStep>[];
              final completed = steps.where((_OnboardingStep step) => step.completed).length;
              final progress = steps.isEmpty ? 0.0 : completed / steps.length;

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() => _stepsFuture = _loadSteps());
                  await _stepsFuture;
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  children: <Widget>[
                    _OnboardingHero(
                      completed: completed,
                      total: steps.length,
                      progress: progress,
                    ),
                    const SizedBox(height: 20),
                    ...steps.asMap().entries.map(
                      (MapEntry<int, _OnboardingStep> entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StepCard(
                          number: entry.key + 1,
                          step: entry.value,
                          onTap: () => _openStep(entry.value),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openStep(_OnboardingStep step) {
    if (step.route != null) {
      Navigator.pushNamed(context, step.route!);
      return;
    }
    if (step.destination == null) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => step.destination!),
    ).then((_) {
      if (!mounted) return;
      setState(() => _stepsFuture = _loadSteps());
    });
  }
}

class _OnboardingStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool completed;
  final Widget? destination;
  final String? route;

  const _OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.completed,
    this.destination,
    this.route,
  });
}

class _OnboardingHero extends StatelessWidget {
  final int completed;
  final int total;
  final double progress;

  const _OnboardingHero({
    required this.completed,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final tenant = SessionState.instance.tenant;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.tenantGradient(tenant),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.rocket_launch_outlined, color: Colors.white, size: 34),
          const SizedBox(height: 14),
          const Text(
            'Launch your school workspace',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$completed of $total setup areas completed',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: Colors.white24,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int number;
  final _OnboardingStep step;
  final VoidCallback onTap;

  const _StepCard({
    required this.number,
    required this.step,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: step.completed
                        ? AppColors.success.withOpacity(0.12)
                        : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      step.icon,
                      color: step.completed
                          ? AppColors.success
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Positioned(
                    right: -5,
                    top: -5,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: step.completed
                          ? AppColors.success
                          : AppColors.textSecondary,
                      child: step.completed
                          ? const Icon(Icons.check, size: 13, color: Colors.white)
                          : Text(
                              '$number',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                step.completed ? 'Complete' : 'Set up',
                style: TextStyle(
                  color: step.completed
                      ? AppColors.success
                      : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
