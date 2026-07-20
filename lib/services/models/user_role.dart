/// Role-based access control for the multi-tenant School ERP.
///
/// Plain enum + extension (no "enhanced enum" members) for Dart-version
/// compatibility.
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

  /// Stable string for storage/serialization.
  String get value => toString().split('.').last;

  // Broad permission groups used to gate dashboard modules.
  bool get canManagePlatform => this == UserRole.superAdmin;

  bool get isLeadership =>
      this == UserRole.superAdmin ||
      this == UserRole.schoolOwner ||
      this == UserRole.principal ||
      this == UserRole.vicePrincipal;

  bool get canManageStudents =>
      isLeadership ||
      this == UserRole.adminStaff ||
      this == UserRole.receptionist ||
      this == UserRole.classTeacher;

  bool get canManageStaff => isLeadership || this == UserRole.hrManager;

  bool get canManageFinance =>
      isLeadership || this == UserRole.accountant;

  bool get canTakeAttendance =>
      isLeadership || this == UserRole.teacher || this == UserRole.classTeacher;

  bool get isStaff =>
      this != UserRole.student && this != UserRole.parent;
}

UserRole userRoleFromString(String? value) {
  for (final r in UserRole.values) {
    if (r.value == value) return r;
  }
  return UserRole.student;
}
