import 'package:flutter/material.dart';

import '../core/erp/erp_catalog.dart';
import '../core/erp/erp_entity.dart';
import '../core/erp/erp_record.dart';
import '../core/erp/tenant_erp_service.dart';
import '../services/session_state.dart';
import '../theme/app_theme.dart';

class SchoolContextSwitcher extends StatelessWidget {
  final bool compact;

  const SchoolContextSwitcher({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionState.instance,
      builder: (BuildContext context, Widget? child) {
        final state = SessionState.instance;
        if (compact) {
          return IconButton(
            tooltip: 'Campus and academic year',
            onPressed: () => _showContextSheet(context),
            icon: const Icon(Icons.tune_rounded),
          );
        }

        return OutlinedButton.icon(
          onPressed: () => _showContextSheet(context),
          icon: const Icon(Icons.location_city_outlined, size: 18),
          label: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              <String>[
                state.activeCampusId ?? 'All campuses',
                state.activeAcademicYearId ?? 'Select year',
              ].join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Future<void> _showContextSheet(BuildContext context) async {
    final state = SessionState.instance;
    final campusEntity = ErpCatalog.entityByCollection('campuses');
    final yearEntity = ErpCatalog.entityByCollection('academic_years');
    final records = await Future.wait<List<ErpRecord>>(<Future<List<ErpRecord>>>[
      _loadRecords(campusEntity),
      _loadRecords(yearEntity),
    ]);
    if (!context.mounted) return;

    final authorizedCampusIds = state.user?.campusIds ?? const <String>[];
    final campuses = records[0].where((ErpRecord record) {
      return authorizedCampusIds.isEmpty || authorizedCampusIds.contains(record.id);
    }).toList(growable: false);
    final years = records[1];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: <Widget>[
                const Text(
                  'Working Context',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Data, reports and workflows use the selected campus and academic year.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Campus',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                RadioListTile<String?>(
                  value: null,
                  groupValue: state.activeCampusId,
                  title: const Text('All authorized campuses'),
                  subtitle: const Text('Use combined school-wide data'),
                  onChanged: (String? value) {
                    state.setActiveCampus(null);
                    Navigator.pop(sheetContext);
                  },
                ),
                ...campuses.map(
                  (ErpRecord record) => RadioListTile<String?>(
                    value: record.id,
                    groupValue: state.activeCampusId,
                    title: Text(record.data['name']?.toString() ?? record.id),
                    subtitle: Text(record.data['code']?.toString() ?? ''),
                    onChanged: (String? value) {
                      state.setActiveCampus(value);
                      Navigator.pop(sheetContext);
                    },
                  ),
                ),
                const Divider(height: 28),
                const Text(
                  'Academic Year',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...years.map(
                  (ErpRecord record) => RadioListTile<String?>(
                    value: record.id,
                    groupValue: state.activeAcademicYearId,
                    title: Text(record.data['name']?.toString() ?? record.id),
                    subtitle: Text(record.data['status']?.toString() ?? ''),
                    onChanged: (String? value) {
                      state.setActiveAcademicYear(value);
                      Navigator.pop(sheetContext);
                    },
                  ),
                ),
                if (years.isEmpty)
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('No academic years configured'),
                    subtitle: Text('Create an academic year from School Setup.'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<ErpRecord>> _loadRecords(ErpEntity? entity) async {
    if (entity == null) return const <ErpRecord>[];
    try {
      return await TenantErpService()
          .watch(entity)
          .first
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      return const <ErpRecord>[];
    }
  }
}
