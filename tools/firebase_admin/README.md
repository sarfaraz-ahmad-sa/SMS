# Trusted Firebase Admin Tools

These scripts require Application Default Credentials. Never place a service-account JSON file in the Flutter application or commit it to Git.

## Install

```bash
cd tools/firebase_admin
npm install
```

Authenticate with one of these trusted methods:

```bash
gcloud auth application-default login
```

or set `GOOGLE_APPLICATION_CREDENTIALS` to a service-account file stored outside the repository.

## Seed first school and owner

```bash
FIREBASE_PROJECT_ID=school-management-app-46a07 \
TENANT_ID=school_demo \
TENANT_NAME="Demo Public School" \
TENANT_CODE=DPS \
USER_EMAIL=owner@example.com \
USER_NAME="School Owner" \
USER_PASSWORD='replace-with-a-strong-temporary-password' \
npm run seed:tenant
```

Optional variables:

```text
ROLES=schoolOwner
CAMPUS_IDS=main-campus
ACADEMIC_YEAR_ID=2026-2027
TIMEZONE=Asia/Karachi
CURRENCY=PKR
```

## Migrate old global students/events

First run is a dry run:

```bash
FIREBASE_PROJECT_ID=school-management-app-46a07 \
TENANT_ID=school_demo \
ACTOR_UID=<trusted-admin-firebase-uid> \
npm run migrate:flat
```

To write the tenant copies:

```bash
DRY_RUN=false npm run migrate:flat
```

Only after backup and verification, optionally remove source documents:

```bash
DRY_RUN=false DELETE_SOURCE=true npm run migrate:flat
```
