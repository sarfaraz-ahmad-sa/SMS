import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_bootstrap.dart';

class SupabaseStudentRecord {
  const SupabaseStudentRecord({
    required this.id,
    required this.tenantId,
    required this.campusId,
    required this.academicYearId,
    required this.admissionNo,
    required this.fullName,
    required this.status,
    required this.classId,
    required this.sectionId,
    required this.updatedAt,
    this.dateOfBirth,
    this.gender,
  });

  final String id;
  final String tenantId;
  final String campusId;
  final String academicYearId;
  final String admissionNo;
  final String fullName;
  final String status;
  final String? classId;
  final String? sectionId;
  final DateTime? updatedAt;
  final DateTime? dateOfBirth;
  final String? gender;

  factory SupabaseStudentRecord.fromRow(Map<String, dynamic> row) {
    return SupabaseStudentRecord(
      id: row['id']?.toString() ?? '',
      tenantId: row['tenant_id']?.toString() ?? '',
      campusId: row['campus_id']?.toString() ?? '',
      academicYearId: row['academic_year_id']?.toString() ?? '',
      admissionNo: row['admission_no']?.toString() ?? '',
      fullName: row['full_name']?.toString() ?? '',
      status: row['status']?.toString() ?? 'active',
      classId: _optionalText(row['class_id']),
      sectionId: _optionalText(row['section_id']),
      updatedAt: _date(row['updated_at']),
      dateOfBirth: _date(row['date_of_birth']),
      gender: _optionalText(row['gender']),
    );
  }
}

class SupabaseStudentDraft {
  const SupabaseStudentDraft({
    required this.campusId,
    required this.academicYearId,
    required this.admissionNo,
    required this.fullName,
    this.classId,
    this.sectionId,
    this.dateOfBirth,
    this.gender,
    this.status = 'active',
  });

  final String campusId;
  final String academicYearId;
  final String admissionNo;
  final String fullName;
  final String? classId;
  final String? sectionId;
  final DateTime? dateOfBirth;
  final String? gender;
  final String status;

  Map<String, dynamic> toPayload() => <String, dynamic>{
        'campus_id': campusId.trim(),
        'academic_year_id': academicYearId.trim(),
        'admission_no': admissionNo.trim(),
        'full_name': fullName.trim(),
        'class_id': _optionalText(classId),
        'section_id': _optionalText(sectionId),
        'date_of_birth': _dateOnly(dateOfBirth),
        'gender': _optionalText(gender)?.toLowerCase(),
        'status': status.trim().toLowerCase(),
      };
}

class SupabaseStudentPage {
  const SupabaseStudentPage({
    required this.records,
    required this.hasMore,
    this.nextCursor,
  });

  final List<SupabaseStudentRecord> records;
  final bool hasMore;
  final String? nextCursor;
}

class SupabaseStudentPlacement {
  const SupabaseStudentPlacement({
    required this.classId,
    required this.sectionId,
  });

  final String classId;
  final String sectionId;
}

