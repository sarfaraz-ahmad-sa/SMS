import 'package:flutter/material.dart';

import '../../Widgets/PermissionGate.dart';
import '../../Widgets/jinn_ui.dart';
import '../../Widgets/saas_scaffold.dart';
import '../../core/erp/erp_access_policy.dart';
import '../../core/erp/erp_entity.dart';
import '../../core/erp/erp_module.dart';
import '../../core/erp/tenant_erp_service.dart';
import '../../services/plan_entitlement_service.dart';
import '../../services/session_state.dart';
import '../../theme/app_theme.dart';
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
        ErpAccessPolicy.canViewModule(widget.module, state.user, state.hasPermission);
    if (!canViewModule) {
      return SaasScaffold(
        title: widget.module.title,
        activeRoute: '/erp-module',
        activeModuleId: widget.module.id,
        body: const PermissionDeniedView(),
      );
    }

    final entities = widget.module.entities
        .where((ErpEntity entity) => ErpAccessPolicy.canViewEntity(entity, state.user, state.hasPermission))
        .where((ErpEntity entity) {
          if (_query.isEmpty) return true;
          return '${entity.title} ${entity.description}'.toLowerCase().contains(_query);
        })
        .toList(growable: false);

    return SaasScaffold(
      title: widget.module.title,
      activeRoute: '/erp-module',
      activeModuleId: widget.module.id,
      body: JinnPage(
        maxWidth: 1380,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _ModuleHeader(module: widget.module, workflowCount: entities.length),
            const SizedBox(height: 16),
            if (widget.module.id == 'school-setup') ...<Widget>[
              JinnCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const SchoolProfileScreen()),
                ),
                child: const Row(
                  children: <Widget>[
                    JinnIconBadge(icon: Icons.school_outlined, color: AppColors.navigation, background: AppColors.pastelBlue),
                    SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('School Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          SizedBox(height: 3),
                          Text('Branding, contact details, timezone and active academic year.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            JinnSearchField(
              hintText: 'Search ${widget.module.title.toLowerCase()} workflows...',
              onChanged: (String value) => setState(() => _query = value.trim().toLowerCase()),
            ),
            const SizedBox(height: 20),
            JinnSectionHeader(
              title: 'Workflows',
              subtitle: '${entities.length} authorized options',
              trailing: TenantErpService().isDemoMode
                  ? const JinnStatusPill(label: 'Demo data', color: AppColors.info, icon: Icons.science_outlined)
                  : null,
            ),
            const SizedBox(height: 12),
            if (entities.isEmpty)
              const JinnEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matching workflow',
                message: 'Try another search term or check your account permissions.',
              )
            else
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final mobile = constraints.maxWidth < 620;
                  final columns = mobile ? 2 : constraints.maxWidth < 980 ? 2 : 3;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: mobile ? 1.08 : 2.18,
                    ),
                    itemCount: entities.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _WorkflowCard(entity: entities[index], compact: mobile);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ModuleHeader extends StatelessWidget {
  final ErpModule module;
  final int workflowCount;

  const _ModuleHeader({required this.module, required this.workflowCount});

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 720;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 17 : 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          JinnIconBadge(
            icon: module.icon,
            color: module.color,
            background: module.color.withOpacity(0.1),
            size: mobile ? 54 : 64,
          ),
          SizedBox(width: mobile ? 14 : 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(module.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: mobile ? 20 : 25)),
                const SizedBox(height: 5),
                Text(module.description, maxLines: mobile ? 2 : 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: <Widget>[
                    JinnStatusPill(label: '$workflowCount workflows', color: module.color, icon: Icons.grid_view_rounded),
                    JinnStatusPill(label: SessionState.instance.activeAcademicYearId ?? 'Academic year', color: AppColors.success, icon: Icons.calendar_month_outlined),
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

class _WorkflowCard extends StatefulWidget {
  final ErpEntity entity;
  final bool compact;

  const _WorkflowCard({required this.entity, required this.compact});

  @override
  State<_WorkflowCard> createState() => _WorkflowCardState();
}

class _WorkflowCardState extends State<_WorkflowCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final state = SessionState.instance;
    final canCreate = ErpAccessPolicy.canCreate(widget.entity, state.user, state.hasPermission);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.012 : 1,
        duration: const Duration(milliseconds: 150),
        child: JinnCard(
          shadow: _hovered,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => ErpEntityListScreen(entity: widget.entity)),
          ),
          padding: EdgeInsets.all(widget.compact ? 13 : 16),
          child: widget.compact
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    JinnIconBadge(icon: widget.entity.icon, color: widget.entity.color, size: 46),
                    const SizedBox(height: 9),
                    Text(widget.entity.title, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text(canCreate ? 'View & add' : 'View records', style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
                  ],
                )
              : Row(
                  children: <Widget>[
                    JinnIconBadge(icon: widget.entity.icon, color: widget.entity.color, size: 50),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(widget.entity.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(widget.entity.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10.5)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: _hovered ? widget.entity.color : AppColors.textSecondary, size: 19),
                  ],
                ),
        ),
      ),
    );
  }
}
