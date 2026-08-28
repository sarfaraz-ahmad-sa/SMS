import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/core/erp/erp_access_policy.dart';
import 'package:school_management/core/erp/erp_catalog.dart';
import 'package:school_management/services/UserModel.dart';
import 'package:school_management/services/models/user_role.dart';

void main() {
  const student = UserModel(
    uid: 'student-1',
    tenantId: 'school-1',
    roles: <UserRole>[UserRole.student],
  );
  const parent = UserModel(
    uid: 'parent-1',
    tenantId: 'school-1',
    roles: <UserRole>[UserRole.parent],
  );
  const owner = UserModel(
    uid: 'owner-1',
    tenantId: 'school-1',
    roles: <UserRole>[UserRole.schoolOwner],
  );

  test('student sees only allowed portal records', () {
    final students = ErpCatalog.entityByCollection('students')!;
    final assignments = ErpCatalog.entityByCollection('assignments')!;
    final journals = ErpCatalog.entityByCollection('journal_entries')!;

    expect(
      ErpAccessPolicy.canViewEntity(
        students,
        student,
        student.hasPermission,
      ),
      isTrue,
    );
    expect(
      ErpAccessPolicy.canViewEntity(
        assignments,
        student,
        student.hasPermission,
      ),
      isTrue,
    );
    expect(
      ErpAccessPolicy.canViewEntity(
        journals,
        student,
        student.hasPermission,
      ),
      isFalse,
    );
  });

  test('student and parent can create but cannot edit self-service requests', () {
    final leave = ErpCatalog.entityByCollection('student_leave_requests')!;
    final certificate = ErpCatalog.entityByCollection('certificate_requests')!;

    expect(
      ErpAccessPolicy.canCreate(leave, student, student.hasPermission),
      isTrue,
    );
    expect(
      ErpAccessPolicy.canEdit(leave, student.hasPermission),
      isFalse,
    );
    expect(
      ErpAccessPolicy.canCreate(certificate, parent, parent.hasPermission),
      isTrue,
    );
    expect(
      ErpAccessPolicy.canEdit(certificate, parent.hasPermission),
      isFalse,
    );
  });

  test('school owner has access to every catalog workflow', () {
    final inaccessible = ErpCatalog.modules
        .expand((module) => module.entities)
        .where(
          (entity) => !ErpAccessPolicy.canViewEntity(
            entity,
            owner,
            owner.hasPermission,
          ),
        )
        .toList();

    expect(inaccessible, isEmpty);
  });
  test('teacher can submit but not approve own leave request', () {
    const teacher = UserModel(
      uid: 'teacher-1',
      tenantId: 'school-1',
      roles: <UserRole>[UserRole.teacher],
    );
    final leave = ErpCatalog.entityByCollection('leave_requests')!;

    expect(
      ErpAccessPolicy.canCreate(leave, teacher, teacher.hasPermission),
      isTrue,
    );
    expect(
      ErpAccessPolicy.canEdit(leave, teacher.hasPermission),
      isFalse,
    );
  });

  test('admin staff sees operational data without finance elevation', () {
    const admin = UserModel(
      uid: 'admin-1',
      tenantId: 'school-1',
      roles: <UserRole>[UserRole.adminStaff],
    );
    final students = ErpCatalog.entityByCollection('students')!;
    final diary = ErpCatalog.entityByCollection('daily_diary')!;
    final journals = ErpCatalog.entityByCollection('journal_entries')!;

    expect(
      ErpAccessPolicy.canViewEntity(students, admin, admin.hasPermission),
      isTrue,
    );
    expect(
      ErpAccessPolicy.canViewEntity(diary, admin, admin.hasPermission),
      isTrue,
    );
    expect(
      ErpAccessPolicy.canViewEntity(journals, admin, admin.hasPermission),
      isFalse,
    );
  });

}
