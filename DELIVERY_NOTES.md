# v2.4.2 Web Runtime Patch

This release fixes startup-time SessionState notifications and the missing Google web client-ID assertion.

# SEEF School ERP SaaS — Delivery Notes

## Delivered in version 2.4.2+9

- Secure administrator-created accounts using a temporary password or email setup link.
- Mandatory first-login password change with strong-password validation and recent-authentication enforcement.
- Student, parent and teacher account linking to existing ERP master profiles.
- Personal-scope Firestore access for student attendance, fees, results, library, transport, certificates and welfare records.
- Guardian-to-child relationship propagation and a trusted backfill migration for existing records.
- Account directory with role/campus editing, password reset, setup-email resend, suspension and reactivation.
- Account-level persisted system/light/dark appearance and comprehensive enterprise dark theme.
- Plan entitlement enforcement in navigation, global search, direct module routes, entity routes and Firestore rules.

- Adaptive authenticated application shell for desktop, tablet and mobile.
- Tenant logo and brand-colour theming with light/dark mode.
- Campus and academic-year working context.
- SaaS Control Center with subscription lifecycle, feature entitlements and live quota usage.
- Guided school onboarding and launch-readiness checklist.
- Approval inbox with trusted approve/reject Cloud Functions and immutable audit records.
- Backend-enforced student, campus and paid staff-user limits.
- Paid staff-seat quotas exclude student and parent portal accounts.
- Direct client bypass prevention for metered student/campus creation and archive operations.
- Trusted usage refresh and compatibility migration for existing tenants.
- Plan-based module visibility and Firestore collection entitlement checks.
- Standardized SEEF School ERP branding.
- Existing 24 modules and 105 tenant-scoped workflows retained and integrated.


### Responsive navigation and interface

- Web at 1024px and above uses a permanent side navigation.
- At 1320px and above the side navigation opens with labels by default.
- Between 1024px and 1319px it automatically uses a compact icon mode.
- The expand/collapse preference remains available while navigating between screens.
- Tablet uses an adaptive NavigationRail and a complete module drawer.
- Mobile uses bottom navigation for Dashboard, Search, Alerts and Modules.
- Campus, academic year and school switching remain accessible without crowding the mobile AppBar.
- Dashboard shortcut tiles automatically resize according to available width.

## Existing Firebase project upgrade

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release --no-wasm-dry-run
firebase deploy --only functions,firestore:rules,firestore:indexes,storage
```

Then migrate existing schools from the trusted admin workstation:

```bash
cd tools/firebase_admin
npm install
export GOOGLE_APPLICATION_CREDENTIALS=/secure/firebase-service-account.json
export FIREBASE_PROJECT_ID=your-project-id
export DEFAULT_SAAS_TIER=enterprise
npm run migrate:saas
```

`DEFAULT_SAAS_TIER=enterprise` avoids unexpectedly locking legacy schools. Review and assign the correct commercial plan after migration.

## Validation completed in the delivery environment

- Firebase Functions Node syntax: PASS
- Firebase Functions role tests: 4/4 PASS
- Dart delimiter/static validation: PASS
- Missing relative Dart imports: 0
- Dart import cycles: 0
- ERP catalog: 24 modules / 105 workflows
- Firestore rule collection coverage: 105/105
- JSON validation: PASS

Flutter and Firebase CLI are not installed in the delivery container. Run the Flutter and Firebase commands above on the development Mac before production deployment.

## External provider boundary

Payment settlement, bank disbursement, signed certificates, SMS/WhatsApp/email delivery, biometric/GPS devices and backups still require the organisation's provider credentials and callback configuration. The product now contains the integration records, entitlements, trusted backend boundaries and audit structure, but credentials are intentionally not embedded in source code.
