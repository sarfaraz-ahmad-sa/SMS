# Production Readiness Audit

Audit date: 2026-08-03

## Executive assessment

The project has a sound tenant-rooted Firestore model, default-deny rules,
role/permission checks, archive metadata, callable account administration, and
an extensive ERP catalog. It was not ready for public production at audit
start because generated dependencies and an archive were committed, App Check
was absent, high-impact records were client-writable, primary lists used broad
real-time listeners, dashboard reads fanned out into many queries, several
legacy screens contained local sample data, and operational capabilities such
as exports, backups, alerting, and restore drills remain incomplete.

No private key, service-account credential, or server access token was found in
the tracked application source. Firebase client configuration and API keys are
present; these identifiers are necessarily shipped in Firebase clients and are
not substitutes for authorization. They must be restricted to the correct
apps/domains and protected with App Check, Firestore Rules, and API restrictions.

## P0 — Critical security and integrity

- [x] Remove committed `functions/node_modules` (5,730 tracked files),
  `SMS.zip`, local build output, and generated local environment output.
- [x] Ignore dependency trees, archives, environment files, signing material,
  service-account files, and platform Firebase config generated locally.
- [x] Activate Firebase App Check in Flutter (reCAPTCHA v3, Play Integrity,
  App Attest/DeviceCheck; debug providers for local mobile builds).
- [x] Require valid App Check tokens on every callable Cloud Function.
- [x] Deny direct Firestore create/update access to payments, refunds, payroll,
  payslips, accounting records, and exam results.
- [x] Route those mutations through an authenticated, tenant-authorized Cloud
  Function transaction with server timestamps and append-only audit records.
- [x] Validate unique business identifiers for receipts, refunds, payroll
  periods, payslips, accounts, journals, bank accounts, expenses, and results.
- [x] Enforce basic positive-amount, balanced-journal, and protected final-state
  transition checks.
- [x] Make approval decisions transactional, prevent self-approval, annotate the
  target record, and write the audit event atomically.
- [ ] Add domain-specific idempotency keys and ledger/invoice atomic posting for
  payment gateway callbacks and refunds before accepting external money.
- [ ] Add maker-checker policies per workflow and require the matching approved
  request before payroll disbursement, refund payment, journal posting, or result
  publication.
- [ ] Add Firebase Emulator authorization tests for every role and sensitive
  collection. The repository currently has unit tests but no executable rules
  test harness.

Deployment prerequisites: register all apps in Firebase App Check, configure
the web site key, deploy Functions and Rules, observe App Check metrics, then
enable enforcement for Firestore, Authentication, Storage, and Functions in
the Firebase console. Rotate any credential that may have existed in older Git
history; deleting a current file does not remove it from history.

## P1 — Read cost, query scope, and concurrency

- [x] Apply `isArchived`, active campus, and active academic-year filters in the
  shared Firestore query builder (tenant scope is enforced by document path).
- [x] Reduce the generic ERP listener ceiling from 500 to 100 records.
- [x] Add per-campus/per-year dashboard summary documents maintained by a
  Firestore write trigger, plus an audited callable rebuild for existing data.
- [x] Make dashboard metric services prefer the one summary document, retaining
  a compatibility fallback until every tenant has been backfilled.
- [x] Replace the primary ERP list listener with cursor-based, one-shot pages
  (`orderBy`, `limit`, `startAfterDocument`), explicit refresh, and load-more.
- [ ] Add query-driven status/search filters; current text filtering applies only
  to the loaded page.
- [ ] Replace listeners that do not require live collaboration (account lists,
  approvals, usage, events) with cached one-shot reads and user-triggered refresh.
- [ ] Add composite indexes for every supported campus/year/personal-scope query
  and run index validation against the Emulator Suite.
- [ ] Cache session user/membership/tenant documents to eliminate repeated reads
  during tenant switching and route changes.
- [ ] Convert staff quota checks from collection scans to transactionally
  maintained counters; the current function scans active members.

Before enabling scoped queries for an existing tenant, backfill `campusId`,
`academicYearId`, `isArchived`, and `updatedAt` on legacy records. Firestore
correctly excludes documents missing an equality-filtered field.

## P1 — Data completeness

- [x] Replace the legacy Teacher, HR, Inventory, and Accounting in-memory screens
  with compatibility routes to the tenant Firestore ERP entities/modules.
