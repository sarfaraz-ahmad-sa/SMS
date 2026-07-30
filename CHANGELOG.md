
## 2.4.1 - Production login reliability

- Added Firebase Web auth-state fallback when `UserCredential.user` is delayed.
- Forces a fresh ID token before tenant and membership reads.
- Added readable Firestore service, permission, and availability errors.
- Preserves existing tenant, role, subscription, and first-login security checks.
# Changelog

## 2.4.1+8 — Adaptive Navigation and UI Polish

- Added a persistent collapsible web sidebar with automatic sizing by viewport width.
- Wide web screens show the full labeled menu; medium web screens automatically use the compact icon menu.
- Added compact module popovers so every ERP workflow stays accessible without expanding the sidebar.
- Added permission-aware active menu highlighting for routes, modules and entity screens.
- Added module search inside the expanded web and tablet/mobile drawer.
- Added an adaptive tablet NavigationRail with an expanded labeled mode on larger tablets.
- Added a fixed mobile bottom navigation bar for Dashboard, Search, Alerts and Modules.
- Moved campus, academic-year and school switching into a dedicated mobile/tablet context strip to prevent AppBar overflow.
- Added responsive top-bar compaction for narrow browser windows.
- Reworked dashboard shortcuts to use automatic tile sizing instead of fixed column counts.
- Added dashboard hover animation, keyboard-friendly InkWell interaction and improved dark-theme surfaces.
- Added consistent scrollbar, floating-action-button, icon-button and navigation-bar theming.
- Added active-route metadata to ERP module/entity screens.
- Fixed the duplicate named parameter declaration in `MainDrawer._named`.

## 2.3.1+7 — Secure Portals and Account Lifecycle

- Added trusted administrator provisioning with temporary-password and email-link setup methods.
- Added forced first-login password replacement, password reset, setup-email resend, account suspension and reactivation.
- Added required ERP profile linking for student, parent, teacher and class-teacher accounts.
- Added guardian-to-student access propagation and personal-scope Firestore authorization.
- Added portal-link backfill migration for existing tenant data.
- Added account-level persisted appearance and a complete tenant-aware enterprise dark theme.
- Enforced plan entitlements across drawer navigation, global search, direct module/entity routes and Firestore rules.
- Added stronger account lifecycle tests, static validation and deployment documentation.
- Added recent-authentication enforcement for first-login password completion.
- Separated student/parent portal accounts from paid staff-seat quotas across provisioning, role changes, suspension, usage refresh and migration.
- Added parent-child prerequisite validation and corrected parent self-service relationship metadata.

## 2.1.1 — Account Provisioning Error Handling

- Separated account provisioning success from password-email delivery failure.
- Added actionable Cloud Function errors and structured provisioning logs.
- Kept optional student/teacher record fields valid when both values are empty.

# Dashboard Navigation Update

- Added top AppBar Global Search for authorized ERP modules and options.
- Kept the original Quick Access cards with responsive mobile, tablet, and web grids.
- Reduced dashboard KPIs to Active Students and Admission Summary.
- Moved all ERP modules and entity options into permission-aware expandable drawer menus.
- Preserved notifications, school switching, tenant isolation, and role authorization.


## 2.0.0 — Enterprise SaaS Workspace

- Added 24 role-authorized ERP modules and 105 tenant-scoped workflows.
- Added the schema-driven ERP catalog, dynamic validated forms and responsive list engine.
- Added create, update, details, search, status filters and archive to every configured workflow.
- Added full debug ERP demo data and role preview for all supported roles.
- Added live tenant-scoped Firestore service and dashboard aggregate counts.
- Rebuilt the dashboard, quick actions, module search, latest updates and navigation drawer.
- Added School Setup, Admissions, Student, Parent, Teacher, Student Welfare, HR/Payroll, Attendance, Academic, Examination, Fees, Accounting, Library, Transport, Hostel, Inventory, Communication, Events, Documents, Timetable, Reports, Helpdesk, SaaS Administration and AI/Automation modules.
- Added live tenant announcements and events to the notification center.
- Expanded permissions and Firestore rules for all enterprise collections.
- Added Firebase Admin enterprise master-data seed tools for Windows.
- Added catalog integrity tests and updated architecture, module and setup documentation.

## 1.1.0

- Implemented Firebase session restoration and tenant membership validation.
- Added multiple roles, explicit permissions, denied permissions and multi-school switching.
- Added permission-filtered dashboard and navigation.
- Moved student and event data to tenant collections and replaced hard delete with archive.
- Added secure profile update, password reset, rules, indexes and Windows tools.

## 2.2.0+6 - SaaS foundation

- Added adaptive desktop, tablet and mobile application shell.
- Added tenant brand colour and logo application across the authenticated UI.
- Added campus and academic-year context selector.
- Added SaaS Control Center with plan status, usage quotas and feature matrix.
- Added guided tenant onboarding and launch-readiness calculation.
- Added subscription feature and limit overrides with grace-period support.
- Added plan-based module filtering and Firestore collection entitlement checks.
- Added trusted usage refresh and generic approval Cloud Functions with audit events.
- Added responsive approval inbox with approve/reject decisions and mandatory rejection reasons.
- Added backend-enforced student and campus quotas with trusted archive counters.
- Added a migration tool for existing tenant subscriptions and SaaS usage counters.
- Added staff-user subscription-limit enforcement during account provisioning.
- Standardized product branding as CARTZ Link School ERP.
