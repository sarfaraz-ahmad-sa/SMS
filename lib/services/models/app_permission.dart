/// Stable permission keys shared by the Flutter client, Firestore rules,
/// and the future Laravel API. Flutter uses these only for presentation;
/// Firestore/Laravel remains the final authorization boundary.
class AppPermission {
  AppPermission._();

  static const String wildcard = '*';

  static const String profileView = 'profile.view';
  static const String notificationsView = 'notifications.view';

  static const String attendanceView = 'attendance.view';
  static const String attendanceMark = 'attendance.mark';
  static const String attendanceManage = 'attendance.manage';

  static const String examsView = 'exams.view';
  static const String examsManage = 'exams.manage';
  static const String examResultsPublish = 'exams.results.publish';

  static const String timetableView = 'timetable.view';
  static const String timetableManage = 'timetable.manage';

  static const String libraryView = 'library.view';
  static const String libraryManage = 'library.manage';

  static const String feesView = 'fees.view';
  static const String feesManage = 'fees.manage';
  static const String feesCollect = 'fees.collect';
  static const String feesRefund = 'fees.refund';

  static const String transportView = 'transport.view';
  static const String transportManage = 'transport.manage';

  static const String leaveView = 'leave.view';
  static const String leaveApply = 'leave.apply';
  static const String leaveManage = 'leave.manage';

  static const String activitiesView = 'activities.view';
  static const String activitiesManage = 'activities.manage';

  static const String admissionsView = 'admissions.view';
  static const String admissionsManage = 'admissions.manage';

  static const String studentsView = 'students.view';
  static const String studentsCreate = 'students.create';
  static const String studentsUpdate = 'students.update';
  static const String studentsArchive = 'students.archive';
  static const String studentsPromote = 'students.promote';

  static const String teachersView = 'teachers.view';
  static const String teachersManage = 'teachers.manage';

  static const String hrView = 'hr.view';
  static const String hrManage = 'hr.manage';
  static const String payrollManage = 'payroll.manage';

  static const String accountingView = 'accounting.view';
  static const String accountingManage = 'accounting.manage';

  static const String eventsView = 'events.view';
  static const String eventsManage = 'events.manage';

  static const String hostelView = 'hostel.view';
  static const String hostelManage = 'hostel.manage';

  static const String inventoryView = 'inventory.view';
  static const String inventoryManage = 'inventory.manage';

  static const String reportsView = 'reports.view';
  static const String settingsView = 'settings.view';
  static const String usersManage = 'users.manage';
  static const String tenantManage = 'tenant.manage';
}