- [x] Replace the legacy hardcoded Reports screen with the tenant Firestore
  Reports module.
- [x] Add a tenant/campus/year-scoped daily diary workflow with student and
  guardian personal-record access controls.
- [ ] Add a platform-operator console for provisioning and supervising tenants.
  Existing multi-school switching is limited to tenants assigned to the signed-in
  user and deliberately does not grant cross-tenant access.
- [ ] Remove the unauthenticated local demo path from production builds using a
  compile-time feature flag; demo records remain extensive in `erp_catalog.dart`.
- [ ] Replace remaining local data in Fees, Leave Apply, and Exam Result legacy
  screens or remove those unreachable compatibility screens.
- [ ] Add migration tests to prove every catalog field maps to the deployed
  Firestore schema and every collection has an entitlement/rules mapping.

## P2 — Reports and operations

- [ ] Implement report jobs in the backend with bounded queries and role checks.
- [ ] Implement CSV exports with spreadsheet-injection escaping and UTF-8 BOM
  where required; implement server-generated PDFs with tenant branding.
- [ ] Store export artifacts in protected Cloud Storage with short-lived signed
  URLs, retention policies, job status, and audit events.
- [ ] Configure scheduled Firestore/Storage backups, encryption, retention,
  cross-project or cross-region copies, and documented restore drills/RPO/RTO.
- [ ] Add Crashlytics or an approved web error reporter, Cloud Logging structured
  fields, Error Reporting, uptime checks, function latency/error alerts, and
  dead-letter handling for retried jobs.
- [ ] Configure Google Cloud budgets and billing alerts at 50/75/90/100%, plus
  Firestore read/write, Functions invocation, Storage egress, SMS, and email
  operational thresholds. Billing alerts notify; they do not cap spending.
- [ ] Standardize user-safe errors and correlation IDs across Flutter and
  Functions while keeping sensitive server details out of client messages.

## P2 — Flutter Web and delivery

- [x] Require the App Check web key in release builds and pass it from Vercel's
  encrypted project environment.
- [x] Avoid `git pull` in Vercel builds and shallow-clone Flutter only when the
  cached SDK is absent.
- [ ] Pin the Flutter SDK in CI instead of tracking mutable `stable`.
- [ ] Split or lazy-load infrequently used modules, measure with
  `flutter build web --analyze-size`, and establish a bundle budget.
- [ ] Remove or transcode the approximately 10 MB `SMS App.gif`; it dominates
  the asset payload. Verify which screenshot/demo assets are still referenced.
- [ ] Replace legacy Flare/GIF animations, reduce repaint areas, honor reduced
  motion, and avoid animation controllers in list rows.
- [ ] Introduce module-scoped repositories/state instead of global singleton
  rebuilds, then add loading/error/empty states and cancellation tests.
- [ ] Add immutable caching headers for hashed assets, security headers, preview
  deployment checks, smoke tests, and a rollback procedure.

## Verification baseline

At audit start, all 20 Flutter unit tests and all 4 Functions unit tests passed.
`flutter analyze` reported 253 style/info findings and no compile errors; the
non-zero analyzer status is caused by lint severity. Security rules were read
and reviewed statically but still require Emulator Suite tests before release.

After the first remediation slice, the same 20 Flutter tests and 4 Functions
tests pass, Functions load successfully, and Firestore Rules compile in the
local emulator. `npm audit --omit=dev` still reports seven moderate findings in
the current Firebase Admin transitive Google Cloud Storage/`uuid` tree; no safe
direct upgrade or override is available, so this must be monitored upstream
rather than force-downgrading Firebase Admin.

## Live deployment status (2026-08-03)

Firestore Rules were deployed to `school-management-app-46a07` with the
dashboard-summary read authorization, resolving the reported permission-denied
path after the client refreshes or signs in again. Cloud Functions could not be
deployed because the project is not on the Blaze billing plan; the Firebase CLI
could not enable Cloud Build and Artifact Registry. Until Blaze is enabled and
the Functions are deployed/backfilled, the dashboard uses bounded aggregate
fallback queries and high-integrity financial/result writes cannot safely be
made backend-only in the live rules without breaking the currently deployed
client. The repository rules already contain that stricter target state and
must be deployed together with the Functions release.
