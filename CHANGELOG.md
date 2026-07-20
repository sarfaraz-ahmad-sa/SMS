# Changelog

## 1.1.0

- Removed production guest-role bypass
- Implemented Firebase session restoration
- Added tenant membership validation
- Added multiple roles, explicit permissions, and denied permissions
- Added multi-school switching
- Added permission-filtered dashboard and navigation
- Moved student and event data to nested tenant collections
- Replaced destructive student deletion with archiving
- Added secure profile display-name update
- Added Firestore, Storage, and index configuration
- Modernized Android Gradle and Flutter web bootstrap
- Replaced obsolete widget test with permission tests
- Added SaaS architecture and production documentation

## 2026-07-20 Windows setup hotfix

- Fixed nullable Firebase ID token future compile error.
- Exposed the subscription plan label directly from the `Subscription` model.
- Added Windows CMD tenant seed and legacy migration wrappers.
- Added a root Windows validation command and setup guide.
- Included generated `lib/firebase_options.dart` in the distributable archive.
