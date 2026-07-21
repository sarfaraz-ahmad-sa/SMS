import 'package:flutter/material.dart';

import '../core/erp/erp_access_policy.dart';
import '../core/erp/erp_catalog.dart';
import '../core/erp/erp_entity.dart';
import '../core/erp/erp_module.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';
import 'Enterprise/ErpEntityListScreen.dart';
import 'Enterprise/ErpModuleScreen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionState.instance,
      builder: (BuildContext context, Widget? child) {
        final state = SessionState.instance;
        final user = state.user;

        final modules = ErpCatalog.modules
            .where(
              (ErpModule module) => ErpAccessPolicy.canViewModule(
                module,
                user,
                state.hasPermission,
              ),
            )
            .toList(growable: false);

        final normalized = _query.trim().toLowerCase();
        final results = <_GlobalSearchResult>[];

        for (final module in modules) {
          final moduleText =
              '${module.title} ${module.description}'.toLowerCase();
          if (normalized.isEmpty || moduleText.contains(normalized)) {
            results.add(
              _GlobalSearchResult.module(module),
            );
          }

          if (normalized.isNotEmpty) {
            for (final entity in module.entities) {
              if (!ErpAccessPolicy.canViewEntity(
                entity,
                user,
                state.hasPermission,
              )) {
                continue;
              }

              final entityText =
                  '${entity.title} ${entity.singularTitle} ${entity.description} ${module.title}'
                      .toLowerCase();
              if (entityText.contains(normalized)) {
                results.add(
                  _GlobalSearchResult.entity(module, entity),
                );
              }
            }
          }
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Global Search')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: (String value) {
                        setState(() => _query = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search modules and options...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _controller.clear();
                                  setState(() => _query = '');
                                  _focusNode.requestFocus();
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: results.isEmpty
                        ? const _EmptySearchResult()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: results.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (
                              BuildContext context,
                              int index,
                            ) {
                              final item = results[index];
                              return Card(
                                elevation: 0,
                                child: ListTile(
                                  leading: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: item.color.withOpacity(0.11),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Icon(item.icon, color: item.color),
                                  ),
                                  title: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    item.subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () => item.open(context),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GlobalSearchResult {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final ErpModule module;
  final ErpEntity? entity;

  const _GlobalSearchResult._({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.module,
    this.entity,
  });

  factory _GlobalSearchResult.module(ErpModule module) {
    return _GlobalSearchResult._(
      title: module.title,
      subtitle: '${module.description} · Module',
      icon: module.icon,
      color: module.color,
      module: module,
    );
  }

  factory _GlobalSearchResult.entity(
    ErpModule module,
    ErpEntity entity,
  ) {
    return _GlobalSearchResult._(
      title: entity.title,
      subtitle: '${module.title} · ${entity.description}',
      icon: entity.icon,
      color: entity.color,
      module: module,
      entity: entity,
    );
  }

  void open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => entity == null
            ? ErpModuleScreen(module: module)
            : ErpEntityListScreen(entity: entity!),
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.manage_search_rounded,
              size: 58,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'No matching module found',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Try another module or option name.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
