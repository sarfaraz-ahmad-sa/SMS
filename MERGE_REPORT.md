# Enterprise Merge Report

## Completed in this repository

- Removed production guest-role authentication bypass.
- Added Firebase email/password and Google sign-in flow with school membership validation.
- Added authenticated session restore on app start.
- Added multi-tenant school switching.
- Added multi-role users, explicit permissions, denied permissions, campus scope, and active academic-year context.
- Converted the dashboard and drawer to permission-based navigation.
- Moved student and event access to tenant-scoped Firestore subcollections.
- Added immutable archive flows instead of client hard deletion.
- Added default-deny Firestore and Storage rules.
- Added Firestore composite indexes.
- Added profile editing, password reset, and access-request handling.
- Fixed the Events screen duplicate-widget compile blocker.
- Removed unused and obsolete package dependencies.
- Removed the stale lockfile; `flutter pub get` will generate a clean lockfile for the installed Flutter SDK.
- Modernized Android Gradle plugin configuration and Flutter web bootstrap.
- Added model and permission tests.
- Added trusted Firebase Admin scripts to seed the first tenant and migrate legacy flat collections.
- Added Firebase data model, migration, Laravel handoff, architecture, and production checklist documentation.

## Validation performed here

- Parsed every Dart source and test file with a Dart syntax parser.
- Verified all relative imports resolve to existing files.
- Verified every imported third-party package is declared in `pubspec.yaml`.
- Checked tenant-scoped service paths and permission constants for consistency.

## Validation still required on a Flutter workstation

This execution environment does not include the Flutter SDK, Android SDK, Xcode, or Firebase Emulator Suite. Run:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run
firebase emulators:exec --only firestore,storage "flutter test"
```

Also perform Android, iOS, and web release builds before deployment.