/// Bounded, keyset-paginated student reads for one exact school scope.
class SupabaseStudentService {
  SupabaseStudentService({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  Future<SupabaseStudentPage> fetchPage({
    required String tenantId,
    required String campusId,
    required String academicYearId,
    int pageSize = 25,
    String? afterId,
    String? query,
    String? status,
  }) async {
    _requireScope('tenantId', tenantId);
    _requireScope('campusId', campusId);
    _requireScope('academicYearId', academicYearId);
    if (pageSize < 1 || pageSize > 100) {
      throw RangeError.range(pageSize, 1, 100, 'pageSize');
    }

    var request = _client
        .from('students')
        .select(
          'tenant_id,id,campus_id,academic_year_id,admission_no,full_name,'
          'date_of_birth,gender,status,class_id,section_id,updated_at',
        )
        .eq('tenant_id', tenantId)
        .eq('campus_id', campusId)
        .eq('academic_year_id', academicYearId)
        .eq('is_archived', false);
    final cursor = _optionalText(afterId);
    final search = _optionalText(query);
    final statusFilter = _optionalText(status);
    if (search != null) {
      final escaped = search
          .replaceAll('\\', '\\\\')
          .replaceAll('%', '\\%')
          .replaceAll('_', '\\_');
      request = request.ilike('search_text', '%$escaped%');
    }
    if (statusFilter != null) {
      request = request.eq('status', statusFilter.toLowerCase());
    }
    if (cursor != null) request = request.gt('id', cursor);

    final response = await request.order('id').limit(pageSize + 1);
    final rows = response
        .whereType<Map>()
        .map((Map<dynamic, dynamic> row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
    final hasMore = rows.length > pageSize;
    final visibleRows = hasMore ? rows.take(pageSize) : rows;
    final records =
        visibleRows.map(SupabaseStudentRecord.fromRow).toList(growable: false);

    return SupabaseStudentPage(
      records: records,
      hasMore: hasMore,
      nextCursor: records.isEmpty ? null : records.last.id,
    );
  }

  Future<SupabaseStudentRecord> fetchById({
    required String tenantId,
    required String campusId,
    required String academicYearId,
    required String studentId,
  }) async {
    _requireScope('tenantId', tenantId);
    _requireScope('campusId', campusId);
    _requireScope('academicYearId', academicYearId);
    _requireScope('studentId', studentId);
    final row = await _client
        .from('students')
        .select(
          'tenant_id,id,campus_id,academic_year_id,admission_no,full_name,'
          'date_of_birth,gender,status,class_id,section_id,updated_at',
        )
        .eq('tenant_id', tenantId)
        .eq('campus_id', campusId)
        .eq('academic_year_id', academicYearId)
        .eq('id', studentId)
        .eq('is_archived', false)
        .limit(1)
        .maybeSingle();
    if (row == null) throw StateError('Student was not found.');
    return SupabaseStudentRecord.fromRow(row);
  }

  Future<SupabaseStudentPlacement> resolvePlacement({
    required String tenantId,
    required String campusId,
    required String academicYearId,
    required String className,
    required String sectionName,
  }) async {
    _requireScope('tenantId', tenantId);
    _requireScope('campusId', campusId);
    _requireScope('academicYearId', academicYearId);
    _requireScope('className', className);
    _requireScope('sectionName', sectionName);

    final classRow = await _client
        .from('classes')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('campus_id', campusId)
        .eq('academic_year_id', academicYearId)
        .eq('name', className.trim())
        .eq('is_archived', false)
        .limit(1)
        .maybeSingle();
    final classId = _optionalText(classRow?['id']);
    if (classId == null) {
      throw StateError('Selected class is not configured for this school.');
    }

    final sectionRow = await _client
        .from('sections')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('campus_id', campusId)
        .eq('academic_year_id', academicYearId)
        .eq('class_id', classId)
        .eq('name', sectionName.trim())
        .eq('is_archived', false)
        .limit(1)
        .maybeSingle();
    final sectionId = _optionalText(sectionRow?['id']);
    if (sectionId == null) {
      throw StateError('Selected section is not configured for this class.');
    }
    return SupabaseStudentPlacement(classId: classId, sectionId: sectionId);
  }

  /// Creates a student through the server-side transaction. Direct table
  /// INSERT privileges are intentionally revoked from authenticated clients.
  Future<SupabaseStudentRecord> create({
    required String tenantId,
    required SupabaseStudentDraft student,
  }) async {
    _requireScope('tenantId', tenantId);
    _validateDraft(student);
    final response = await _client.rpc(
      'create_student',
      params: <String, dynamic>{
        'p_tenant_id': tenantId.trim(),
        'p_payload': student.toPayload(),
      },
    );
    return SupabaseStudentRecord.fromRow(_singleRow(response));
  }

  /// Updates the complete editable student record with optimistic concurrency.
  /// A stale [student.updatedAt] is rejected by PostgreSQL instead of silently
  /// overwriting a newer change from another staff member.
  Future<SupabaseStudentRecord> update({
    required SupabaseStudentRecord student,
    required SupabaseStudentDraft changes,
  }) async {
    _requireScope('tenantId', student.tenantId);
    _requireScope('studentId', student.id);
    _validateDraft(changes);
    final expectedUpdatedAt = _requireVersion(student);
    final response = await _client.rpc(
      'update_student',
      params: <String, dynamic>{
        'p_tenant_id': student.tenantId,
        'p_student_id': student.id,
        'p_expected_updated_at': expectedUpdatedAt.toIso8601String(),
        'p_payload': changes.toPayload(),
      },
    );
    return SupabaseStudentRecord.fromRow(_singleRow(response));
  }

  /// Soft-deletes a student through the backend so dependent history remains
  /// intact and the automatic audit/dashboard triggers run in one transaction.
  Future<SupabaseStudentRecord> archive(
    SupabaseStudentRecord student,
  ) async {
    _requireScope('tenantId', student.tenantId);
    _requireScope('studentId', student.id);
    final expectedUpdatedAt = _requireVersion(student);
    final response = await _client.rpc(
      'archive_student',
      params: <String, dynamic>{
        'p_tenant_id': student.tenantId,
        'p_student_id': student.id,
        'p_expected_updated_at': expectedUpdatedAt.toIso8601String(),
      },
    );
    return SupabaseStudentRecord.fromRow(_singleRow(response));
  }

  void _validateDraft(SupabaseStudentDraft student) {
    _requireScope('campusId', student.campusId);
    _requireScope('academicYearId', student.academicYearId);
    final admissionLength = student.admissionNo.trim().length;
    if (admissionLength < 1 || admissionLength > 50) {
      throw ArgumentError.value(
        student.admissionNo,
        'admissionNo',
        'Admission number must contain 1 to 50 characters.',
      );
    }
    final nameLength = student.fullName.trim().length;
    if (nameLength < 2 || nameLength > 160) {
      throw ArgumentError.value(
        student.fullName,
        'fullName',
        'Student name must contain 2 to 160 characters.',
      );
    }
    if (student.sectionId != null && student.classId == null) {
      throw ArgumentError.value(
        student.sectionId,
        'sectionId',
        'A section requires a class.',
      );
    }
  }

  DateTime _requireVersion(SupabaseStudentRecord student) {
    final version = student.updatedAt;
    if (version == null) {
      throw StateError('Student must be reloaded before it can be changed.');
    }
    return version;
  }

  void _requireScope(String name, String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'Scope cannot be empty.');
    }
  }
}

Map<String, dynamic> _singleRow(dynamic response) {
  if (response is Map) return Map<String, dynamic>.from(response);
  if (response is List && response.length == 1 && response.first is Map) {
    return Map<String, dynamic>.from(response.first as Map);
  }
  throw const FormatException('Student mutation returned an invalid row.');
}

String? _optionalText(dynamic value) {
  final normalized = value?.toString().trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

DateTime? _date(dynamic value) {
  if (value is DateTime) return value;
  return value == null ? null : DateTime.tryParse(value.toString());
}

String? _dateOnly(DateTime? value) {
  if (value == null) return null;
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
