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


## Migrate existing schools to the SaaS control plane

Deploy Functions and Firestore rules before running this command:

```bat
set "FIREBASE_PROJECT_ID=your-project-id"
set "DEFAULT_SAAS_TIER=enterprise"
migrate-saas-foundation.cmd
```

Set `TENANT_ID` to migrate one school only. Without it, all tenant documents are migrated. The script preserves existing plan settings, classifies memberships as `staff` or `portal`, calculates live students/paid-staff/campus usage and appends an audit event. Student and parent-only memberships are portal accounts and do not consume staff seats.

## Backfill student and parent portal relationships

Run this after deploying version 2.3 rules/functions so existing attendance, fee,
result, library, transport and welfare records receive trusted `studentRecordId`,
`authUid` and `guardianUids` fields.

Start with a dry run:

```bat
set "FIREBASE_PROJECT_ID=your-project-id"
set "TENANT_ID=your-school-id"
set "DRY_RUN=true"
npm run backfill:portal-links
```

Review the unresolved count, correct ambiguous student IDs/admission numbers, then apply:

```bat
set "DRY_RUN=false"
npm run backfill:portal-links
```
