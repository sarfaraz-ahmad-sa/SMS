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
}
