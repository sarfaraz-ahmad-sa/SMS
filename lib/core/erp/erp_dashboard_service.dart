import '../../services/UserModel.dart';
import '../../services/models/user_role.dart';
import '../../services/session_state.dart';
import 'erp_access_policy.dart';
import 'erp_catalog.dart';
import 'tenant_erp_service.dart';

class ErpDashboardMetric {
  final String key;
  final String label;
  final int value;

  const ErpDashboardMetric({
    required this.key,
    required this.label,
    required this.value,
  });
}

class ErpDashboardSnapshot {
  final List<ErpDashboardMetric> metrics;

  const ErpDashboardSnapshot({required this.metrics});
}

class ErpDashboardService {
  ErpDashboardService({TenantErpService? service})
      : _service = service ?? TenantErpService();

  final TenantErpService _service;

  Future<ErpDashboardSnapshot> load() async {
    final state = SessionState.instance;
    final user = state.user;
    if (user == null) {
      return const ErpDashboardSnapshot(metrics: <ErpDashboardMetric>[]);
    }

    final specs = _specsFor(user);
    final visibleSpecs = specs.where((spec) => _canView(spec, user, state));
    final metrics = <ErpDashboardMetric>[];
    final summary = await _service.loadDashboardSummary();

    for (final spec in visibleSpecs.take(6)) {
      final value = await _loadValue(spec, user, state, summary);
      metrics.add(
        ErpDashboardMetric(
          key: spec.key,
          label: spec.label,
          value: value,
        ),
      );
    }

    return ErpDashboardSnapshot(metrics: metrics);
  }

  bool _canView(
    _DashboardMetricSpec spec,
    UserModel user,
    SessionState state,
  ) {
    return spec.collections.any((String collection) {
      final entity = ErpCatalog.entityByCollection(collection);
      return entity != null &&
          ErpAccessPolicy.canViewEntity(
            entity,
            user,
            state.hasPermission,
          );
    });
  }

  Future<int> _loadValue(
    _DashboardMetricSpec spec,
    UserModel user,
    SessionState state,
    Map<String, dynamic> summary,
  ) async {
    var total = 0;

    for (final collection in spec.collections) {
      final entity = ErpCatalog.entityByCollection(collection);
      if (entity == null ||
          !ErpAccessPolicy.canViewEntity(
            entity,
            user,
            state.hasPermission,
          )) {
        continue;
      }

      if (spec.filterCollection == collection &&
          spec.filterField != null &&
          spec.filterValue != null &&
          !user.role.isLearner &&
          !user.role.isGuardian) {
        final summarized = _summaryStatusCount(
          summary,
          collection,
          spec.filterValue.toString(),
        );
        if (summarized != null) {
          total += summarized;
          continue;
        }
        total += await _service.countWhere(
          collection,
          spec.filterField!,
          spec.filterValue,
        );
      } else {
        if (!user.role.isLearner && !user.role.isGuardian) {
          final summarized = _summaryCount(summary, collection);
          if (summarized != null) {
            total += summarized;
            continue;
          }
        }
        total += await _service.countVisible(entity);
      }
    }

    return total;
  }

  int? _summaryCount(Map<String, dynamic> summary, String collection) {
    final counts = summary['counts'];
    if (counts is! Map || !counts.containsKey(collection)) return null;
    return (counts[collection] as num?)?.toInt();
  }

  int? _summaryStatusCount(
    Map<String, dynamic> summary,
    String collection,
    String status,
  ) {
    final allStatuses = summary['statusCounts'];
    if (allStatuses is! Map) return null;
    final statuses = allStatuses[collection];
    if (statuses is! Map) return null;
    final key = Uri.encodeComponent(status);
    if (!statuses.containsKey(key)) return null;
    return (statuses[key] as num?)?.toInt();
  }

