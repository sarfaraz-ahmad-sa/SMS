# SaaS Foundation

Version 2.2 adds the shared control plane required to operate the School Management System as a multi-tenant SaaS product.

## Application shell

The authenticated workspace now uses one adaptive shell:

- permanent tenant-branded sidebar on large desktop screens;
- compact navigation rail on tablets;
- bottom navigation and drawer on phones;
- global search, notifications, theme switching and tenant switching;
- campus and academic-year working context;
- named routes for shared workspace destinations and ERP workflows.

The shell is implemented in `lib/Widgets/saas_scaffold.dart`.

## Tenant branding

`Tenant.logoUrl` and `Tenant.brandColor` are applied to:

- application colour scheme;
- workspace sidebar;
- dashboard and onboarding hero areas;
- school profile surfaces.

The global fallback palette remains accessible cobalt, navy and teal.

## Subscription entitlements

`Subscription` supports:

- trial, starter, professional, enterprise and custom tiers;
- trial, active, past-due, suspended and cancelled lifecycle states;
- current period, trial and grace-period dates;
- cancel-at-period-end;
- tenant feature overrides;
- tenant limit overrides.

Stable feature keys are defined in `lib/core/saas/saas_feature.dart`.

`PlanEntitlementService` enforces:

- module visibility;
- feature availability;
- student, staff, campus, storage, SMS, email and AI limits;
- inactive-subscription denial.

Firestore rules apply the same plan feature boundary to ERP collection reads and writes. UI checks remain a convenience; rules and trusted backend functions remain authoritative.

## SaaS Control Center

The control centre presents:

- current plan and subscription state;
- tenant usage against plan limits;
- enabled and locked features;
- onboarding access;
- users, billing, integrations, audit, backup and restore operations;
- trusted-backend production boundary guidance.

Route: `/saas`

## Tenant onboarding

The onboarding workspace calculates readiness from live tenant data:

1. school profile and branding;
2. campuses;
3. academic year;
4. classes and sections;
5. subjects and grading;
6. fee structure;
7. teachers and staff;
8. students and guardians;
9. secure user accounts;
10. launch review.

Route: `/onboarding`

## Usage collection

The trusted callable function `refreshSaasUsage` counts active students, paid staff accounts and campuses, preserves metered provider usage, writes `tenants/{tenantId}/saas_usage/current`, and appends an immutable audit record. Student and parent portal accounts are excluded from the paid staff-seat count.

External provider callbacks should update these fields transactionally:

- `storageMb`
- `smsThisMonth`
- `emailThisMonth`
- `aiActionsThisMonth`

Clients can read usage when authorized but cannot write it.

## Approval engine foundation

The callable functions provide a trusted generic boundary:

- `requestApproval`
- `decideApproval`

Management users can work from the responsive `/approvals` inbox. Rejections require a reason, while every decision is recorded through the backend.

Requests are stored at:

```text
tenants/{tenantId}/approval_requests/{approvalId}
```

Every submission and decision appends an immutable record under:

```text
tenants/{tenantId}/audit_logs/{logId}
```

Approval decisions do not automatically execute a financial, payroll or result operation. Each high-risk domain must add an idempotent executor after approval.

## Metered plan limits

Student and campus creation/archive operations use trusted callable functions:

- `createMeteredErpRecord`
- `archiveMeteredErpRecord`

Direct client creation of these metered collections is denied by Firestore rules. The Functions enforce the current plan limit transactionally and update `saas_usage/current`. Paid staff-user limits remain enforced by `provisionSchoolUser`; student and parent portal accounts do not consume staff seats.

## Account provisioning limits

`provisionSchoolUser` now validates:

- active tenant;
- usable subscription and grace period;
- paid staff-user limit for the current plan, excluding student and parent portal accounts;
- caller permission and role delegation;
- linked student/teacher record integrity.

## Deployment

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release --no-wasm-dry-run
firebase deploy --only functions,firestore:rules,firestore:indexes,storage
```

After deployment, run `tools/firebase_admin/migrate-saas-foundation.cmd` for existing tenants. It backfills plan defaults, recalculates live students/staff/campus usage and appends a migration audit event. Use `DEFAULT_SAAS_TIER=enterprise` during compatibility migration unless an existing tenant already has an assigned plan.

## Remaining production integrations

The foundation does not pretend to complete third-party settlement or legally significant operations. Before live use, connect trusted implementations for:

- payment gateway callback verification and reconciliation;
- double-entry posting, reversal and period close;
- payroll approval and bank disbursement;
- final result locking and publication;
- signed certificates and public verification;
- SMS, email, WhatsApp, push, biometric and GPS providers;
- backups, retention enforcement and restore tests.
