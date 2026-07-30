import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/services/UserModel.dart';
import 'package:school_management/services/models/user_role.dart';

void main() {
  test('legacy single role is parsed into roles list', () {
    final user = UserModel.fromMap(
      'uid-1',
      <String, dynamic>{
        'tenantId': 'school-1',
        'role': 'accountant',
      },
    );

    expect(user.roles, contains(UserRole.accountant));
    expect(user.tenantId, 'school-1');
  });

  test('multi-role membership removes duplicate roles', () {
    final user = UserModel.fromMap(
      'uid-2',
      <String, dynamic>{
        'tenantId': 'school-1',
        'roles': <String>['teacher', 'classTeacher', 'teacher'],
      },
    );

    expect(user.roles.length, 2);
    expect(user.roles, containsAll(<UserRole>[
      UserRole.teacher,
      UserRole.classTeacher,
    ]));
  });

  test('secure account and linked ERP identity fields are parsed', () {
    final user = UserModel.fromMap(
      'uid-3',
      <String, dynamic>{
        'tenantId': 'school-1',
        'roles': <String>['student'],
        'mustChangePassword': true,
        'linkedRecordType': 'student',
        'linkedRecordId': 'student-doc-1',
        'themeMode': 'dark',
      },
    );

    expect(user.mustChangePassword, isTrue);
    expect(user.linkedRecordType, 'student');
    expect(user.linkedRecordId, 'student-doc-1');
    expect(user.themeMode, 'dark');
  });

  test('unsupported saved theme falls back to system mode', () {
    final user = UserModel.fromMap(
      'uid-4',
      <String, dynamic>{
        'tenantId': 'school-1',
        'roles': <String>['teacher'],
        'themeMode': 'unknown',
      },
    );

    expect(user.themeMode, 'system');
  });

}
