import 'package:flutter/material.dart';

import '../../services/models/app_permission.dart';
import '../../services/models/student.dart';
import '../../services/session_state.dart';
import '../../services/student_service.dart';
import '../../services/supabase_student_service.dart';
import '../../config/backend_config.dart';
import '../../theme/app_theme.dart';
import 'AddStudent.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({Key? key}) : super(key: key);

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final StudentService _service = StudentService();
  final SupabaseStudentService _supabaseService = SupabaseStudentService();
  String _query = '';
  SupabaseStudentPage? _supabasePage;
  bool _supabaseLoading = false;
  String? _supabaseError;

  @override
  void initState() {
    super.initState();
    if (BackendConfig.isSupabasePrimary) _loadSupabase();
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
                records: <SupabaseStudentRecord>[
                  ...previous.records,
                  ...page.records,
                ],
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

  Future<void> _confirmArchive(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Archive student?'),
        content: Text(
          '${student.fullName} will be removed from active lists, while history remains available.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true || student.id == null) return;

    try {
      await _service.archiveStudent(student.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${student.fullName} archived')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Archive failed: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _confirmSupabaseArchive(
    SupabaseStudentRecord student,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Archive student?'),
        content: Text(
          '${student.fullName} will be removed from active lists, while history remains available.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _supabaseService.archive(student);
      await _loadSupabase();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${student.fullName} archived')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Archive failed: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCreate =
        SessionState.instance.hasPermission(AppPermission.studentsCreate);
    final canArchive =
        SessionState.instance.hasPermission(AppPermission.studentsArchive);

    if (BackendConfig.isSupabasePrimary) {
      return _buildSupabase(canCreate: canCreate, canArchive: canArchive);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Student Management')),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const AddStudentScreen(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Student'),
            )
          : null,
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (String value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search by name or ID card',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Student>>(
              stream: _service.streamStudents(),
              builder: (
                BuildContext context,
                AsyncSnapshot<List<Student>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _error(snapshot.error.toString());
                }

                final normalizedQuery = _query.trim().toLowerCase();
                final list = (snapshot.data ?? <Student>[])
                    .where(
                      (Student student) =>
                          normalizedQuery.isEmpty ||
                          student.fullName
                              .toLowerCase()
                              .contains(normalizedQuery) ||
                          student.idCardNumber
                              .toLowerCase()
                              .contains(normalizedQuery),
                    )
                    .toList();

                if (list.isEmpty) return _empty(canCreate: canCreate);

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int index) {
                    final student = list[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            student.firstName.isNotEmpty
                                ? student.firstName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          student.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Class ${student.className}-${student.section} · ${student.idCardNumber}',
                        ),
                        trailing: canArchive
                            ? IconButton(
                                tooltip: 'Archive student',
                                icon: const Icon(
                                  Icons.archive_outlined,
                                  color: AppColors.warning,
                                ),
                                onPressed: () => _confirmArchive(student),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupabase({
    required bool canCreate,
    required bool canArchive,
  }) {
    final normalizedQuery = _query.trim().toLowerCase();
    final records = (_supabasePage?.records ?? <SupabaseStudentRecord>[])
        .where(
          (student) =>
              normalizedQuery.isEmpty ||
              student.fullName.toLowerCase().contains(normalizedQuery) ||
              student.admissionNo.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Student Management')),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AddStudentScreen(),
                  ),
                );
                if (mounted) await _loadSupabase();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Student'),
            )
          : null,
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search by name or admission number',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _supabaseError != null
                ? _error(_supabaseError!)
                : _supabaseLoading && _supabasePage == null
                    ? const Center(child: CircularProgressIndicator())
                    : records.isEmpty
                        ? _empty(canCreate: canCreate)
                        : RefreshIndicator(
                            onRefresh: _loadSupabase,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                              itemCount: records.length +
                                  (_supabasePage?.hasMore == true ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                if (index == records.length) {
                                  return Center(
                                    child: TextButton(
                                      onPressed: _supabaseLoading
                                          ? null
                                          : () => _loadSupabase(more: true),
                                      child: Text(_supabaseLoading
                                          ? 'Loading…'
                                          : 'Load more'),
                                    ),
                                  );
                                }
                                final student = records[index];
                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text(student.fullName.isEmpty
                                          ? '?'
                                          : student.fullName[0].toUpperCase()),
                                    ),
                                    title: Text(
                                      student.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Admission ${student.admissionNo}',
                                    ),
                                    trailing: canArchive
                                        ? IconButton(
                                            tooltip: 'Archive student',
                                            icon: const Icon(
                                              Icons.archive_outlined,
                                              color: AppColors.warning,
                                            ),
                                            onPressed: () =>
                                                _confirmSupabaseArchive(
                                                    student),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _empty({required bool canCreate}) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.group_off_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text('No students found'),
            const SizedBox(height: 4),
            Text(
              canCreate
                  ? 'Tap "Add Student" to create the first record.'
                  : 'No active student records are available.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );

  Widget _error(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.cloud_off, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              const Text(
                'Could not load students',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
}
