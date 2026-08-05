import 'package:flutter/material.dart';

import '../../Widgets/jinn_ui.dart';
import '../../Widgets/saas_scaffold.dart';
import '../../config/backend_config.dart';
import '../../services/models/app_permission.dart';
import '../../services/models/student.dart';
import '../../services/session_state.dart';
import '../../services/student_service.dart';
import '../../services/supabase_student_service.dart';
import '../../theme/app_theme.dart';
import 'AddStudent.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final StudentService _service = StudentService();
  final SupabaseStudentService _supabaseService = SupabaseStudentService();
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  SupabaseStudentPage? _supabasePage;
  bool _supabaseLoading = false;
  String? _supabaseError;

  @override
  void initState() {
    super.initState();
    if (BackendConfig.isSupabasePrimary) _loadSupabase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSupabase({bool more = false}) async {
    if (_supabaseLoading) return;
    final state = SessionState.instance;
    final tenantId = state.tenant?.id;
    final campusId = state.activeCampusId;
    final academicYearId = state.activeAcademicYearId;
    if (tenantId == null || campusId == null || academicYearId == null) {
      setState(() => _supabaseError = 'School scope is incomplete.');
      return;
    }

    setState(() {
      _supabaseLoading = true;
      _supabaseError = null;
    });

    try {
      final previous = more ? _supabasePage : null;
      final page = await _supabaseService.fetchPage(
        tenantId: tenantId,
        campusId: campusId,
        academicYearId: academicYearId,
        pageSize: 25,
        afterId: previous?.nextCursor,
      );
      if (!mounted) return;
      setState(() {
        _supabasePage = previous == null
            ? page
            : SupabaseStudentPage(
                records: <SupabaseStudentRecord>[...previous.records, ...page.records],
                hasMore: page.hasMore,
                nextCursor: page.nextCursor,
              );
      });
    } catch (error) {
      if (mounted) setState(() => _supabaseError = error.toString());
    } finally {
      if (mounted) setState(() => _supabaseLoading = false);
    }
  }

  Future<void> _openAddStudent() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const AddStudentScreen()),
    );
    if (mounted && BackendConfig.isSupabasePrimary) await _loadSupabase();
  }

  Future<void> _confirmArchive(Student student) async {
    final confirmed = await _confirmArchiveDialog(student.fullName);
    if (confirmed != true || student.id == null) return;
    try {
      await _service.archiveStudent(student.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${student.fullName} archived.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Archive failed: $error')));
    }
  }

  Future<void> _confirmSupabaseArchive(SupabaseStudentRecord student) async {
    final confirmed = await _confirmArchiveDialog(student.fullName);
    if (confirmed != true) return;
    try {
      await _supabaseService.archive(student);
      await _loadSupabase();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${student.fullName} archived.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Archive failed: $error')));
    }
  }

  Future<bool?> _confirmArchiveDialog(String name) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        icon: const Icon(Icons.archive_outlined, color: AppColors.warning),
        title: const Text('Archive student?'),
        content: Text('$name will be removed from active lists while historical records remain available.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Archive')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = SessionState.instance;
    final canCreate = state.hasPermission(AppPermission.studentsCreate);
    final canArchive = state.hasPermission(AppPermission.studentsArchive);

    return SaasScaffold(
      title: 'Students',
      activeRoute: '/modules',
      activeModuleId: 'students',
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openAddStudent,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Student'),
            )
          : null,
      actions: <Widget>[
        if (canCreate)
          IconButton(
            tooltip: 'Add student',
            onPressed: _openAddStudent,
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
      ],
      body: BackendConfig.isSupabasePrimary
          ? _buildSupabase(canCreate: canCreate, canArchive: canArchive)
          : _buildFirebase(canCreate: canCreate, canArchive: canArchive),
    );
  }

  Widget _buildFirebase({required bool canCreate, required bool canArchive}) {
    return StreamBuilder<List<Student>>(
      stream: _service.streamStudents(),
      builder: (BuildContext context, AsyncSnapshot<List<Student>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _fullPageError(snapshot.error.toString());

        final normalized = _query.trim().toLowerCase();
        final records = (snapshot.data ?? <Student>[])
            .where((Student student) =>
                normalized.isEmpty ||
                student.fullName.toLowerCase().contains(normalized) ||
                student.idCardNumber.toLowerCase().contains(normalized) ||
                student.className.toLowerCase().contains(normalized))
            .toList(growable: false);

        return _StudentWorkspace(
          total: snapshot.data?.length ?? 0,
          shown: records.length,
          queryController: _searchController,
          onQueryChanged: (String value) => setState(() => _query = value),
          empty: records.isEmpty,
          canCreate: canCreate,
          onCreate: _openAddStudent,
          listBuilder: () => ListView.separated(
            padding: const EdgeInsets.only(bottom: 92),
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 9),
            itemBuilder: (BuildContext context, int index) {
              final student = records[index];
              return _StudentRecordCard(
                name: student.fullName,
                identifier: student.idCardNumber,
                classLabel: 'Class ${student.className}-${student.section}',
                onArchive: canArchive ? () => _confirmArchive(student) : null,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSupabase({required bool canCreate, required bool canArchive}) {
    if (_supabaseError != null) return _fullPageError(_supabaseError!);
    if (_supabaseLoading && _supabasePage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final normalized = _query.trim().toLowerCase();
    final all = _supabasePage?.records ?? <SupabaseStudentRecord>[];
    final records = all
        .where((SupabaseStudentRecord student) =>
            normalized.isEmpty ||
            student.fullName.toLowerCase().contains(normalized) ||
            student.admissionNo.toLowerCase().contains(normalized))
        .toList(growable: false);

    return _StudentWorkspace(
      total: all.length,
      shown: records.length,
      queryController: _searchController,
      onQueryChanged: (String value) => setState(() => _query = value),
      empty: records.isEmpty,
      canCreate: canCreate,
      onCreate: _openAddStudent,
      onRefresh: _loadSupabase,
      listBuilder: () => RefreshIndicator(
        onRefresh: _loadSupabase,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 92),
          itemCount: records.length + (_supabasePage?.hasMore == true ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 9),
          itemBuilder: (BuildContext context, int index) {
            if (index == records.length) {
              return Center(
                child: OutlinedButton.icon(
                  onPressed: _supabaseLoading ? null : () => _loadSupabase(more: true),
                  icon: _supabaseLoading
                      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.expand_more_rounded, size: 18),
                  label: Text(_supabaseLoading ? 'Loading…' : 'Load more'),
                ),
              );
            }
            final student = records[index];
            return _StudentRecordCard(
              name: student.fullName,
              identifier: student.admissionNo,
              classLabel: 'Admission ${student.admissionNo}',
              onArchive: canArchive ? () => _confirmSupabaseArchive(student) : null,
            );
          },
        ),
      ),
    );
  }

  Widget _fullPageError(String message) {
    return JinnPage(
      maxWidth: 700,
      child: JinnEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load students',
        message: message,
        action: OutlinedButton.icon(
          onPressed: BackendConfig.isSupabasePrimary ? _loadSupabase : null,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try Again'),
        ),
      ),
    );
  }
}

class _StudentWorkspace extends StatelessWidget {
  final int total;
  final int shown;
  final TextEditingController queryController;
  final ValueChanged<String> onQueryChanged;
  final bool empty;
  final bool canCreate;
  final VoidCallback onCreate;
  final Future<void> Function()? onRefresh;
  final Widget Function() listBuilder;

  const _StudentWorkspace({
    required this.total,
    required this.shown,
    required this.queryController,
    required this.onQueryChanged,
    required this.empty,
    required this.canCreate,
    required this.onCreate,
    required this.listBuilder,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return JinnPage(
      maxWidth: 1260,
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final compact = constraints.maxWidth < 680;
              final title = JinnSectionHeader(
                title: 'Student Directory',
                subtitle: '$shown of $total active student records',
                trailing: compact || !canCreate
                    ? null
                    : FilledButton.icon(
                        onPressed: onCreate,
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        label: const Text('Add Student'),
                      ),
              );
              return title;
            },
          ),
          const SizedBox(height: 14),
          JinnCard(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: JinnSearchField(
                    controller: queryController,
                    hintText: 'Search by name, ID, admission no. or class...',
                    onChanged: onQueryChanged,
                  ),
                ),
                if (onRefresh != null) ...<Widget>[
                  const SizedBox(width: 9),
                  IconButton.filledTonal(
                    tooltip: 'Refresh',
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: empty
                ? JinnEmptyState(
                    icon: Icons.group_off_rounded,
                    title: 'No students found',
                    message: canCreate
                        ? 'Change the search or add the first matching student.'
                        : 'No active student records are available.',
                    action: canCreate
                        ? FilledButton.icon(
                            onPressed: onCreate,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Student'),
                          )
                        : null,
                  )
                : listBuilder(),
          ),
        ],
      ),
    );
  }
}

class _StudentRecordCard extends StatelessWidget {
  final String name;
  final String identifier;
  final String classLabel;
  final VoidCallback? onArchive;

  const _StudentRecordCard({
    required this.name,
    required this.identifier,
    required this.classLabel,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    return JinnCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.pastelGold,
            child: Text(initial, style: const TextStyle(color: AppColors.navigation, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 3),
                Text('$classLabel  ·  $identifier', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const JinnStatusPill(label: 'Active', color: AppColors.success),
          if (onArchive != null) ...<Widget>[
            const SizedBox(width: 5),
            IconButton(
              tooltip: 'Archive student',
              onPressed: onArchive,
              icon: const Icon(Icons.archive_outlined, color: AppColors.warning, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}
