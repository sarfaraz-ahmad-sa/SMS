# SEEF School Management SaaS

Production-oriented Flutter + Firebase School ERP foundation for schools, colleges and education groups.

## Current build

- **24 role-authorized ERP modules**
- **105 tenant-scoped operational workflows**
- Responsive desktop, tablet and mobile interface
- Firebase email/password and Google authentication
- Multi-school membership and school switching
- 16 school/platform roles with explicit and denied permissions
- Campus and academic-year context
- Live Firestore data with an in-memory full ERP demo
- Search, status filters, create, update, details and archive on every configured workflow
- Default-deny Firestore and Storage rules
- Firebase Admin onboarding and enterprise master-data seed tools
- Tenant-branded light/dark themes and role-preview mode in the demo
- Responsive SaaS application shell: desktop sidebar, tablet rail and mobile navigation
- SaaS Control Center with plan entitlements, usage quotas and production controls
- Guided tenant onboarding for school profile, academics, fees, users and launch readiness
- Feature-gated Firestore access, live approval inbox and trusted Cloud Functions for usage refresh and approvals
- Backend-enforced student, campus and paid staff-seat quotas with immutable audit events
- Student and parent portal accounts excluded from staff-seat billing limits

Full inventory: [`docs/ENTERPRISE_MODULES.md`](docs/ENTERPRISE_MODULES.md)

SaaS foundation: [`docs/SAAS_FOUNDATION.md`](docs/SAAS_FOUNDATION.md)

Production readiness and provider boundaries: [`docs/PRODUCTION_READINESS_AND_INTEGRATIONS.md`](docs/PRODUCTION_READINESS_AND_INTEGRATIONS.md)

## Run immediately on Windows

```bat
cd /d C:\SMS
start-demo.cmd
```

On the login screen select **Open Full ERP Demo**. The button exists only in Flutter debug builds.

## Connect the live Firebase project

Run from `C:\SMS`, not from `tools\firebase_admin`:

```bat
flutterfire configure
flutter pub get
firebase deploy --only functions,firestore:rules,firestore:indexes,storage
```

Enable Email/Password and Google in Firebase Authentication before testing real login.

## Create role-secured school accounts

1. Enable **Email/Password** in Firebase Authentication.
2. Sign in as the school owner, principal, vice principal, IT administrator,
   or an authorized administrator with `users.manage`.
3. Open **School Accounts** from the navigation.
4. Enter the user's name, email, role, campus scope and account setup method.
5. For student, parent and teacher accounts, select the matching ERP profile:
   - Student → an existing `students/{recordId}` record
   - Parent → an existing `guardians/{recordId}` record with student links
   - Teacher/Class Teacher → an existing `teachers/{recordId}` record
6. Choose either a generated/entered strong temporary password or an email
   setup link. Temporary passwords require at least 10 characters with uppercase,
   lowercase, number and special character.
7. Create the account and securely share the generated credentials when that
   setup method is selected.

The trusted callable function creates or reuses the Firebase Authentication
identity, creates the global profile and tenant membership, derives effective
permissions from the selected role, links the ERP identity, applies campus
scope and writes an immutable audit event. New temporary-password users must
change their password on first login. Student and parent portal records are
restricted by Firestore rules to the linked student identity; hiding a menu is
not treated as security.

Administrators can later edit role/campus access, reset a temporary password,
resend setup email, suspend or reactivate an account. For an Authentication
identity shared by multiple schools, tenant administrators cannot overwrite the
global password and accidentally break access to another school.

Do not create Authentication users only from the Firebase console. A usable
school login also requires the global user profile, tenant membership and, for
portal roles, the linked ERP identity. Full flow: [`docs/ACCOUNT_ACCESS_AND_PORTALS.md`](docs/ACCOUNT_ACCESS_AND_PORTALS.md).

## Create the first real school

The trusted admin scripts require a Firebase service-account JSON stored outside the repository.

```bat
cd /d C:\SMS\tools\firebase_admin
set "GOOGLE_APPLICATION_CREDENTIALS=C:\secure\firebase-service-account.json"
seed-tenant.cmd
seed-enterprise-data.cmd
```

The scripts create the first school owner membership and seed safe master records. Tenant creation, user role elevation and platform administration are intentionally blocked from the Flutter client.

For an existing Firebase installation, deploy the new Functions and rules first, then backfill subscription defaults and live usage counters:

```bat
cd /d C:\SMS\tools\firebase_admin
set "GOOGLE_APPLICATION_CREDENTIALS=C:\secure\firebase-service-account.json"
set "FIREBASE_PROJECT_ID=your-project-id"
migrate-saas-foundation.cmd
```

The migration defaults legacy schools without a plan to `enterprise` so existing users are not unexpectedly locked out. Review and assign the correct plan after migration.

## Data architecture

```text
Firebase Authentication
        |
users/{uid}
        |
tenants/{tenantId}/members/{uid}
        |
tenants/{tenantId}/{erpCollection}/{recordId}
```

Every operational record carries tenant, campus, academic-year, actor, timestamps and archive metadata.

## Production boundary

This repository provides the complete responsive ERP interface, tenant data model and authorization foundation. Before accepting live money or publishing legally significant records, connect a trusted Laravel API or Firebase Cloud Functions for:

- payment callbacks, idempotency, settlement and reconciliation;
- double-entry posting, reversals and period close;
- payroll approval and bank disbursement;
- final examination locking and result publication;
- privileged user provisioning and role changes;
- signed certificates and public verification;
- immutable audit events, backups and retention enforcement;
- external SMS, WhatsApp, email, GPS, biometric and SSO credentials.

Flutter permission checks shape the UI; Firestore rules and the trusted backend remain the authorization boundaries.

## Validation commands

```bat
cd /d C:\SMS
flutter analyze
flutter test
flutter build web --release --no-wasm-dry-run
```

Do not commit `.env`, service-account JSON, private API keys, signing keystores or database credentials.


## Responsive interface

- **Web ≥ 1320px:** expanded labeled sidebar.
- **Web 1024–1319px:** compact icon sidebar with module popovers.
- **Tablet 720–1023px:** adaptive NavigationRail plus full module drawer.
- **Mobile < 720px:** bottom navigation plus complete Modules drawer.

The layout follows the current browser width automatically and supports manual sidebar collapse/expand on desktop.
