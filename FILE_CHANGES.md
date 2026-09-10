# File change record

Local deployment files removed from the Git index remain on disk and are ignored. No commit was created. Generated dependency/build output is ignored and excluded from this source-change list.

| File | Reason |
| --- | --- |
| `.env.example` | Clarifies public branding build configuration; placeholders only. |
| `.gitignore` | Excludes private deployment/signing/configuration and release output. |
| `.vercel/README.txt` | Removed from Git index; ignored local copy retained. |
| `.vercel/project.json` | Removed deployment association from Git index; ignored local copy retained. |
| `AUDIT_BEFORE_CHANGES.md` | Buyer documentation / audit / evidence / scope record; historical changelog retained where applicable. |
| `CHANGELOG.md` | Buyer documentation / audit / evidence / scope record; historical changelog retained where applicable. |
| `COMMERCIAL_LICENSE_DRAFT.md` | Buyer documentation / audit / evidence / scope record; historical changelog retained where applicable. |
| `DEMO_ACCOUNTS.md` | Buyer documentation / audit / evidence / scope record; historical changelog retained where applicable. |
| `FEATURES.md` | Buyer documentation / audit / evidence / scope record; historical changelog retained where applicable. |
| `FILE_CHANGES.md` | Buyer documentation / audit / evidence / scope record; historical changelog retained where applicable. |
| `INSTALLATION.md` | Buyer documentation / audit / evidence / scope record; historical changelog retained where applicable. |
| `KNOWN_ISSUES.md` | Buyer documentation / audit / evidence / scope record; historical changelog retained where applicable. |
| `README.md` | Buyer documentation / audit / evidence / scope record; historical changelog retained where applicable. |
| `SALE_READINESS_REPORT.md` | Buyer documentation / audit / evidence / scope record; historical changelog retained where applicable. |
| `STATIC_VALIDATION.txt` | Fresh static check report; no historical result reused. |
| `TEST_RESULTS.md` | Buyer documentation / audit / evidence / scope record; historical changelog retained where applicable. |
| `THIRD_PARTY_REVIEW.md` | Buyer documentation / audit / evidence / scope record; historical changelog retained where applicable. |
| `WHITE_LABEL_GUIDE.md` | Buyer documentation / audit / evidence / scope record; historical changelog retained where applicable. |
| `android/app/src/main/AndroidManifest.xml` | Neutral application display label. |
| `assets/school-mark.svg` | New original geometric school placeholder; no third-party artwork. |
| `config/brand.example.json` | Public placeholder/default configuration for all branding keys. |
| `functions/package-lock.json` | Compatible advisory fixes and neutral package identity. |
| `functions/package.json` | Neutral package identity; no dependency major-version change. |
| `ios/Flutter/AppFrameworkInfo.plist` | Automatic Flutter 3.44.9 compatibility migration during native build verification. |
| `ios/Podfile` | Removes nonexistent RunnerTests CocoaPods target. |
| `ios/Podfile.lock` | Automatic Flutter 3.44.9 compatibility migration during native build verification. |
| `ios/Runner.xcodeproj/project.pbxproj` | Removes seller plist resource and records SDK-required iOS project migration. |
| `ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata` | Automatic Flutter 3.44.9 compatibility migration during native build verification. |
| `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` | Automatic Flutter 3.44.9 compatibility migration during native build verification. |
| `ios/Runner.xcworkspace/contents.xcworkspacedata` | Automatic Flutter 3.44.9 compatibility migration during native build verification. |
| `ios/Runner/AppDelegate.swift` | Automatic Flutter 3.44.9 compatibility migration during native build verification. |
| `ios/Runner/GoogleService-Info.plist` | Removed seller Firebase configuration from Git index; ignored local copy retained. |
| `ios/Runner/Info.plist` | Central public display label and SDK-required iOS scene configuration. |
| `lib/Screens/Enterprise/ErpEntityListScreen.dart` | Uses active tenant currency and configured date formatter. |
| `lib/Screens/Enterprise/SchoolProfileScreen.dart` | Uses central fallback currency/timezone. |
| `lib/Screens/FirstLoginPasswordScreen.dart` | Suppresses raw authentication exception details in debug logs. |
| `lib/Screens/LoginPage.dart` | Central branding, fictional demo label/defaults and safer debug log. |
| `lib/Screens/Saas/platform_school_onboarding_screen.dart` | Neutralizes example school code. |
| `lib/Screens/Settings.dart` | Displays central support details and corrects backend terminology. |
| `lib/Screens/SplashScreen.dart` | Uses central neutral application/school branding while retaining layout. |
| `lib/Screens/home.dart` | Uses central neutral application/school branding while retaining layout. |
| `lib/Widgets/MainDrawer.dart` | Uses central neutral application/school branding while retaining layout. |
| `lib/Widgets/UserDetailCard.dart` | Uses central neutral application/school branding while retaining layout. |
| `lib/Widgets/saas_scaffold.dart` | Uses central neutral application/school branding while retaining layout. |
| `lib/Widgets/school_brand.dart` | Uses central neutral application/school branding while retaining layout. |
| `lib/Widgets/solid_auth_shell.dart` | Uses central neutral application/school branding while retaining layout. |
| `lib/config/backend_config.dart` | Rejects recognizable server secret keys in public client configuration. |
| `lib/config/brand_config.dart` | Centralizes public branding and date/currency/timezone defaults. |
| `lib/config/supabase_public_config.dart` | Removes seller endpoint and bundled client key defaults. |
| `lib/core/erp/erp_catalog.dart` | Fictionalizes sample personal/contact labels and centralizes currency default. |
| `lib/main.dart` | Uses central neutral application/school branding while retaining layout. |
| `lib/services/csv_encoding.dart` | Neutralizes formula-bearing CSV cells including record identifiers. |
| `lib/services/models/tenant.dart` | Uses central defaults without changing persisted tenant values. |
| `lib/services/platform_onboarding_service.dart` | Uses central currency/timezone defaults. |
| `lib/services/record_export_service_web.dart` | Uses shared safe encoding for all cells. |
| `lib/theme/app_theme.dart` | Uses central primary/secondary color defaults. |
| `pubspec.yaml` | Neutral description and explicit newly authored SVG asset; old GIF/Flare no longer bundled. |
| `scripts/vercel_build.sh` | Requires buyer backend settings, pins Flutter and accepts branding file. |
| `start-demo.cmd` | Requires explicit sandbox JSON instead of misleading default developer-login build. |
| `supabase/functions/platform-onboarding/index.ts` | Pins SDK and corrects Supabase client type annotation. |
| `supabase/functions/request-school-access/index.ts` | Pins SDK version for reproducible direct dependency. |
| `supabase/functions/school-accounts/index.ts` | Guards existing account privilege/self/shared reset paths; pins SDK, fixes types and hides internal errors. |
| `supabase/migrations/202609100020_active_portal_membership.sql` | Adds active membership guard for linked portal access; not deployed. |
| `supabase/tests/role_access_matrix.sql` | Adds suspended student/parent denial regression assertions. |
| `test/backend_config_test.dart` | Asserts seller backend is absent and missing configuration fails closed. |
| `test/csv_encoding_test.dart` | Regression tests for formula prefixes, control whitespace and CSV quoting. |
| `tools/apply_brand.py` | Synchronizes platform labels from central public JSON. |
| `tools/firebase_admin/migrate-flat.cmd` | Neutralizes seller-specific seed/script display labels. |
| `tools/firebase_admin/migrate-saas-foundation.cmd` | Neutralizes seller-specific seed/script display labels. |
| `tools/firebase_admin/package-lock.json` | Compatible dependency audit updates. |
| `tools/firebase_admin/seed-enterprise-data.cmd` | Neutralizes seller-specific seed/script display labels. |
| `tools/firebase_admin/seed-enterprise-data.mjs` | Neutralizes seller-specific seed/script display labels. |
| `tools/firebase_admin/seed-tenant.cmd` | Neutralizes seller-specific seed/script display labels. |
| `tools/prepare_release.py` | Creates local allowlisted candidate, screens sensitive patterns and emits hashes. |
| `tools/test_prepare_release.py` | Tests private-path exclusion and high-confidence secret detection. |
| `tools/validate_project.py` | Updates stale branded-asset and backend-build expectations. |
| `web/icons/school-mark.svg` | Web copy of new original geometric placeholder. |
| `web/index.html` | Neutral platform metadata and new placeholder asset references. |
| `web/manifest.json` | Neutral application identity and new SVG icon; unverified PNG references removed. |
