# Firestore Data Model

## Platform collections

```text
users/{uid}
tenants/{tenantId}
tenants/{tenantId}/members/{uid}
accessRequests/{requestId}
```

## Tenant operational collections

All ERP data is stored below the active tenant:

```text
tenants/{tenantId}/{collection}/{recordId}
```

The current catalog contains 105 known operational collections. The complete list is generated in `ENTERPRISE_MODULES.md`.

Examples:

```text
tenants/{tenantId}/students/{studentId}
tenants/{tenantId}/student_attendance/{attendanceId}
tenants/{tenantId}/fee_invoices/{invoiceId}
tenants/{tenantId}/payments/{paymentId}
tenants/{tenantId}/exams/{examId}
tenants/{tenantId}/employees/{employeeId}
tenants/{tenantId}/books/{bookId}
tenants/{tenantId}/integration_connections/{connectionId}
```

## Standard operational metadata

Every client-created ERP record includes:

```text
tenantId
campusId
academicYearId
createdBy
createdAt
updatedBy
updatedAt
isArchived
archivedBy
archivedAt
```

Records are archived rather than hard deleted. Financial, academic-publication and legal records should additionally use immutable server-side events and reversals.

## User document

```text
email
displayName
photoUrl
tenantIds[]
activeTenantId
activeCampusId
activeAcademicYearId
isActive
createdAt
updatedAt
```

The user document is a platform identity profile. It is not the sole source of tenant authorization.

## Membership document

```text
status: active | inactive | suspended
roles[]
permissions[]
deniedPermissions[]
campusIds[]
activeCampusId
activeAcademicYearId
createdAt
updatedAt
```

Roles and permission changes must be performed by a trusted backend or Firebase Admin process.

## Sensitive records

Medical, counseling, safeguarding, payroll, financial, marks and identity records require narrower backend policies than general school records. The Flutter UI already filters them by permission, but live deployments must test Firestore rules with representative user roles and should move sensitive operations to the trusted API.

## Trusted-only operations

- Tenant creation and suspension
- Subscription activation
- Firebase Authentication user provisioning
- Membership and role assignment
- Financial posting and reconciliation
- Payroll approval and disbursement
- Final result publication
- Certificate signing
- Immutable audit events
- Backup, restore, retention and legal hold execution
- Permanent deletion or anonymization

## SaaS control-plane collections

```text
tenants/{tenantId}/saas_usage/current
tenants/{tenantId}/approval_requests/{approvalId}
tenants/{tenantId}/audit_logs/{logId}
tenants/{tenantId}/onboarding_state/current
```

`saas_usage/current` is written only by trusted backend code. It stores current
student, staff, campus, storage, SMS, email and AI usage.

`approval_requests` is also backend-controlled. The requester and authorized
approvers may read relevant requests, but direct client writes are denied.

`audit_logs` is append-only from trusted code and read-only for authorized
leadership, audit and IT roles.

The tenant document subscription map may contain:

```text
subscription.tier
subscription.status
subscription.currentPeriodEnd
subscription.trialEndsAt
subscription.gracePeriodEndsAt
subscription.cancelAtPeriodEnd
subscription.enabledFeatures[]
subscription.limits.students
subscription.limits.staffUsers
subscription.limits.campuses
subscription.limits.storageMb
subscription.limits.smsPerMonth
subscription.limits.emailPerMonth
subscription.limits.aiActionsPerMonth
```
