import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/services/UserModel.dart';
import 'package:school_management/services/models/app_permission.dart';
import 'package:school_management/services/models/user_role.dart';

void main() {
  group('User permissions', () {
    test('school owner receives wildcard access', () {
      const user = UserModel(
        uid: 'owner',
        tenantId: 'school-1',
        roles: <UserRole>[UserRole.schoolOwner],
      );

      expect(user.hasPermission(AppPermission.accountingManage), isTrue);
      expect(user.hasPermission(AppPermission.studentsCreate), isTrue);
    });

    test('student does not receive management access', () {
      const user = UserModel(
        uid: 'student',
        tenantId: 'school-1',
        roles: <UserRole>[UserRole.student],
      );

      expect(user.hasPermission(AppPermission.examsView), isTrue);
      expect(user.hasPermission(AppPermission.studentsCreate), isFalse);
      expect(user.hasPermission(AppPermission.accountingManage), isFalse);
    });

    test('email student membership loads the student portal role', () {
      final user = UserModel.fromMap(
        'student-auth-uid',
        <String, dynamic>{
          'email': 'student@school.test',
          'tenantId': 'school-1',
          'roles': <String>['student'],
          'permissions': <String>[
            AppPermission.dashboardView,
            AppPermission.examsView,
          ],
          'isActive': true,
        },
      );

      expect(user.email, 'student@school.test');
      expect(user.hasRole(UserRole.student), isTrue);
      expect(user.hasPermission(AppPermission.examsView), isTrue);
      expect(user.hasPermission(AppPermission.studentsManage), isFalse);
    });

    test('admin staff can create role-based school accounts', () {
      const user = UserModel(
        uid: 'admin',
        tenantId: 'school-1',
        roles: <UserRole>[UserRole.adminStaff],
      );

      expect(user.hasPermission(AppPermission.usersManage), isTrue);
    });

    test('explicit permission extends a role', () {
      const user = UserModel(
        uid: 'teacher',
        tenantId: 'school-1',
        roles: <UserRole>[UserRole.teacher],
        permissions: <String>{AppPermission.reportsView},
      );

      expect(user.hasPermission(AppPermission.reportsView), isTrue);
    });

    test('denied permission removes a non-wildcard role permission', () {
      const user = UserModel(
        uid: 'teacher',
        tenantId: 'school-1',
        roles: <UserRole>[UserRole.teacher],
        deniedPermissions: <String>{AppPermission.attendanceMark},
      );

      expect(user.hasPermission(AppPermission.attendanceView), isTrue);
      expect(user.hasPermission(AppPermission.attendanceMark), isFalse);
    });
  });
}
