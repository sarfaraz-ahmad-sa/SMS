# CARTZ Link School ERP SaaS 2.4.1+8

## Release scope

This release consolidates the multi-tenant SaaS shell, role-secured ERP workflows and complete school-account lifecycle.

### Account lifecycle

- Administrator-created Email/Password accounts.
- Strong temporary passwords or Firebase email setup links.
- Mandatory first-login password replacement.
- Recent-authentication verification before setup completion.
- Student, parent and teacher ERP identity linking.
- Parent account requires at least one linked child.
- Role and campus access editing.
- Temporary-password reset, setup-email resend, suspension and reactivation.
- Student/parent portal accounts excluded from paid staff-seat quotas.
- Account actions recorded in tenant audit logs.

### Access control

- Server-derived role permissions.
- Tenant, campus and academic-year context.
- Plan entitlements enforced in navigation, global search, direct routes and Firestore rules.
- Personal-scope rules for student and guardian data.
- Trusted creation/archive operations for metered students and campuses.
- Default-deny Firestore coverage for all ERP collections.

### Product interface

- Tenant-branded Material 3 theme.
- Complete light and dark themes.
- Permanent desktop sidebar, tablet NavigationRail and mobile bottom navigation/drawer.
- Role-aware dashboard and quick access.
- SaaS Control Center, onboarding, approvals and account directory.
- Twenty-four modules and 105 tenant-scoped workflows.

## Validation performed in the delivery environment

- Firebase Functions tests: 4/4 passed.
- Firebase Functions and Admin scripts Node syntax: passed.
- Dart lexical/delimiter validation: passed.
- Missing relative Dart imports: 0.
- ERP modules: 24.
- ERP workflows: 105.
- Firestore rules collection coverage: 105/105.
- Entitlement module mapping: complete.
- JSON validation: passed.

Flutter SDK is not installed in the delivery container. Run the commands in `DELIVERY_NOTES.md` on the development Mac before deploying.

## External configuration boundary

Payment, SMS, WhatsApp, transactional email, push notifications, GPS, biometric devices, bank payroll, signed certificates, custom domains and backups require the organisation's provider credentials and production callback configuration. See `docs/PRODUCTION_READINESS_AND_INTEGRATIONS.md`.


## 2.4.1 UI navigation files

- `lib/Widgets/saas_scaffold.dart` — desktop/tablet/mobile adaptive shell.
- `lib/Widgets/MainDrawer.dart` — expanded and compact permission-aware navigation.
- `lib/services/navigation_preferences.dart` — persistent in-app sidebar preference.
- `lib/Widgets/FeatureCard.dart` — responsive dashboard shortcut interaction.
- `lib/theme/app_theme.dart` — navigation, scrollbar and action styling.
