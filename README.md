# CARTZ Link School Management SaaS

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
- Light/dark themes and role-preview mode in the demo

Full inventory: [`docs/ENTERPRISE_MODULES.md`](docs/ENTERPRISE_MODULES.md)

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
firebase deploy --only firestore:rules,firestore:indexes,storage
```

Enable Email/Password and Google in Firebase Authentication before testing real login.

## Create the first real school

The trusted admin scripts require a Firebase service-account JSON stored outside the repository.

```bat
cd /d C:\SMS\tools\firebase_admin
set "GOOGLE_APPLICATION_CREDENTIALS=C:\secure\firebase-service-account.json"
seed-tenant.cmd
seed-enterprise-data.cmd
```

The scripts create the first school owner membership and seed safe master records. Tenant creation, user role elevation and platform administration are intentionally blocked from the Flutter client.

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
flutter build web --release
```

Do not commit `.env`, service-account JSON, private API keys, signing keystores or database credentials.
