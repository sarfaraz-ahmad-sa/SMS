# Firebase to Supabase/PostgreSQL Migration

Status: core schema deployed to the Supabase staging project on 2026-08-03.
The application now runs in Supabase-primary mode by default. Firebase is not
initialized in this mode. Authentication, tenant/session context, dashboard,
students, generic ERP records, School Accounts, approvals, finance, payroll,
accounting, result publication, notifications, profile, settings, and school
profile operations now use Supabase/PostgreSQL paths.

Deployment verification for project `mmixwroevlfucxialdix`:

- 22 expected tables created; all 22 have RLS enabled and forced.
- 51 tenant/role/personal-access policies created.
- `record_fee_payment` is installed as a security-definer transaction RPC.
- A 106-collection ERP permission catalog and bounded `erp_records` adapter are
  deployed with forced RLS, exact campus/year filters, keyset pagination,
  optimistic concurrency, idempotency, soft archive, and audit logs.
- School Accounts uses a deployed `school-accounts` Edge Function for Auth
  administration. The service/secret key exists only in the function runtime.
- Refund, payroll, journal, expense, budget, payslip and result records use
  dedicated transaction RPCs. Direct high-risk table writes remain denied;
  approval and publishing status changes use validated server transitions.
- Anonymous tenant reads return no rows and anonymous payment calls are denied.
- Campus-scoped RLS hardening is deployed for students, setup, fees,
  attendance, exams, announcements, expenses, and dashboard summaries.
- The exact-scope dashboard summary refresh migration is deployed. Six trusted
  triggers maintain student, fee, payment, attendance, exam, and expense counts.
- The pilot `main-campus / 2026-2027` summary row was backfilled; anonymous
  callers cannot execute the private rebuild function. A transaction rollback
  test verified trigger refresh without retaining test data.
- The first read-only Firebase migration preflight mapped source tenant
  `school_demo` to target tenant `pilot_school`. Missing master documents were
  deterministically synthesized from the student's scoped labels. Validation
  passed with one campus, academic year, class, section, and student.
- That reference/student slice was imported idempotently and reconciled on
  2026-08-03: both Firebase and PostgreSQL report one student, and the trusted
  PostgreSQL dashboard summary reports `students = 1`. No financial, result,
  attendance, guardian, or authentication-link data was changed.
- Flutter now has a read-only PostgreSQL student pilot using keyset pagination.
  Every page requires explicit tenant, campus, and academic-year values, applies
  `is_archived = false` in PostgreSQL, orders by stable student ID, and requests
  at most `pageSize + 1` rows to determine whether another page exists.
- Student create, update, and archive RPCs are deployed. Authenticated clients
  have SELECT-only table access: every write now validates permission and exact
  tenant/campus/year/class/section scope, serializes case-insensitive admission
  number creation, rejects stale updates, preserves history through soft
  archive, and invokes the trusted audit/summary triggers transactionally.
- The one-time Supabase migration secret was deleted after reconciliation and
  its macOS Keychain entry and clipboard were cleared. The Firebase Admin key
  remains outside the repository under restricted filesystem permissions until
  the remaining migration slices are complete, after which it must be revoked.
- Rollback-based integration tests confirm tenant isolation, campus isolation,
  denied cross-campus writes/payments, a successful allowed-campus payment,
  denied direct student writes, duplicate admission prevention, stale-update
  protection, audit-log creation, and dashboard refresh after student archive.
- `ENABLE_SUPABASE_PRIMARY=true` now makes Supabase Auth and PostgreSQL the
  source of truth for the main login, restored session, dashboard summary, and
  student list/create/update/archive workflows. Demo student fallback is
  disabled in this mode.

## Authentication migration status

Supabase email/password authentication is configured with these production
defaults:

- Email provider enabled.
- Email confirmation required.
- Public self-signup disabled; accounts are invitation-only.
- Anonymous sign-in disabled.

The first owner invitation and RLS-protected pilot membership were verified.
Before production invitations, configure the stable HTTPS Vercel/custom-domain
redirect in Supabase Auth; no fixed localhost port is required by the app.

Flutter resolves the signed-in Supabase user into the shared application
session, active tenant, roles, permissions, campuses and academic year using
RLS-protected PostgreSQL reads.

Firebase compatibility code remains temporarily for rollback and legacy-screen
cleanup, but it is not initialized or used by the default Supabase-primary
runtime. It can be deleted after final Firebase data reconciliation and the
rollback window.

## What the first migration contains

Migration file:
`supabase/migrations/202608030001_core_school_schema.sql`

Security hardening and test files:

