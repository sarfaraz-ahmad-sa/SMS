import 'app_permission.dart';

enum UserRole {
  superAdmin,
  schoolOwner,
  principal,
  vicePrincipal,
  adminStaff,
  accountant,
  teacher,
  classTeacher,
  student,
  parent,
  librarian,
  hrManager,
  receptionist,
  transportManager,
  hostelManager,
  itAdmin,
}

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.schoolOwner:
        return 'School Owner';
      case UserRole.principal:
        return 'Principal';
      case UserRole.vicePrincipal:
        return 'Vice Principal';
      case UserRole.adminStaff:
        return 'Admin Staff';
      case UserRole.accountant:
        return 'Accountant';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.classTeacher:
        return 'Class Teacher';
      case UserRole.student:
        return 'Student';
      case UserRole.parent:
        return 'Parent / Guardian';
      case UserRole.librarian:
        return 'Librarian';
      case UserRole.hrManager:
        return 'HR Manager';
      case UserRole.receptionist:
        return 'Receptionist';
      case UserRole.transportManager:
        return 'Transport Manager';
      case UserRole.hostelManager:
        return 'Hostel Manager';
      case UserRole.itAdmin:
        return 'IT Administrator';
    }
  }

  String get value => name;

  /// Default module visibility. Explicit membership permissions can extend
  /// this list and deniedPermissions can remove individual permissions.
  Set<String> get defaultPermissions {
    const common = <String>{
      AppPermission.profileView,
      AppPermission.notificationsView,
      AppPermission.timetableView,
      AppPermission.eventsView,
    };

    switch (this) {
      case UserRole.superAdmin:
      case UserRole.schoolOwner:
      case UserRole.principal:
        return const <String>{AppPermission.wildcard};
      case UserRole.vicePrincipal:
        return <String>{
          ...common,
          AppPermission.attendanceView,
          AppPermission.attendanceManage,
          AppPermission.examsView,
          AppPermission.examsManage,
          AppPermission.examResultsPublish,
          AppPermission.admissionsView,
          AppPermission.admissionsManage,
          AppPermission.studentsView,
          AppPermission.studentsCreate,
          AppPermission.studentsUpdate,
          AppPermission.studentsPromote,
          AppPermission.teachersView,
          AppPermission.teachersManage,
          AppPermission.activitiesView,
          AppPermission.activitiesManage,
          AppPermission.eventsManage,
          AppPermission.reportsView,
          AppPermission.leaveView,
          AppPermission.leaveManage,
        };
      case UserRole.adminStaff:
        return <String>{
          ...common,
          AppPermission.admissionsView,
          AppPermission.admissionsManage,
          AppPermission.studentsView,
          AppPermission.studentsCreate,
          AppPermission.studentsUpdate,
          AppPermission.attendanceView,
          AppPermission.feesView,
          AppPermission.transportView,
          AppPermission.eventsManage,
          AppPermission.reportsView,
        };
      case UserRole.accountant:
        return <String>{
          ...common,
          AppPermission.feesView,
          AppPermission.feesManage,
          AppPermission.feesCollect,
          AppPermission.accountingView,
          AppPermission.accountingManage,
          AppPermission.reportsView,
        };
      case UserRole.teacher:
        return <String>{
          ...common,
          AppPermission.attendanceView,
          AppPermission.attendanceMark,
          AppPermission.examsView,
          AppPermission.examsManage,
          AppPermission.studentsView,
          AppPermission.leaveView,
          AppPermission.leaveApply,
          AppPermission.activitiesView,
          AppPermission.eventsManage,
        };
      case UserRole.classTeacher:
        return <String>{
          ...common,
          AppPermission.attendanceView,
          AppPermission.attendanceMark,
          AppPermission.examsView,
          AppPermission.examsManage,
          AppPermission.studentsView,
          AppPermission.studentsUpdate,
          AppPermission.leaveView,
          AppPermission.leaveApply,
          AppPermission.activitiesView,
          AppPermission.eventsManage,
          AppPermission.reportsView,
        };
      case UserRole.student:
        return <String>{
          ...common,
          AppPermission.attendanceView,
          AppPermission.examsView,
          AppPermission.feesView,
          AppPermission.libraryView,
          AppPermission.transportView,
          AppPermission.leaveView,
          AppPermission.leaveApply,
          AppPermission.activitiesView,
        };
      case UserRole.parent:
        return <String>{
          ...common,
          AppPermission.attendanceView,
          AppPermission.examsView,
          AppPermission.feesView,
          AppPermission.transportView,
          AppPermission.leaveView,
          AppPermission.leaveApply,
          AppPermission.activitiesView,
        };
      case UserRole.librarian:
        return <String>{
          ...common,
          AppPermission.libraryView,
          AppPermission.libraryManage,
          AppPermission.studentsView,
          AppPermission.reportsView,
        };
      case UserRole.hrManager:
        return <String>{
          ...common,
          AppPermission.hrView,
          AppPermission.hrManage,
          AppPermission.payrollManage,
          AppPermission.teachersView,
          AppPermission.teachersManage,
          AppPermission.leaveView,
          AppPermission.leaveManage,
          AppPermission.reportsView,
        };
      case UserRole.receptionist:
        return <String>{
          ...common,
          AppPermission.admissionsView,
          AppPermission.admissionsManage,
          AppPermission.studentsView,
          AppPermission.studentsCreate,
          AppPermission.transportView,
        };
      case UserRole.transportManager:
        return <String>{
          ...common,
          AppPermission.transportView,
          AppPermission.transportManage,
          AppPermission.studentsView,
          AppPermission.reportsView,
        };
      case UserRole.hostelManager:
        return <String>{
          ...common,
          AppPermission.hostelView,
          AppPermission.hostelManage,
          AppPermission.studentsView,
          AppPermission.feesView,
          AppPermission.reportsView,
        };
      case UserRole.itAdmin:
        return <String>{
          ...common,
          AppPermission.settingsView,
          AppPermission.usersManage,
          AppPermission.tenantManage,
          AppPermission.reportsView,
        };
    }
  }
}

UserRole? tryUserRoleFromString(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;

  for (final role in UserRole.values) {
    if (role.value == normalized) return role;
  }
  return null;
}

UserRole userRoleFromString(String? value) {
  return tryUserRoleFromString(value) ?? UserRole.student;
}