  List<_DashboardMetricSpec> _specsFor(UserModel user) {
    if (user.role.isLearner) {
      return const <_DashboardMetricSpec>[
        _DashboardMetricSpec('my-profile', 'My Profile', <String>['students']),
        _DashboardMetricSpec(
          'attendance',
          'Attendance Records',
          <String>['student_attendance'],
        ),
        _DashboardMetricSpec(
          'assignments',
          'Assignments',
          <String>['assignments'],
        ),
        _DashboardMetricSpec(
          'results',
          'Exam Results',
          <String>['exam_results'],
        ),
        _DashboardMetricSpec(
          'invoices',
          'Fee Invoices',
          <String>['fee_invoices'],
        ),
        _DashboardMetricSpec(
          'certificates',
          'Certificates',
          <String>['issued_certificates'],
        ),
      ];
    }

    if (user.role.isGuardian) {
      return const <_DashboardMetricSpec>[
        _DashboardMetricSpec(
          'children',
          'Linked Children',
          <String>['students'],
        ),
        _DashboardMetricSpec(
          'attendance',
          'Attendance Records',
          <String>['student_attendance'],
        ),
        _DashboardMetricSpec(
          'results',
          'Exam Results',
          <String>['exam_results'],
        ),
        _DashboardMetricSpec(
          'invoices',
          'Fee Invoices',
          <String>['fee_invoices'],
        ),
        _DashboardMetricSpec(
          'meetings',
          'Parent Meetings',
          <String>['parent_meetings'],
        ),
        _DashboardMetricSpec(
          'requests',
          'My Requests',
          <String>['student_leave_requests', 'certificate_requests'],
        ),
      ];
    }

    if (user.hasRole(UserRole.accountant)) {
      return const <_DashboardMetricSpec>[
        _DashboardMetricSpec(
            'invoices', 'Fee Invoices', <String>['fee_invoices']),
        _DashboardMetricSpec('payments', 'Payments', <String>['payments']),
        _DashboardMetricSpec('refunds', 'Refunds', <String>['fee_refunds']),
        _DashboardMetricSpec(
            'journals', 'Journal Entries', <String>['journal_entries']),
        _DashboardMetricSpec(
            'banks', 'Bank Accounts', <String>['bank_accounts']),
        _DashboardMetricSpec('budgets', 'Budgets', <String>['budgets']),
      ];
    }

    if (user.hasRole(UserRole.teacher) || user.hasRole(UserRole.classTeacher)) {
      return const <_DashboardMetricSpec>[
        _DashboardMetricSpec('students', 'Students', <String>['students']),
        _DashboardMetricSpec(
          'attendance',
          'Attendance Records',
          <String>['student_attendance'],
        ),
        _DashboardMetricSpec(
            'assignments', 'Assignments', <String>['assignments']),
        _DashboardMetricSpec(
            'marks', 'Marks Entries', <String>['mark_entries']),
        _DashboardMetricSpec('events', 'Events', <String>['events']),
        _DashboardMetricSpec(
            'leave', 'Leave Requests', <String>['leave_requests']),
      ];
    }

    if (user.hasRole(UserRole.librarian)) {
      return const <_DashboardMetricSpec>[
        _DashboardMetricSpec('books', 'Books', <String>['books']),
        _DashboardMetricSpec('loans', 'Book Loans', <String>['book_loans']),
        _DashboardMetricSpec(
          'reservations',
          'Reservations',
          <String>['library_reservations'],
        ),
        _DashboardMetricSpec('students', 'Students', <String>['students']),
        _DashboardMetricSpec('teachers', 'Teachers', <String>['teachers']),
        _DashboardMetricSpec('events', 'Events', <String>['events']),
      ];
    }

    if (user.hasRole(UserRole.hrManager)) {
      return const <_DashboardMetricSpec>[
        _DashboardMetricSpec('employees', 'Employees', <String>['employees']),
        _DashboardMetricSpec('teachers', 'Teachers', <String>['teachers']),
        _DashboardMetricSpec(
            'leave', 'Leave Requests', <String>['leave_requests']),
        _DashboardMetricSpec(
            'payroll', 'Payroll Runs', <String>['payroll_runs']),
        _DashboardMetricSpec(
          'staff-attendance',
          'Staff Attendance',
          <String>['staff_attendance'],
        ),
        _DashboardMetricSpec(
            'contracts', 'Contracts', <String>['employee_contracts']),
      ];
    }

    if (user.hasRole(UserRole.receptionist)) {
      return const <_DashboardMetricSpec>[
        _DashboardMetricSpec(
          'admissions',
          'Admissions',
          <String>['admission_applications'],
        ),
        _DashboardMetricSpec('students', 'Students', <String>['students']),
        _DashboardMetricSpec('guardians', 'Guardians', <String>['guardians']),
        _DashboardMetricSpec(
            'appointments', 'Appointments', <String>['appointments']),
        _DashboardMetricSpec('visitors', 'Visitors', <String>['visitor_log']),
        _DashboardMetricSpec(
            'complaints', 'Complaints', <String>['complaints']),
      ];
    }

    if (user.hasRole(UserRole.transportManager)) {
      return const <_DashboardMetricSpec>[
        _DashboardMetricSpec('routes', 'Routes', <String>['transport_routes']),
        _DashboardMetricSpec('vehicles', 'Vehicles', <String>['vehicles']),
        _DashboardMetricSpec('drivers', 'Drivers', <String>['drivers']),
        _DashboardMetricSpec(
          'assignments',
          'Student Assignments',
          <String>['transport_assignments'],
        ),
        _DashboardMetricSpec('students', 'Students', <String>['students']),
        _DashboardMetricSpec('events', 'Events', <String>['events']),
      ];
    }

    if (user.hasRole(UserRole.hostelManager)) {
      return const <_DashboardMetricSpec>[
        _DashboardMetricSpec('rooms', 'Hostel Rooms', <String>['hostel_rooms']),
        _DashboardMetricSpec(
          'allocations',
          'Bed Allocations',
          <String>['hostel_allocations'],
        ),
        _DashboardMetricSpec(
            'visitors', 'Hostel Visitors', <String>['hostel_visitors']),
        _DashboardMetricSpec('students', 'Students', <String>['students']),
        _DashboardMetricSpec(
            'invoices', 'Fee Invoices', <String>['fee_invoices']),
        _DashboardMetricSpec('assets', 'Assets', <String>['assets']),
      ];
    }

    if (user.hasRole(UserRole.itAdmin)) {
      return const <_DashboardMetricSpec>[
        _DashboardMetricSpec('users', 'User Access', <String>['user_access']),
        _DashboardMetricSpec('integrations', 'Integrations',
            <String>['integration_connections']),
        _DashboardMetricSpec('backups', 'Backup Jobs', <String>['backup_jobs']),
        _DashboardMetricSpec(
            'audits', 'Audit Reviews', <String>['audit_reviews']),
        _DashboardMetricSpec(
          'tickets',
          'Open Tickets',
          <String>['support_tickets'],
          filterCollection: 'support_tickets',
          filterField: 'status',
          filterValue: 'Open',
        ),
        _DashboardMetricSpec(
            'features', 'Feature Flags', <String>['feature_flags']),
      ];
    }

    return const <_DashboardMetricSpec>[
      _DashboardMetricSpec('students', 'Students', <String>['students']),
      _DashboardMetricSpec(
        'admissions',
        'Admissions',
        <String>['admission_applications'],
      ),
      _DashboardMetricSpec(
        'staff',
        'Teachers & Staff',
        <String>['teachers', 'employees'],
      ),
      _DashboardMetricSpec(
          'invoices', 'Fee Invoices', <String>['fee_invoices']),
      _DashboardMetricSpec('payments', 'Payments', <String>['payments']),
      _DashboardMetricSpec(
        'tickets',
        'Open Tickets',
        <String>['support_tickets'],
        filterCollection: 'support_tickets',
        filterField: 'status',
        filterValue: 'Open',
      ),
    ];
  }
}

class _DashboardMetricSpec {
  final String key;
  final String label;
  final List<String> collections;
  final String? filterCollection;
  final String? filterField;
  final dynamic filterValue;

  const _DashboardMetricSpec(
    this.key,
    this.label,
    this.collections, {
    this.filterCollection,
    this.filterField,
    this.filterValue,
  });
}
