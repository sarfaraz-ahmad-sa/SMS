# School Workspace

Flutter school-management source code for buyer-owned deployments. **Release candidate; not yet approved for commercial delivery.** See `SALE_READINESS_REPORT.md` and `KNOWN_ISSUES.md` before quoting capabilities to customers.

The application contains 24 ERP modules and 106 entity definitions, school-scoped sessions, role navigation, forms, account administration, and Supabase persistence. Record screens are not equivalent to complete automated business workflows. `FEATURES.md` distinguishes tested code from unverified integrations.

## Stack and requirements

- Flutter 3.44.9 / Dart 3.12.2 used for this preparation; package constraint Dart >=3.3 <4.
- Supabase Auth, PostgreSQL RLS, Storage and Deno Edge Functions are the default backend.
- Firebase Auth, Firestore, Storage rules and Node 22 Cloud Functions remain optional compatibility code. No Laravel server exists here.
- Android: Java 17, Android SDK 36, Gradle 8.13; iOS: macOS, Xcode, CocoaPods and buyer signing identities.
- Node 22 for optional Firebase tools. Lockfiles are supplied; dependencies are installed by the buyer.

## Start

1. Read `INSTALLATION.md`; provision a separate, empty backend.
2. Copy `config/brand.example.json` to ignored `config/local.json` and add your public `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, and recovery redirect.
3. Run `flutter pub get`, then `flutter run -d chrome --dart-define-from-file=config/local.json`.

There is no bundled seller backend, master password or pre-created account. `.env.example` documents variables; Flutter does not automatically load `.env`.

## Verification and documentation

Read `FEATURES.md`, `DEMO_ACCOUNTS.md`, `WHITE_LABEL_GUIDE.md`, `TEST_RESULTS.md`, and `COMMERCIAL_LICENSE_DRAFT.md`. Existing historical reports describe earlier revisions and are not current acceptance evidence.

## Screenshots

No customer screenshots are supplied. Capture only the fictional sandbox: desktop dashboard, mobile dashboard, student list/form, attendance, fees, role-specific portal, branding settings and permission denial. See the report for a demo-video sequence.

## License

The existing `LICENSE` remains unchanged. The commercial draft does not replace existing MIT permissions. Ownership and asset rights must be resolved before selling under restrictive terms.
