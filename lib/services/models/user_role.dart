/// Role-based access control for the multi-tenant SMS SaaS.
///
/// Every user belongs to exactly one tenant (organization/school) and carries
/// one role that governs what they can see and do.
///
/// Written as a plain enum + extension (no "enhanced enum" members) so it
/// compiles on any Dart language version.
enum UserRole {
  superAdmin, // platform owner — manages all tenants (CARTZ Link staff)
  admin, // school administrator — manages one tenant
  teacher,
  student,
  parent,
}

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.student:
        return 'Student';
      case UserRole.parent:
        return 'Parent';
    }
  }

  /// Stable string used for storage/serialization.
  String get value {
    switch (this) {
      case UserRole.superAdmin:
        return 'superAdmin';
      case UserRole.admin:
        return 'admin';
      case UserRole.teacher:
        return 'teacher';
      case UserRole.student:
        return 'student';
      case UserRole.parent:
        return 'parent';
    }
  }

  bool get canManageTenant =>
      this == UserRole.admin || this == UserRole.superAdmin;
  bool get canManagePlatform => this == UserRole.superAdmin;
  bool get canTakeAttendance => this == UserRole.teacher || canManageTenant;
}

UserRole userRoleFromString(String? value) {
  switch (value) {
    case 'superAdmin':
      return UserRole.superAdmin;
    case 'admin':
      return UserRole.admin;
    case 'teacher':
      return UserRole.teacher;
    case 'parent':
      return UserRole.parent;
    case 'student':
    default:
      return UserRole.student;
  }
}
