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

  bool get isLeadership => <UserRole>{
        UserRole.superAdmin,
        UserRole.schoolOwner,
        UserRole.principal,
        UserRole.vicePrincipal,
      }.contains(this);

  bool get isLearner => this == UserRole.student;
  bool get isGuardian => this == UserRole.parent;
  bool get isStaff => !isLearner && !isGuardian;

  Set<String> get defaultPermissions {
    const common = <String>{
      AppPermission.dashboardView,
      AppPermission.profileView,
      AppPermission.notificationsView,
      AppPermission.timetableView,
      AppPermission.communicationView,
      AppPermission.eventsView,
    };

    const leadership = <String>{
      AppPermission.wildcard,
    };

    switch (this) {
      case UserRole.superAdmin:
      case UserRole.schoolOwner:
      case UserRole.principal:
      case UserRole.vicePrincipal:
        return leadership;

      case UserRole.adminStaff:
        return <String>{
          ...common,
          AppPermission.schoolSetupView,
          AppPermission.schoolSetupManage,
          AppPermission.admissionsView,
          AppPermission.admissionsManage,
          AppPermission.studentsView,
          AppPermission.studentsCreate,
          AppPermission.studentsUpdate,
          AppPermission.studentsManage,
          AppPermission.parentsView,
          AppPermission.parentsManage,
          AppPermission.teachersView,
          AppPermission.employeesView,
          AppPermission.attendanceView,
          AppPermission.attendanceManage,
          AppPermission.academicsView,
          AppPermission.examsView,
          AppPermission.feesView,
          AppPermission.libraryView,
          AppPermission.transportView,
          AppPermission.hostelView,
          AppPermission.inventoryView,
          AppPermission.communicationManage,
          AppPermission.eventsManage,
          AppPermission.documentsView,
          AppPermission.documentsManage,
          AppPermission.welfareView,
          AppPermission.welfareManage,
          AppPermission.complianceView,
          AppPermission.reportsView,
          AppPermission.helpdeskView,
          AppPermission.helpdeskManage,
          AppPermission.settingsView,
          AppPermission.usersManage,
        };

      case UserRole.accountant:
        return <String>{
          ...common,
          AppPermission.studentsView,
          AppPermission.parentsView,
          AppPermission.feesView,
          AppPermission.feesManage,
          AppPermission.feesCollect,
          AppPermission.feesRefund,
          AppPermission.accountingView,
          AppPermission.accountingManage,
          AppPermission.payrollManage,
          AppPermission.inventoryView,
          AppPermission.reportsView,
          AppPermission.documentsView,
        };

      case UserRole.teacher:
        return <String>{
          ...common,
          AppPermission.studentsView,
          AppPermission.attendanceView,
          AppPermission.attendanceMark,
          AppPermission.academicsView,
          AppPermission.academicsManage,
          AppPermission.examsView,
          AppPermission.examsMarksEnter,
          AppPermission.activitiesView,
          AppPermission.activitiesManage,
          AppPermission.leaveView,
          AppPermission.leaveApply,
          AppPermission.libraryView,
          AppPermission.documentsView,
        };

      case UserRole.classTeacher:
        return <String>{
          ...common,
          AppPermission.studentsView,
          AppPermission.studentsUpdate,
          AppPermission.parentsView,
          AppPermission.attendanceView,
          AppPermission.attendanceMark,
          AppPermission.attendanceManage,
          AppPermission.academicsView,
          AppPermission.academicsManage,
          AppPermission.examsView,
          AppPermission.examsMarksEnter,
          AppPermission.communicationManage,
          AppPermission.activitiesView,
          AppPermission.activitiesManage,
          AppPermission.leaveView,
          AppPermission.leaveApply,
          AppPermission.libraryView,
          AppPermission.reportsView,
          AppPermission.documentsView,
        };

      case UserRole.student:
        return <String>{
          ...common,
          AppPermission.studentsView,
          AppPermission.academicsView,
          AppPermission.welfareView,
          AppPermission.helpdeskView,
          AppPermission.attendanceView,
          AppPermission.examsView,
          AppPermission.feesView,
          AppPermission.libraryView,
          AppPermission.transportView,
          AppPermission.hostelView,
          AppPermission.activitiesView,
          AppPermission.leaveView,
          AppPermission.leaveApply,
          AppPermission.documentsView,
        };

      case UserRole.parent:
        return <String>{
          ...common,
          AppPermission.parentsView,
          AppPermission.academicsView,
          AppPermission.libraryView,
          AppPermission.hostelView,
          AppPermission.welfareView,
          AppPermission.helpdeskView,
          AppPermission.studentsView,
          AppPermission.attendanceView,
          AppPermission.examsView,
          AppPermission.feesView,
          AppPermission.transportView,
          AppPermission.activitiesView,
          AppPermission.leaveView,
          AppPermission.leaveApply,
          AppPermission.documentsView,
        };

      case UserRole.librarian:
        return <String>{
          ...common,
          AppPermission.libraryView,
          AppPermission.libraryManage,
          AppPermission.studentsView,
          AppPermission.teachersView,
          AppPermission.employeesView,
          AppPermission.reportsView,
        };

      case UserRole.hrManager:
        return <String>{
          ...common,
          AppPermission.teachersView,
          AppPermission.teachersManage,
          AppPermission.employeesView,
          AppPermission.employeesManage,
          AppPermission.hrView,
          AppPermission.hrManage,
          AppPermission.payrollManage,
          AppPermission.attendanceView,
          AppPermission.attendanceManage,
          AppPermission.leaveView,
          AppPermission.leaveManage,
          AppPermission.reportsView,
          AppPermission.documentsView,
          AppPermission.documentsManage,
          AppPermission.welfareView,
          AppPermission.complianceView,
          AppPermission.complianceManage,
        };

      case UserRole.receptionist:
        return <String>{
          ...common,
          AppPermission.admissionsView,
          AppPermission.admissionsManage,
          AppPermission.studentsView,
          AppPermission.studentsCreate,
          AppPermission.parentsView,
          AppPermission.transportView,
          AppPermission.helpdeskView,
          AppPermission.helpdeskManage,
        };

      case UserRole.transportManager:
        return <String>{
          ...common,
          AppPermission.transportView,
          AppPermission.transportManage,
          AppPermission.studentsView,
          AppPermission.parentsView,
          AppPermission.employeesView,
          AppPermission.reportsView,
        };

      case UserRole.hostelManager:
        return <String>{
          ...common,
          AppPermission.hostelView,
          AppPermission.hostelManage,
          AppPermission.studentsView,
          AppPermission.parentsView,
          AppPermission.feesView,
          AppPermission.inventoryView,
          AppPermission.reportsView,
        };

      case UserRole.itAdmin:
        return <String>{
          ...common,
          AppPermission.schoolSetupView,
          AppPermission.settingsView,
          AppPermission.settingsManage,
          AppPermission.usersManage,
          AppPermission.tenantManage,
          AppPermission.subscriptionManage,
          AppPermission.auditView,
          AppPermission.integrationsView,
          AppPermission.integrationsManage,
          AppPermission.complianceView,
          AppPermission.complianceManage,
          AppPermission.aiView,
          AppPermission.aiManage,
          AppPermission.saasAdminView,
          AppPermission.saasAdminManage,
          AppPermission.reportsView,
          AppPermission.helpdeskView,
          AppPermission.helpdeskManage,
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
