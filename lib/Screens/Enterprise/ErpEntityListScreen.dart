import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../Widgets/PermissionGate.dart';
import '../../Widgets/saas_scaffold.dart';

import '../../core/erp/erp_access_policy.dart';
import '../../core/erp/erp_catalog.dart';
import '../../core/erp/erp_entity.dart';
import '../../core/erp/erp_field.dart';
import '../../core/erp/erp_record.dart';
import '../../core/erp/erp_repository.dart';
import '../../core/erp/tenant_erp_service.dart';
import '../../services/plan_entitlement_service.dart';
import '../../services/session_state.dart';
import '../../theme/app_theme.dart';
import 'ErpEntityForm.dart';

class ErpEntityListScreen extends StatefulWidget {
  final ErpEntity entity;

  const ErpEntityListScreen({super.key, required this.entity});

  @override
  State<ErpEntityListScreen> createState() => _ErpEntityListScreenState();
}

class _ErpEntityListScreenState extends State<ErpEntityListScreen> {
  final ErpRepository _service = TenantErpService();
  final TextEditingController _searchController = TextEditingController();
  final List<ErpRecord> _records = <ErpRecord>[];
  String _query = '';
  String? _status;
  Object? _cursor;
  Object? _loadError;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant ErpEntityListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entity.collection != widget.entity.collection) {
      _searchController.clear();
      _query = '';
      _status = null;
      _reload();
    }
  }

  Future<void> _reload() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
        _cursor = null;
        _hasMore = false;
      });
    }
    try {
      final page = await _service.fetchPage(widget.entity);
      if (!mounted) return;
      setState(() {
        _records
          ..clear()
          ..addAll(page.records);
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _service.fetchPage(
        widget.entity,
        startAfter: _cursor,
      );
      if (!mounted) return;
      setState(() {
        _records.addAll(page.records);
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      _showError(error.toString());
    }
  }

  bool get _canCreate => ErpAccessPolicy.canCreate(
        widget.entity,
        SessionState.instance.user,
        SessionState.instance.hasPermission,
      );

  bool get _canEdit => ErpAccessPolicy.canEdit(
        widget.entity,
        SessionState.instance.hasPermission,
      );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm([ErpRecord? record]) async {
    if (record == null && !_canCreate) return;
    if (record != null && !_canEdit) return;
    final saved = await showErpEntityForm(
      context: context,
      entity: widget.entity,
      record: record,
    );
    if (saved == true && mounted) {
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              record == null
                  ? '${widget.entity.singularTitle} created successfully.'
                  : '${widget.entity.singularTitle} updated successfully.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
    }
  }

  Future<void> _archive(ErpRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Archive ${widget.entity.singularTitle}?'),
        content: const Text(
          'The record will be hidden from active lists but retained for audit history.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.archive(widget.entity, record.id);
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Record archived.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      _showError(error.toString());
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.danger),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = SessionState.instance;
    final module = ErpCatalog.moduleForCollection(widget.entity.collection);
    final entitlement = PlanEntitlementService(tenant: state.tenant);
    final canView =
        (module == null || entitlement.canAccessModule(module.id)) &&
            ErpAccessPolicy.canViewEntity(
              widget.entity,
              state.user,
              state.hasPermission,
            );
    if (!canView) {
      return SaasScaffold(
        title: widget.entity.title,
        activeRoute: '/erp-entity',
        activeModuleId: module?.id,
        activeEntityCollection: widget.entity.collection,
        body: const PermissionDeniedView(),
      );
    }
    return SaasScaffold(
      title: widget.entity.title,
      activeRoute: '/erp-entity',
      activeModuleId: module?.id,
      activeEntityCollection: widget.entity.collection,
      actions: <Widget>[
        if (_canCreate)
          IconButton(
            tooltip: 'Add ${widget.entity.singularTitle}',
            onPressed: _openForm,
            icon: const Icon(Icons.add_circle_outline),
          ),
      ],
      floatingActionButton: _canCreate
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              icon: const Icon(Icons.add),
              label: Text('Add ${widget.entity.singularTitle}'),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
                  ? _ErrorState(
                      message: _loadError.toString(),
                      onRetry: _reload,
                    )
                  : _buildRecordList(),
        ),
      ),
    );
  }

  Widget _buildRecordList() {
    final statusOptions = _statusOptions(_records);
    final records = _records.where(_matchesFilter).toList();
    return Column(
      children: <Widget>[
        _Header(
          entity: widget.entity,
          totalRecords: _records.length,
          visibleRecords: records.length,
          demoMode: _service.isDemoMode,
        ),
        _Filters(
          controller: _searchController,
          status: _status,
          statusOptions: statusOptions,
          onQueryChanged: (String value) {
            setState(() => _query = value.trim().toLowerCase());
          },
          onStatusChanged: (String? value) {
            setState(() => _status = value);
          },
          onClear: () {
            _searchController.clear();
            setState(() {
              _query = '';
              _status = null;
            });
          },
        ),
        Expanded(
          child: records.isEmpty
              ? _EmptyState(
                  entity: widget.entity,
                  filtered: _records.isNotEmpty,
                  canManage: _canCreate,
                  onCreate: _openForm,
                )
              : LayoutBuilder(
                  builder: (
                    BuildContext context,
                    BoxConstraints constraints,
                  ) {
                    if (constraints.maxWidth >= 900) {
                      return _DesktopTable(
                        entity: widget.entity,
                        records: records,
                        canManage: _canEdit,
                        onView: _showDetails,
                        onEdit: _openForm,
                        onArchive: _archive,
                      );
                    }
                    return _MobileList(
                      entity: widget.entity,
                      records: records,
                      canManage: _canEdit,
                      onView: _showDetails,
                      onEdit: _openForm,
                      onArchive: _archive,
                    );
                  },
                ),
        ),
        if (_hasMore)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: OutlinedButton.icon(
              onPressed: _loadingMore ? null : _loadMore,
              icon: _loadingMore
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more_rounded),
              label: Text(_loadingMore ? 'Loading…' : 'Load next 50 records'),
            ),
          ),
      ],
    );
  }

  bool _matchesFilter(ErpRecord record) {
    if (_status != null &&
        record.data[widget.entity.statusField]?.toString() != _status) {
      return false;
    }
    if (_query.isEmpty) return true;

    final fields = widget.entity.searchableFields.isEmpty
        ? widget.entity.fields
            .where((ErpField field) => !field.internal)
            .toList(growable: false)
        : widget.entity.searchableFields;
    for (final field in fields) {
      final value = record.data[field.key];
      if (value != null && value.toString().toLowerCase().contains(_query)) {
        return true;
      }
    }
    return false;
  }

  List<String> _statusOptions(List<ErpRecord> records) {
    final key = widget.entity.statusField;
    if (key == null) return const <String>[];
    final values = records
        .map((ErpRecord record) => record.data[key]?.toString().trim() ?? '')
        .where((String value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  void _showDetails(ErpRecord record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) => FractionallySizedBox(
        heightFactor: 0.86,
        child: _RecordDetails(entity: widget.entity, record: record),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ErpEntity entity;
  final int totalRecords;
  final int visibleRecords;
  final bool demoMode;

  const _Header({
    required this.entity,
    required this.totalRecords,
    required this.visibleRecords,
    required this.demoMode,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: entity.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(entity.icon, color: entity.color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entity.title,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  entity.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '$visibleRecords',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                visibleRecords == totalRecords
                    ? 'active records'
                    : 'of $totalRecords records',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              if (demoMode)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'DEMO DATA',
                    style: TextStyle(
                      color: scheme.onSecondaryContainer,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final TextEditingController controller;
  final String? status;
  final List<String> statusOptions;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onClear;

  const _Filters({
    required this.controller,
    required this.status,
    required this.statusOptions,
    required this.onQueryChanged,
    required this.onStatusChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final search = TextField(
            controller: controller,
            onChanged: onQueryChanged,
            decoration: const InputDecoration(
              hintText: 'Search records...',
              prefixIcon: Icon(Icons.search),
            ),
          );
          final filter = statusOptions.isEmpty
              ? const SizedBox.shrink()
              : DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.filter_alt_outlined),
                  ),
                  items: <DropdownMenuItem<String>>[
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All statuses'),
                    ),
                    ...statusOptions.map(
                      (String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    ),
                  ],
                  onChanged: onStatusChanged,
                );

          if (constraints.maxWidth >= 650) {
            return Row(
              children: <Widget>[
                Expanded(child: search),
                if (statusOptions.isNotEmpty) ...<Widget>[
                  const SizedBox(width: 12),
                  SizedBox(width: 220, child: filter),
                ],
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Clear filters',
                  onPressed: onClear,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                ),
              ],
            );
          }

          return Column(
            children: <Widget>[
              search,
              if (statusOptions.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(child: filter),
                    IconButton(
                      tooltip: 'Clear filters',
                      onPressed: onClear,
                      icon: const Icon(Icons.filter_alt_off_outlined),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DesktopTable extends StatelessWidget {
  final ErpEntity entity;
  final List<ErpRecord> records;
  final bool canManage;
  final ValueChanged<ErpRecord> onView;
  final ValueChanged<ErpRecord> onEdit;
  final ValueChanged<ErpRecord> onArchive;

  const _DesktopTable({
    required this.entity,
    required this.records,
    required this.canManage,
    required this.onView,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final fields = entity.listFields.take(5).toList();
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            headingRowColor: MaterialStatePropertyAll<Color>(
              entity.color.withOpacity(0.07),
            ),
            columns: <DataColumn>[
              ...fields.map(
                (ErpField field) => DataColumn(
                  label: Text(
                    field.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const DataColumn(label: Text('Actions')),
            ],
            rows: records
                .map(
                  (ErpRecord record) => DataRow(
                    onSelectChanged: (_) => onView(record),
                    cells: <DataCell>[
                      ...fields.map(
                        (ErpField field) => DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 230),
                            child: field.key == entity.statusField
                                ? _StatusChip(
                                    value: _value(record.data[field.key]),
                                  )
                                : Text(
                                    _formatValue(field, record.data[field.key]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ),
                      ),
                      DataCell(
                        _Actions(
                          canManage: canManage,
                          onView: () => onView(record),
                          onEdit: () => onEdit(record),
                          onArchive: () => onArchive(record),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _MobileList extends StatelessWidget {
  final ErpEntity entity;
  final List<ErpRecord> records;
  final bool canManage;
  final ValueChanged<ErpRecord> onView;
  final ValueChanged<ErpRecord> onEdit;
  final ValueChanged<ErpRecord> onArchive;

  const _MobileList({
    required this.entity,
    required this.records,
    required this.canManage,
    required this.onView,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final record = records[index];
        final primary = _value(record.data[entity.primaryField]);
        final secondary = entity.secondaryField == null
            ? ''
            : _value(record.data[entity.secondaryField]);
        final status = entity.statusField == null
            ? ''
            : _value(record.data[entity.statusField]);

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onView(record),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: entity.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(entity.icon, color: entity.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          primary.isEmpty ? entity.singularTitle : primary,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (secondary.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 3),
                          Text(
                            secondary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (status.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          _StatusChip(value: status),
                        ],
                      ],
                    ),
                  ),
                  _Actions(
                    compact: true,
                    canManage: canManage,
                    onView: () => onView(record),
                    onEdit: () => onEdit(record),
                    onArchive: () => onArchive(record),
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

class _Actions extends StatelessWidget {
  final bool canManage;
  final bool compact;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const _Actions({
    required this.canManage,
    required this.onView,
    required this.onEdit,
    required this.onArchive,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      onSelected: (String value) {
        switch (value) {
          case 'view':
            onView();
            break;
          case 'edit':
            onEdit();
            break;
          case 'archive':
            onArchive();
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'view',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.visibility_outlined),
            title: Text('View details'),
          ),
        ),
        if (canManage)
          const PopupMenuItem<String>(
            value: 'edit',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.edit_outlined),
              title: Text('Edit'),
            ),
          ),
        if (canManage)
          const PopupMenuItem<String>(
            value: 'archive',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.archive_outlined),
              title: Text('Archive'),
            ),
          ),
      ],
      child: compact
          ? const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.more_vert),
            )
          : const Icon(Icons.more_horiz),
    );
  }
}

class _RecordDetails extends StatelessWidget {
  final ErpEntity entity;
  final ErpRecord record;

  const _RecordDetails({required this.entity, required this.record});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: entity.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(entity.icon, color: entity.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _value(record.data[entity.primaryField]).isEmpty
                          ? entity.singularTitle
                          : _value(record.data[entity.primaryField]),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),
                    Text(
                      entity.singularTitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              ...entity.fields.where((ErpField field) => !field.internal).map(
                    (ErpField field) => _DetailRow(
                      label: field.label,
                      value: _formatValue(field, record.data[field.key]),
                    ),
                  ),
              const Divider(height: 28),
              _DetailRow(label: 'Record ID', value: record.id),
              _DetailRow(
                label: 'Created by',
                value: _value(record.data['createdBy']),
              ),
              _DetailRow(
                label: 'Updated by',
                value: _value(record.data['updatedBy']),
              ),
              _DetailRow(
                label: 'Last updated',
                value: _formatAny(record.data['updatedAt']),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String value;

  const _StatusChip({required this.value});

  @override
  Widget build(BuildContext context) {
    final lower = value.toLowerCase();
    final color = lower.contains('active') ||
            lower.contains('approved') ||
            lower.contains('paid') ||
            lower.contains('completed') ||
            lower.contains('published') ||
            lower.contains('present') ||
            lower.contains('valid') ||
            lower.contains('posted')
        ? AppColors.success
        : lower.contains('rejected') ||
                lower.contains('failed') ||
                lower.contains('overdue') ||
                lower.contains('cancelled') ||
                lower.contains('suspended') ||
                lower.contains('absent') ||
                lower.contains('revoked')
            ? AppColors.danger
            : lower.contains('pending') ||
                    lower.contains('draft') ||
                    lower.contains('review') ||
                    lower.contains('late') ||
                    lower.contains('open')
                ? AppColors.warning
                : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ErpEntity entity;
  final bool filtered;
  final bool canManage;
  final VoidCallback onCreate;

  const _EmptyState({
    required this.entity,
    required this.filtered,
    required this.canManage,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              filtered ? Icons.search_off_outlined : entity.icon,
              size: 58,
              color: entity.color.withOpacity(0.55),
            ),
            const SizedBox(height: 14),
            Text(
              filtered
                  ? 'No matching records'
                  : 'No ${entity.title.toLowerCase()} yet',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              filtered
                  ? 'Clear the filters or try a different search.'
                  : entity.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (!filtered && canManage) ...<Widget>[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: Text('Add ${entity.singularTitle}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.cloud_off_outlined,
                size: 56, color: AppColors.danger),
            const SizedBox(height: 12),
            const Text(
              'Could not load records',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

String _value(dynamic value) {
  if (value == null) return '';
  if (value is Iterable) return value.join(', ');
  return value.toString();
}

String _formatValue(ErpField field, dynamic value) {
  if (value == null || value.toString().trim().isEmpty) return '—';
  if (field.type == ErpFieldType.money && value is num) {
    return 'PKR ${_withCommas(value.toStringAsFixed(0))}';
  }
  if (field.type == ErpFieldType.boolean) {
    return value == true ? 'Yes' : 'No';
  }
  return _formatAny(value);
}

String _formatAny(dynamic value) {
  if (value == null) return '—';
  if (value is Timestamp) {
    final date = value.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  if (value is DateTime) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
  if (value is Iterable) return value.join(', ');
  return value.toString();
}

String _withCommas(String value) {
  final parts = value.split('.');
  final source = parts.first;
  final buffer = StringBuffer();
  for (var index = 0; index < source.length; index++) {
    if (index > 0 && (source.length - index) % 3 == 0) buffer.write(',');
    buffer.write(source[index]);
  }
  if (parts.length > 1) buffer.write('.${parts[1]}');
  return buffer.toString();
}
