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
- [x] Provision private Supabase document/export/backup buckets; enforce
  tenant/campus/academic-year path scope, MIME/size limits, backend-only export
  writes and service-role-only backups.
- [ ] Configure scheduled Firestore/Storage backups, encryption, retention,
  cross-project or cross-region copies, and documented restore drills/RPO/RTO.
- [ ] Add Crashlytics or an approved web error reporter, Cloud Logging structured
  fields, Error Reporting, uptime checks, function latency/error alerts, and
  dead-letter handling for retried jobs.
- [x] Capture authenticated Flutter framework/platform errors in a rate-limited,
  tenant-linked Supabase error table without exposing direct client writes.
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
- [x] Remove the unused approximately 10 MB `SMS App.gif`; it dominated
  the asset payload. Verify which screenshot/demo assets are still referenced.
- [ ] Replace legacy Flare/GIF animations, reduce repaint areas, honor reduced
  motion, and avoid animation controllers in list rows.
- [ ] Introduce module-scoped repositories/state instead of global singleton
  rebuilds, then add loading/error/empty states and cancellation tests.
- [x] Add immutable caching headers for static assets, baseline security headers,
  and a Supabase-only Vercel production build configuration.
- [ ] Add preview
  deployment checks, smoke tests, and a rollback procedure.

## Verification baseline

At audit start, all 20 Flutter unit tests and all 4 Functions unit tests passed.
`flutter analyze` reported 253 style/info findings and no compile errors; the
non-zero analyzer status is caused by lint severity. Security rules were read
and reviewed statically but still require Emulator Suite tests before release.

After the Supabase cutover slice, all 32 Flutter tests pass and a release web
build completes successfully. `flutter analyze` has no compile errors; its
non-zero status is caused by 246 legacy style/info findings. Temporary build,
package and migration artifacts are removed from the workspace after
verification.

## Live deployment status (2026-08-03)

Supabase is now the default runtime. Migrations `001` through `011`, School
Accounts Edge Function, RLS, trusted finance/result RPCs, tenant profile RPC,
generic ERP storage, dashboard summaries, private Storage buckets and client
error monitoring are live. Firebase contained only 10 tenant documents; all
functional records were inventoried, imported and count-reconciled. Firebase
remains dormant only as rollback compatibility code until acceptance testing;
it is not initialized by the default build.

## Android-first delivery status (2026-08-03)

- [x] Build against and target Android 16 / API 36.
- [x] Upgrade Android Gradle Plugin to 8.11.1, Gradle to 8.13, and Kotlin to
  2.2.20; keep Java 17 and release resource/code shrinking enabled.
- [x] Produce and verify a debug APK from the shared Flutter codebase.
- [x] Fix the drawer Scrollbar ownership exception and mobile bottom
  navigation/dashboard text-scale overflows.
- [ ] Replace the placeholder `com.example.school_management` application ID
  with the organization's permanent reverse-domain ID, then register that exact
  ID as a new Firebase Android app and replace `google-services.json`.
- [ ] Create a protected upload keystore, configure `key.properties` outside
  Git, build a signed AAB, enroll Play App Signing, and test internal release.
- [ ] Register Android App Check debug tokens for development and configure Play
  Integrity for the release signing certificate before enforcement.

The School Accounts UI, profile linking, role delegation, quota checks, Auth
user creation, membership writes, password actions, and audit logging are
implemented. Live create/suspend/reset actions remain unavailable because the
project currently has no deployed Cloud Functions and cannot deploy them on the
Spark plan. This cannot safely be replaced with direct client-side Auth/admin
writes; enable Blaze and deploy Functions to activate the feature.