- `supabase/migrations/202608030002_campus_scope_rls.sql`
- `supabase/migrations/202608030003_dashboard_summary_refresh.sql`
- `supabase/migrations/202608030004_secure_student_mutations.sql`
- `supabase/migrations/202608030005_generic_erp_records.sql`
- `supabase/migrations/202608030006_school_accounts.sql`
- `supabase/migrations/202608030007_trusted_finance_results.sql`
- `supabase/migrations/202608030008_tenant_profile.sql`
- `supabase/tests/rls_tenant_campus_isolation.sql`
- `supabase/tests/secure_student_mutations.sql`
- `supabase/tests/generic_erp_records.sql`
- `supabase/tests/trusted_finance_results.sql`

- Tenant, profile, membership, campus, academic year, class, section, subject,
  student, and guardian relational tables.
- Fees, invoices, payments, attendance, exams, published results,
  announcements, expenses, dashboard summaries, and audit logs.
- Composite tenant foreign keys so a relationship cannot point to another
  school's row.
- Tenant/campus/year/status indexes for bounded operational queries.
- Row Level Security for staff permissions and parent/student personal access.
- Append-only audit triggers for business records.
- An idempotent `record_fee_payment` PostgreSQL RPC that locks the invoice,
  validates balance and permission, generates a unique receipt, inserts the
  payment, and updates the invoice in one transaction.
- A Supabase Auth profile trigger.
- One exact-scope dashboard summary row maintained by trusted database triggers;
  Flutter reads it with tenant, campus, academic-year filters and `limit(1)`.

Relational Phase 1 data uses dedicated tables. The remaining catalog entities
share the secured `erp_records` PostgreSQL table and server-side collection
permission registry.

## Create the free project

1. Create one Supabase Free project in the closest acceptable region.
2. Record the Project URL and client publishable key from the Connect panel.
3. Store the database password in a password manager. Do not place it in this
   repository, Flutter, Vercel client variables, screenshots, or chat.
4. In the SQL Editor, run the migration file once, or link the Supabase CLI and
   use `supabase db push`.
5. Verify every public table shows RLS enabled before adding any real data.

Client configuration:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_REDACTED \
  --dart-define=ENABLE_SUPABASE_SHADOW=true
```

Only the publishable key belongs in the client. The secret/service-role key
bypasses RLS and is restricted to trusted migration tooling and server-side
Functions.

## Firestore to PostgreSQL mapping

| Firebase path/collection | PostgreSQL table |
| --- | --- |
| `tenants/{tenant}` | `tenants` |
| `users/{uid}` | `profiles` plus Supabase `auth.users` |
| `tenants/{tenant}/members` | `tenant_members` |
| `campuses` / `academic_years` | `campuses` / `academic_years` |
| `classes` / `sections` / `subjects` | same named relational tables |
| `students` / `guardians` / `student_guardians` | same named relational tables |
| `fee_structures` / `fee_invoices` | same named relational tables |
| `payments` | `payments`, written only through secure RPC |
| `attendance_sessions` / `student_attendance` | same named relational tables |
| `exams` / `exam_results` | same named relational tables |
| `announcements` / `expenses` | same named relational tables |
| `dashboard_summaries` / `audit_logs` | same named relational tables |

Firestore document IDs are preserved as text IDs. Supabase authentication IDs
are UUIDs, so Firebase UIDs are not inserted into `auth_user_id` columns.
Instead, the migration produces a private UID mapping after each user accepts
an invitation or completes a password reset.

## Safe cutover sequence

1. Export and checksum Firebase Auth, Firestore, and Storage backups.
2. Apply schema and test RLS using two tenants and every Phase 1 role.
3. Import non-user reference data into a staging Supabase project.
4. Invite test users and create the Firebase-UID to Supabase-UUID mapping.
5. Import students/guardians, then invoices, payments, attendance, and results
   in foreign-key order.
6. Reconcile per-tenant row counts and financial totals against Firebase.
7. Implement and test the Supabase ERP/Auth adapters behind repository
   interfaces.
8. Run web and Android pilot tests on slow/throttled connections.
9. Schedule a short write freeze, export the final delta, reconcile again, and
   switch the backend flag.
10. Keep Firebase read-only during the rollback window; remove it only after
    backups and acceptance sign-off.

Do not dual-write payments, refunds, invoices, payroll, journals, or published
results. A failed partial dual write can create financial inconsistencies.

## Remaining production work

- Production-domain Auth redirects and email templates.
- Invoice generation and bulk monthly billing jobs.
- Automated RLS/transaction tests in a local Supabase stack.
- Scheduled backup execution, restore drills, retention and billing alerts.
- CSV/PDF report workers and short-lived signed export downloads.
- Remove the dormant Firebase packages and compatibility code after acceptance
  testing and rollback sign-off.

Completed on 2026-08-03: the only Firebase tenant (`school_demo`) was inventoried
read-only (10 documents), its 7 remaining generic ERP records were imported,
and all relational/generic source counts were reconciled against
`pilot_school`. Private tenant/campus/year-scoped Storage buckets, aggregate ERP
dashboard counts and rate-limited client error monitoring are deployed.
