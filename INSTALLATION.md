# Installation

## Local setup

Install Flutter 3.44.9, run `flutter doctor -v`, then `flutter pub get` and `flutter test`. Use Node 22 only if developing Firebase compatibility services (`npm ci --prefix functions`; `npm ci --prefix tools/firebase_admin`). Deno is needed to check Supabase functions. No seller account is required or included. Legacy Firebase admin migration utilities are workspace-only and omitted from the screened candidate; its supported default is Supabase.

Copy `config/brand.example.json` to `config/local.json` (ignored). Add public client settings:

```json
{
  "APP_NAME": "School Workspace",
  "COMPANY_NAME": "Example Academy",
  "SUPABASE_URL": "https://your-project-ref.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "your-public-client-key",
  "SUPABASE_AUTH_REDIRECT_URL": "https://your-app.example",
  "ENABLE_SUPABASE_PRIMARY": "true"
}
```

Merge desired branding fields from the example. Public configuration is embedded in the client; never add database passwords, service-role keys, mail credentials or signing secrets. `.env` is not automatically loaded. Use `--dart-define-from-file=config/local.json` consistently for run/build.

## Supabase backend

Use a new development project, not an existing customer database. Apply every file in `supabase/migrations` in filename order, including migration 020. Use the Supabase CLI migration workflow or SQL editor on the dedicated project. The repository does not include a initialized local CLI config; `supabase init` and Docker are needed for local CLI development. Review every migration before applying it. Migrations create tables, RLS helpers, RPCs, private buckets and job records; job execution workers are not included.

Deploy `school-accounts`, `platform-onboarding`, and `request-school-access` Edge Functions to that same project. They use server-provided SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY. Keep server secrets in the backend environment. Check JWT verification settings against the project's key type and confirm the function's `auth.getUser` authorization path. Never disable authorization to bypass an error.

Configure Auth site URL, allowed redirect origins and email delivery. Establish the first platform operator through the Supabase administrative console: create an Auth user, corresponding profile, and an active tenant membership with `superAdmin`, explicit permissions and a valid tenant. See schema 001 and provisioning migration 018. This is deliberate operator setup, not a shipped privileged login. Test onboarding on an empty sandbox before inviting users.

Run all six `supabase/tests/*.sql` with a privileged test connection and stop on the first SQL error. These fixtures use transactions and rollback, but must still run only on an isolated test database. Example after setting a private connection environment variable locally:

```sh
for test_file in supabase/tests/*.sql; do
  psql "$TEST_DATABASE_URL" -v ON_ERROR_STOP=1 -f "$test_file" || exit 1
done
```

Protect shell history/logs; never paste the variable's value. Do not claim RLS verified until these and the manual two-school checks pass.

## Web

```sh
flutter run -d chrome --dart-define-from-file=config/local.json
flutter build web --release --dart-define-from-file=config/local.json
```

Host `build/web` on HTTPS with SPA fallback and Auth redirects matching the final domain. `vercel.json` and `scripts/vercel_build.sh` are supplied as optional configuration; the script requires buyer public backend settings and pins Flutter 3.44.9 by default. Set `BRAND_CONFIG_FILE` to a public branding JSON file when using it. Nothing is deployed by the preparation scripts.

## Android

Set your permanent applicationId/namespace in `android/app/build.gradle`; align the Kotlin package/path in MainActivity. Install Java 17 and SDK 36. Regenerate missing Gradle wrapper scripts with the supplied wrapper repair instructions or your installed Gradle 8.13. Run:

```sh
flutter build apk --debug --dart-define-from-file=config/local.json
flutter build appbundle --release --dart-define-from-file=config/local.json
```

Release requires your own protected keystore and ignored `android/key.properties` (storeFile, storePassword, keyAlias, keyPassword). Do not use debug signing for a commercial release.

## iOS

Select your bundle identifier, team and display name in Xcode. Install pods, then build:

```sh
flutter build ios --no-codesign --dart-define-from-file=config/local.json
flutter build ipa --release --dart-define-from-file=config/local.json
```

The IPA requires your Apple membership, certificates and profiles. Replace launcher artwork after rights review. The default Supabase build does not require Firebase plist. To enable Firebase compatibility, add your own GoogleService-Info.plist to Runner resources in Xcode and configure Firebase apps, rules, functions and App Check. No seller plist is distributed.

## Troubleshooting

- Startup configuration screen: supply both public Supabase settings; empty defaults intentionally fail closed.
- Permission denied: inspect active membership, role permissions, campus/year, student/guardian links, deployed migration version and function deployment. Never relax RLS as a workaround.
- Login/recovery: verify email setup, redirect allowlist and expired links. Test logout followed by Back/refresh.
- CSV: browser download only; mobile export is currently unsupported.
- Node warnings: use Node 22. Moderate transitive advisories require review; do not force major dependency changes without tests.
- Missing icons in screened package: unverified artwork is withheld; supply licensed replacements listed in the package manifest.
