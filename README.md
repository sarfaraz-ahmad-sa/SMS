# CARTZ Link School Management System

A Flutter + Firebase multi-tenant foundation for a School Management SaaS platform.

## What is implemented

- Firebase email/password and Google authentication
- Session restoration from Firebase Authentication
- School/tenant membership validation
- Multiple roles per user
- Explicit and denied permissions
- Role-based dashboard and navigation drawer
- Multiple-school account switching
- Tenant-scoped Firestore paths for students and events
- Student archiving instead of destructive deletion
- Firebase password reset and school-access request workflow
- Firestore and Storage security rules with default-deny behavior
- Material 3 responsive dashboard, dark mode, profile editing
- Modern Android Gradle Plugin DSL and Flutter web bootstrap

## Architecture

```text
Flutter application
        |
Firebase Authentication
        |
Firestore membership and tenant context
        |
tenants/{tenantId}/...
```

For the commercial ERP phase, Laravel/MySQL should become the authoritative transactional backend. Firebase can remain responsible for identity, push notifications, App Check, and selected realtime features.

## Required local setup

1. Install a current stable Flutter SDK and Java 17.
2. Install Firebase CLI and FlutterFire CLI.
3. Run:

```bash
flutter clean
flutter pub get
flutterfire configure
```

`flutterfire configure` must generate/update:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

4. Enable these Firebase Authentication providers:

- Email/Password
- Google

5. Deploy security rules and indexes:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

6. Create the first tenant, user profile, and membership using the trusted scripts in `tools/firebase_admin`, a Cloud Function, or the Laravel backend. Do not allow tenant creation or role assignment from the Flutter client.

## Firestore minimum records

### `users/{firebaseUid}`

```json
{
  "email": "owner@school.edu.pk",
  "displayName": "School Owner",
  "tenantIds": ["school_demo"],
  "activeTenantId": "school_demo",
  "isActive": true
}
```

### `tenants/school_demo`

```json
{
  "name": "Demo Public School",
  "code": "DPS",
  "timezone": "Asia/Karachi",
  "currency": "PKR",
  "isActive": true,
  "activeAcademicYearId": "2026-2027",
  "subscription": {
    "tier": "trial",
    "status": "trialing"
  }
}
```

### `tenants/school_demo/members/{firebaseUid}`

```json
{
  "status": "active",
  "isActive": true,
  "roles": ["schoolOwner"],
  "permissions": [],
  "deniedPermissions": [],
  "campusIds": ["main-campus"],
  "activeCampusId": "main-campus",
  "activeAcademicYearId": "2026-2027"
}
```

## Run

```bash
flutter run
```

Web:

```bash
flutter run -d chrome
```

Release web build:

```bash
flutter build web --release
```

## Important security notes

- Flutter permission checks only control presentation.
- Firestore rules are the current authorization boundary.
- When Laravel APIs are introduced, every API must independently validate tenant membership and permission.
- Never commit service-account keys, `.env` files, signing keystores, database passwords, or private API credentials.
- Replace Android debug signing before Play Store publication.

## Documents

- `SAAS_ARCHITECTURE.md`
- `MERGE_REPORT.md`
- `docs/FIRESTORE_DATA_MODEL.md`
- `docs/MIGRATION_GUIDE.md`
- `docs/FIRESTORE_RULES_TESTING.md`
- `docs/MODULE_STATUS.md`
- `docs/LARAVEL_HANDOFF.md`
- `docs/PRODUCTION_CHECKLIST.md`
- `tools/firebase_admin/README.md`
- `DEPLOY_VERCEL.md`
