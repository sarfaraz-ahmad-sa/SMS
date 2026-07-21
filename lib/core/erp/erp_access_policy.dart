import '../../services/UserModel.dart';
import '../../services/models/user_role.dart';
import 'erp_entity.dart';
import 'erp_module.dart';

class ErpAccessPolicy {
  ErpAccessPolicy._();

  static const Set<String> _studentCollections = <String>{
    'students',
    'student_attendance',
    'assignments',
    'study_materials',
    'exam_schedules',
    'exam_results',
    'transcripts',
    'fee_invoices',
    'payments',
    'books',
    'book_loans',
    'library_reservations',
    'transport_routes',
    'transport_assignments',
    'hostel_allocations',
    'announcements',
    'circulars',
    'events',
    'competitions',
    'event_registrations',
    'certificate_requests',
    'issued_certificates',
    'timetable_entries',
    'student_medical_profiles',
    'learning_accommodations',
    'student_leave_requests',
    'support_tickets',
  };

  static const Set<String> _parentCollections = <String>{
    'students',
    'student_attendance',
    'assignments',
    'study_materials',
    'exam_schedules',
    'exam_results',
    'transcripts',
    'fee_invoices',
    'payments',
    'books',
    'book_loans',
    'library_reservations',
    'transport_routes',
    'transport_assignments',
    'hostel_allocations',
    'announcements',
    'circulars',
    'events',
    'competitions',
    'event_registrations',
    'certificate_requests',
    'issued_certificates',
    'timetable_entries',
    'student_medical_profiles',
    'learning_accommodations',
    'student_leave_requests',
    'leave_requests',
    'parent_meetings',
    'support_tickets',
    'complaints',
  };

  static const Set<String> personalStudentCollections = <String>{
    'students',
    'student_attendance',
    'exam_results',
    'transcripts',
    'fee_invoices',
    'payments',
    'book_loans',
    'transport_assignments',
    'hostel_allocations',
    'issued_certificates',
    'student_medical_profiles',
    'learning_accommodations',
  };

  static const Set<String> selfServiceCollections = <String>{
    'library_reservations',
    'event_registrations',
    'certificate_requests',
    'student_leave_requests',
    'leave_requests',
    'parent_meetings',
    'support_tickets',
    'complaints',
  };

  static bool canViewEntity(
    ErpEntity entity,
    UserModel? user,
    bool Function(String permission) hasPermission,
  ) {
    if (user == null || !hasPermission(entity.viewPermission)) return false;
    if (user.role.isLearner) {
      return _studentCollections.contains(entity.collection);
    }
    if (user.role.isGuardian) {
      return _parentCollections.contains(entity.collection);
    }
    return true;
  }

  static bool canViewModule(
    ErpModule module,
    UserModel? user,
    bool Function(String permission) hasPermission,
  ) {
    return module.entities.any(
      (ErpEntity entity) => canViewEntity(entity, user, hasPermission),
    );
  }

  static bool canCreate(
    ErpEntity entity,
    UserModel? user,
    bool Function(String permission) hasPermission,
  ) {
    if (hasPermission(entity.managePermission)) return true;
    if (user == null || !entity.allowSelfServiceCreate) return false;
    if (entity.selfServicePermission != null) {
      return hasPermission(entity.selfServicePermission!);
    }
    return user.role.isLearner || user.role.isGuardian;
  }

  static bool canEdit(
    ErpEntity entity,
    bool Function(String permission) hasPermission,
  ) {
    return hasPermission(entity.managePermission);
  }
}
