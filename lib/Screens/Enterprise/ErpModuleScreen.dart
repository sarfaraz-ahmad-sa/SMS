import 'package:flutter/material.dart';

import '../../core/erp/erp_access_policy.dart';
import '../../core/erp/erp_entity.dart';
import '../../core/erp/erp_module.dart';
import '../../core/erp/tenant_erp_service.dart';
import '../../services/plan_entitlement_service.dart';
import '../../services/session_state.dart';
import '../../theme/app_theme.dart';
import '../../Widgets/PermissionGate.dart';
import '../../Widgets/saas_scaffold.dart';
import 'ErpEntityListScreen.dart';
import 'SchoolProfileScreen.dart';

class ErpModuleScreen extends StatefulWidget {
  final ErpModule module;

  const ErpModuleScreen({super.key, required this.module});

  @override
  State<ErpModuleScreen> createState() => _ErpModuleScreenState();
}

class _ErpModuleScreenState extends State<ErpModuleScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = SessionState.instance;
    final entitlement = PlanEntitlementService(tenant: state.tenant);
    final canViewModule = entitlement.canAccessModule(widget.module.id) &&
        ErpAccessPolicy.canViewModule(
          widget.module,
          state.user,
          state.hasPermission,
        );
    if (!canViewModule) {
      return SaasScaffold(
        title: widget.module.title,
        activeRoute: '/erp-module',
        activeModuleId: widget.module.id,
        body: const PermissionDeniedView(),
      );
    }
    final entities = widget.module.entities
        .where(
          (ErpEntity entity) => ErpAccessPolicy.canViewEntity(
            entity,
            state.user,
            state.hasPermission,
          ),
        )
        .where((ErpEntity entity) {
          if (_query.isEmpty) return true;
          final value = '${entity.title} ${entity.description}'.toLowerCase();
          return value.contains(_query);
        })
        .toList();

    return SaasScaffold(
      title: widget.module.title,
      activeRoute: '/erp-module',
      activeModuleId: widget.module.id,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1220),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: <Widget>[
              _ModuleHero(module: widget.module),
              const SizedBox(height: 16),
              if (widget.module.id == 'school-setup') ...<Widget>[
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.school_outlined),
                    ),
                    title: const Text(
                      'School Profile',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Name, code, timezone, currency, logo and active year.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SchoolProfileScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                onChanged: (String value) {
                  setState(() => _query = value.trim().toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Search ${widget.module.title.toLowerCase()} options...',
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Module Options',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${entities.length} authorized workflows',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (TenantErpService().isDemoMode)
                    const _DemoBadge(),
                ],
              ),
              const SizedBox(height: 12),
              if (entities.isEmpty)
                const _NoOptions()
              else
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final columns = constraints.maxWidth >= 1050
                        ? 3
                        : constraints.maxWidth >= 680
                            ? 2
                            : 1;
                    final ratio = columns == 1 ? 2.75 : 2.05;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: ratio,
                      ),
                      itemCount: entities.length,
                      itemBuilder: (BuildContext context, int index) {
                        final entity = entities[index];
                        return _EntityCard(
                          entity: entity,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ErpEntityListScreen(entity: entity),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              const SizedBox(height: 24),
              _WorkflowNotice(module: widget.module),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleHero extends StatelessWidget {
  final ErpModule module;

  const _ModuleHero({required this.module});

  @override
  Widget build(BuildContext context) {
    final tenant = SessionState.instance.tenant;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[module.color, module.color.withOpacity(0.72)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: module.color.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.17),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(module.icon, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  module.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  module.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    _WhitePill(label: tenant?.name ?? 'Active school'),
                    _WhitePill(
                      label: SessionState.instance.activeAcademicYearId ??
                          'Academic year not selected',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EntityCard extends StatelessWidget {
  final ErpEntity entity;
  final VoidCallback onTap;

  const _EntityCard({required this.entity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final state = SessionState.instance;
    final canManage = ErpAccessPolicy.canEdit(
      entity,
      state.hasPermission,
    );
    final canSubmit = ErpAccessPolicy.canCreate(
      entity,
      state.user,
      state.hasPermission,
    );
    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: entity.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(entity.icon, color: entity.color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            entity.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        _EntityCount(entity: entity),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entity.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: <Widget>[
                        Icon(
                          canManage
                              ? Icons.edit_note_outlined
                              : canSubmit
                                  ? Icons.add_task_outlined
                                  : Icons.visibility_outlined,
                          size: 14,
                          color: entity.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          canManage
                              ? 'View and manage'
                              : canSubmit
                                  ? 'View and submit'
                                  : 'View only',
                          style: TextStyle(
                            color: entity.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntityCount extends StatefulWidget {
  final ErpEntity entity;

  const _EntityCount({required this.entity});

  @override
  State<_EntityCount> createState() => _EntityCountState();
}

class _EntityCountState extends State<_EntityCount> {
  late Future<int> _future;

  @override
  void initState() {
    super.initState();
    _future = TenantErpService().countVisible(widget.entity);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: widget.entity.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            snapshot.hasData ? '${snapshot.data}' : '—',
            style: TextStyle(
              color: widget.entity.color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

class _WorkflowNotice extends StatelessWidget {
  final ErpModule module;

  const _WorkflowNotice({required this.module});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.security_outlined, color: module.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Controlled school workflow',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Every record is tenant-scoped, retains created/updated metadata, and is archived instead of hard deleted. Financial approval, result publication, payroll disbursement and other high-risk actions should be finalized through the trusted backend before public production use.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhitePill extends StatelessWidget {
  final String label;

  const _WhitePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'LOCAL DEMO MODE',
        style: TextStyle(
          color: AppColors.warning,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _NoOptions extends StatelessWidget {
  const _NoOptions();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          children: <Widget>[
            Icon(Icons.lock_outline, size: 44),
            SizedBox(height: 10),
            Text(
              'No authorized options',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            SizedBox(height: 5),
            Text(
              'Your school role does not include access to this module.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
