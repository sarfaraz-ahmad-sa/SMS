import 'dart:async';

import 'package:flutter/material.dart';

import '../Widgets/jinn_ui.dart';
import '../Widgets/saas_scaffold.dart';
import '../core/erp/erp_access_policy.dart';
import '../core/erp/erp_catalog.dart';
import '../core/erp/erp_module.dart';
import '../services/plan_entitlement_service.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';

class ModulesHubScreen extends StatefulWidget {
  const ModulesHubScreen({super.key});

  @override
  State<ModulesHubScreen> createState() => _ModulesHubScreenState();
}

class _ModulesHubScreenState extends State<ModulesHubScreen> {
  Timer? _searchDebounce;
  String _query = '';

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
    final state = SessionState.instance;
    final entitlement = PlanEntitlementService(tenant: state.tenant);
    final modules = ErpCatalog.modules
        .where((ErpModule module) => entitlement.canAccessModule(module.id))
        .where((ErpModule module) => ErpAccessPolicy.canViewModule(
              module,
              state.user,
              state.hasPermission,
            ))
        .where((ErpModule module) {
          if (_query.isEmpty) return true;
          return '${module.title} ${module.description}'.toLowerCase().contains(_query);
        })
        .toList(growable: false);

    return SaasScaffold(
      title: 'All Modules',
      activeRoute: '/modules',
      body: JinnPage(
        maxWidth: 1380,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final mobile = constraints.maxWidth < 620;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (mobile) ...<Widget>[
                      Text(
                        'Hello, ${_firstName(state.user?.displayName)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      mobile ? 'Academics & Operations' : 'School Modules',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontSize: mobile ? 20 : 25,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Everything your school team needs in one organized workspace.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    JinnSearchField(
                      hintText: 'Search modules...',
                      onChanged: _queueSearch,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            if (modules.isEmpty)
              const JinnEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No modules found',
                message: 'Try a different search term or check your permissions.',
              )
            else
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final mobile = constraints.maxWidth < 620;
                  final tablet = constraints.maxWidth < 980;
                  final columns = mobile ? 3 : tablet ? 3 : 4;
                  final ratio = mobile ? 0.88 : 1.58;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: mobile ? 12 : 14,
                      crossAxisSpacing: mobile ? 12 : 14,
                      childAspectRatio: ratio,
                    ),
                    itemCount: modules.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _ModuleTile(
                        module: modules[index],
                        compact: mobile,
                      );
                    },
                  );
                },
              ),
            const SizedBox(height: 28),
            _LearningBanner(compact: MediaQuery.sizeOf(context).width < 620),
          ],
        ),
      ),
    );
  }

  String _firstName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'User';
    return text.split(RegExp(r'\s+')).first;
  }
}

class _ModuleTile extends StatefulWidget {
  final ErpModule module;
  final bool compact;

  const _ModuleTile({required this.module, required this.compact});

  @override
  State<_ModuleTile> createState() => _ModuleTileState();
}

class _ModuleTileState extends State<_ModuleTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(widget.module.id);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.015 : 1,
        duration: const Duration(milliseconds: 150),
        child: JinnCard(
          onTap: () => Navigator.pushNamed(context, '/erp-module', arguments: widget.module),
          padding: EdgeInsets.all(widget.compact ? 10 : 16),
          shadow: _hovered,
          child: widget.compact
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    JinnIconBadge(
                      icon: widget.module.icon,
                      color: tone.foreground,
                      background: tone.background,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.module.title,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, height: 1.15),
                    ),
                  ],
                )
              : Row(
                  children: <Widget>[
                    JinnIconBadge(
                      icon: widget.module.icon,
                      color: tone.foreground,
                      background: tone.background,
                      size: 52,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.module.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.module.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}

class _LearningBanner extends StatelessWidget {
  final bool compact;
  const _LearningBanner({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.pastelCyan,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: const Color(0xFFD6ECED)),
      ),
      child: Row(
        children: <Widget>[
          const JinnIconBadge(
            icon: Icons.auto_stories_rounded,
            color: Color(0xFF1D8A91),
            background: Colors.white,
            size: 50,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('E-Learning Workspace', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  'Lessons, assignments, results and communication in one connected flow.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (!compact)
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.arrow_forward_rounded, size: 17),
              label: const Text('Explore'),
            ),
        ],
      ),
    );
  }
}

_Tone _toneFor(String id) {
  const tones = <_Tone>[
    _Tone(AppColors.pastelGold, Color(0xFFD89614)),
    _Tone(AppColors.pastelRose, Color(0xFFE05D65)),
    _Tone(AppColors.pastelBlue, Color(0xFF4E68D8)),
    _Tone(AppColors.pastelCyan, Color(0xFF22949A)),
    _Tone(AppColors.pastelGreen, Color(0xFF27936B)),
    _Tone(AppColors.pastelPurple, Color(0xFF7B5DC7)),
  ];
  final code = id.codeUnits.fold<int>(0, (int value, int item) => value + item);
  return tones[code % tones.length];
}

class _Tone {
  final Color background;
  final Color foreground;
  const _Tone(this.background, this.foreground);
}
