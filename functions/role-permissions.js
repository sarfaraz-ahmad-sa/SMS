"use strict";

const common = [
  "dashboard.view",
  "profile.view",
  "notifications.view",
  "timetable.view",
  "communication.view",
  "events.view",
];

const rolePermissions = {
  superAdmin: ["*"],
  schoolOwner: ["*"],
  principal: ["*"],
  vicePrincipal: ["*"],
  adminStaff: [
    ...common,
    "school_setup.view", "school_setup.manage",
    "admissions.view", "admissions.manage",
    "students.view", "students.create", "students.update", "students.manage",
    "parents.view", "parents.manage",
    "teachers.view", "employees.view",
    "attendance.view", "attendance.manage",
    "academics.view", "exams.view", "fees.view", "library.view",
    "transport.view", "hostel.view", "inventory.view",
    "communication.manage", "events.manage",
    "documents.view", "documents.manage",
    "welfare.view", "welfare.manage", "compliance.view",
    "reports.view", "helpdesk.view", "helpdesk.manage",
    "settings.view", "users.manage",
  ],
  accountant: [
    ...common,
    "students.view", "parents.view",
    "fees.view", "fees.manage", "fees.collect", "fees.refund",
    "accounting.view", "accounting.manage", "payroll.manage",
    "inventory.view", "reports.view", "documents.view",
  ],
  teacher: [
    ...common,
    "students.view",
    "attendance.view", "attendance.mark",
    "academics.view", "academics.manage",
    "exams.view", "exams.marks.enter",
    "activities.view", "activities.manage",
    "leave.view", "leave.apply",
    "library.view", "documents.view",
  ],
  classTeacher: [
    ...common,
    "students.view", "students.update", "parents.view",
    "attendance.view", "attendance.mark", "attendance.manage",
    "academics.view", "academics.manage",
    "exams.view", "exams.marks.enter",
    "communication.manage",
    "activities.view", "activities.manage",
    "leave.view", "leave.apply",
    "library.view", "reports.view", "documents.view",
  ],
  student: [
    ...common,
    "students.view", "academics.view", "welfare.view", "helpdesk.view",
    "attendance.view", "exams.view", "fees.view", "library.view",
    "transport.view", "hostel.view", "activities.view",
    "leave.view", "leave.apply", "documents.view",
  ],
  parent: [
    ...common,
    "parents.view", "academics.view", "library.view", "hostel.view",
    "welfare.view", "helpdesk.view", "students.view", "attendance.view",
    "exams.view", "fees.view", "transport.view", "activities.view",
    "leave.view", "leave.apply", "documents.view",
  ],
  librarian: [
    ...common,
    "library.view", "library.manage",
    "students.view", "teachers.view", "employees.view", "reports.view",
  ],
  hrManager: [
    ...common,
    "teachers.view", "teachers.manage",
    "employees.view", "employees.manage",
    "hr.view", "hr.manage", "payroll.manage",
    "attendance.view", "attendance.manage",
    "leave.view", "leave.manage", "reports.view",
    "documents.view", "documents.manage",
    "welfare.view", "compliance.view", "compliance.manage",
  ],
  receptionist: [
    ...common,
    "admissions.view", "admissions.manage",
    "students.view", "students.create", "parents.view",
    "transport.view", "helpdesk.view", "helpdesk.manage",
  ],
  transportManager: [
    ...common,
    "transport.view", "transport.manage",
    "students.view", "parents.view", "employees.view", "reports.view",
  ],
  hostelManager: [
    ...common,
    "hostel.view", "hostel.manage",
    "students.view", "parents.view", "fees.view",
    "inventory.view", "reports.view",
  ],
  itAdmin: [
    ...common,
    "school_setup.view",
    "settings.view", "settings.manage", "users.manage", "tenant.manage",
    "subscription.manage", "audit.view",
    "integrations.view", "integrations.manage",
    "compliance.view", "compliance.manage",
    "ai.view", "ai.manage", "saas_admin.view", "saas_admin.manage",
    "reports.view", "helpdesk.view", "helpdesk.manage",
  ],
};

const allRoles = Object.freeze(Object.keys(rolePermissions));

function effectivePermissionsForRoles(roles) {
  const permissions = new Set();
  for (const role of roles) {
    for (const permission of rolePermissions[role] ?? []) {
      permissions.add(permission);
    }
  }
  return [...permissions].sort();
}

module.exports = {
  allRoles,
  effectivePermissionsForRoles,
  rolePermissions,
};
