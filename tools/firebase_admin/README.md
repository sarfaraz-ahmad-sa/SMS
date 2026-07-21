# Firebase Admin Tools

Run these tools only from a trusted administrator workstation. Never add the service-account JSON to this repository.

## Install

```bat
cd /d C:\SMS\tools\firebase_admin
npm install
set "GOOGLE_APPLICATION_CREDENTIALS=C:\secure\firebase-service-account.json"
```

## Create the first school and owner

```bat
seed-tenant.cmd
```

## Seed enterprise master data

```bat
seed-enterprise-data.cmd
```

This creates safe starter records for campus, academic year, departments, classes, sections, subjects, grading, fee structure, chart of accounts, announcement, feature flag and retention policy.

## Migrate old flat collections

```bat
migrate-flat.cmd
```

Run the migration in dry-run mode first. Admin SDK bypasses Firestore rules, so credentials must be tightly controlled and actions must be audited.
