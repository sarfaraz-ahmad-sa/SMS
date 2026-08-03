import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/services/supabase_student_service.dart';

void main() {
  test('maps PostgreSQL student fields without demo fallbacks', () {
    final student = SupabaseStudentRecord.fromRow(<String, dynamic>{
      'id': 'student-1',
      'tenant_id': 'school-1',
      'campus_id': 'campus-1',
      'academic_year_id': 'year-1',
      'admission_no': 'A-001',
      'full_name': 'Test Student',
      'date_of_birth': '2015-03-12',
      'gender': 'male',
      'status': 'active',
      'class_id': 'class-1',
      'section_id': 'section-a',
      'updated_at': '2026-08-03T12:00:00Z',
    });

    expect(student.id, 'student-1');
    expect(student.tenantId, 'school-1');
    expect(student.admissionNo, 'A-001');
    expect(student.fullName, 'Test Student');
    expect(student.dateOfBirth, DateTime(2015, 3, 12));
    expect(student.classId, 'class-1');
    expect(student.sectionId, 'section-a');
    expect(student.updatedAt, DateTime.utc(2026, 8, 3, 12));
  });

  test('nullable relational fields remain null', () {
    final student = SupabaseStudentRecord.fromRow(<String, dynamic>{
      'id': 'student-2',
      'admission_no': 'A-002',
      'full_name': 'Second Student',
      'status': 'active',
    });

    expect(student.classId, isNull);
    expect(student.sectionId, isNull);
    expect(student.gender, isNull);
  });

  test('student draft emits only backend-approved fields', () {
    final payload = SupabaseStudentDraft(
      campusId: ' campus-1 ',
      academicYearId: 'year-1',
      admissionNo: ' A-003 ',
      fullName: ' Third Student ',
      dateOfBirth: DateTime(2014, 9, 7),
      gender: 'Female',
    ).toPayload();

    expect(payload['campus_id'], 'campus-1');
    expect(payload['admission_no'], 'A-003');
    expect(payload['full_name'], 'Third Student');
    expect(payload['date_of_birth'], '2014-09-07');
    expect(payload['gender'], 'female');
    expect(payload.keys, hasLength(9));
  });
}
