/// Stable authorization keys shared by Flutter, Firestore rules, and the
/// future Laravel API. Flutter only uses these keys to shape the interface;
/// the backend remains the final authorization boundary.
class AppPermission {
  AppPermission._();

  static const String wildcard = '*';

  static const String profileView = 'profile.view';
  static const String notificationsView = 'notifications.view';
  static const String notificationsManage = 'notifications.manage';

  static const String dashboardView = 'dashboard.view';

  static const String schoolSetupView = 'school_setup.view';
  static const String schoolSetupManage = 'school_setup.manage';

  static const String admissionsView = 'admissions.view';
  static const String admissionsManage = 'admissions.manage';
  static const String admissionsApprove = 'admissions.approve';

  static const String studentsView = 'students.view';
  static const String studentsCreate = 'students.create';
  static const String studentsUpdate = 'students.update';
  static const String studentsArchive = 'students.archive';
  static const String studentsPromote = 'students.promote';
  static const String studentsManage = 'students.manage';

  static const String parentsView = 'parents.view';
  static const String parentsManage = 'parents.manage';

  static const String teachersView = 'teachers.view';
  static const String teachersManage = 'teachers.manage';

  static const String employeesView = 'employees.view';
  static const String employeesManage = 'employees.manage';

  static const String hrView = 'hr.view';
  static const String hrManage = 'hr.manage';
  static const String payrollManage = 'payroll.manage';
  static const String payrollApprove = 'payroll.approve';

  static const String attendanceView = 'attendance.view';
  static const String attendanceMark = 'attendance.mark';
  static const String attendanceManage = 'attendance.manage';
  static const String attendanceApprove = 'attendance.approve';

  static const String academicsView = 'academics.view';
  static const String academicsManage = 'academics.manage';

  static const String examsView = 'exams.view';
  static const String examsManage = 'exams.manage';
  static const String examsMarksEnter = 'exams.marks.enter';
  static const String examsApprove = 'exams.approve';
  static const String examResultsPublish = 'exams.results.publish';

  static const String timetableView = 'timetable.view';
  static const String timetableManage = 'timetable.manage';

  static const String feesView = 'fees.view';
  static const String feesManage = 'fees.manage';
  static const String feesCollect = 'fees.collect';
  static const String feesRefund = 'fees.refund';
  static const String feesApproveRefund = 'fees.refund.approve';

  static const String accountingView = 'accounting.view';
  static const String accountingManage = 'accounting.manage';
  static const String accountingApprove = 'accounting.approve';

  static const String libraryView = 'library.view';
  static const String libraryManage = 'library.manage';

  static const String transportView = 'transport.view';
  static const String transportManage = 'transport.manage';

  static const String hostelView = 'hostel.view';
  static const String hostelManage = 'hostel.manage';

  static const String inventoryView = 'inventory.view';
  static const String inventoryManage = 'inventory.manage';

  static const String communicationView = 'communication.view';
  static const String communicationManage = 'communication.manage';

  static const String eventsView = 'events.view';
  static const String eventsManage = 'events.manage';

  static const String documentsView = 'documents.view';
  static const String documentsManage = 'documents.manage';
  static const String certificatesApprove = 'certificates.approve';

  static const String leaveView = 'leave.view';
  static const String leaveApply = 'leave.apply';
  static const String leaveManage = 'leave.manage';

  static const String activitiesView = 'activities.view';
  static const String activitiesManage = 'activities.manage';

  static const String welfareView = 'welfare.view';
  static const String welfareManage = 'welfare.manage';

  static const String integrationsView = 'integrations.view';
  static const String integrationsManage = 'integrations.manage';

  static const String complianceView = 'compliance.view';
  static const String complianceManage = 'compliance.manage';

  static const String aiView = 'ai.view';
  static const String aiManage = 'ai.manage';

  static const String saasAdminView = 'saas_admin.view';
  static const String saasAdminManage = 'saas_admin.manage';

  static const String reportsView = 'reports.view';
  static const String reportsManage = 'reports.manage';

  static const String helpdeskView = 'helpdesk.view';
  static const String helpdeskManage = 'helpdesk.manage';

  static const String settingsView = 'settings.view';
  static const String settingsManage = 'settings.manage';
  static const String usersManage = 'users.manage';
  static const String tenantManage = 'tenant.manage';
  static const String subscriptionManage = 'subscription.manage';
  static const String auditView = 'audit.view';
}
