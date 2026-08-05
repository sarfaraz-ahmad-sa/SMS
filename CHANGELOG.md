# Changelog

## 3.3.0+17 — Non-blocking Dashboard & Executive Analysis

- Dashboard renders immediately and hydrates live totals after the first frame.
- Replaced the blocking full-page dashboard skeleton with a compact background status bar.
- Added permission-aware initial state and fresh scoped cache reuse when returning to Dashboard.
- Increased scoped dashboard cache TTL to three minutes and retained in-flight request de-duplication.
- Debounced campus, academic-year, role and permission session update bursts.
- Added bounded timeouts and safe fallbacks for aggregate and admission-status count requests.
- Reduced dashboard scroll cache extent to avoid laying out off-screen web/mobile sections early.
- Deferred lower dashboard panels across successive frames to reduce main-isolate frame spikes.
- Added Executive Analysis for admissions, attendance activity, payment activity and student–staff ratio.
- Replaced placeholder/fake event entries with real Events and Timetable workspace actions.
- Kept every visible dashboard metric and insight connected to a real permission-aware ERP module.

## 3.2.0+15 — Performance and Next-Level Dashboard

- Render the startup interface immediately instead of waiting for Firebase/Supabase initialization before first paint.
- Initialize independent backends in parallel and show an actionable retry state on bootstrap failure.
- Reduced the forced splash delay from 1.1 seconds to 360 milliseconds.
- Added a tenant/user/campus/academic-year scoped dashboard cache with duplicate request deduplication.
- Converted dashboard aggregate loading from a sequential request waterfall to parallel requests.
- Removed the redundant full-dashboard session listener rebuild.
- Added a permission-aware web Command Center with working Students, Attendance, Fees, Exams and Reports shortcuts.
- Made web KPI cards, operations overview rows, calendar, admissions, attendance and quick-access panels navigable.
- Replaced synthetic monthly finance bars and fake attendance percentages with real scoped totals.
- Added a working dashboard refresh action and live-summary freshness label.
- Added permission-aware mobile quick actions, KPI navigation and an all-modules action.
- Debounced Global Search, module search, drawer search and entity-list filtering.
- Added repaint boundaries around high-cost dashboard and record-list surfaces.
- Removed the non-functional keyboard-shortcut badge from the web search box.

## 3.1.0+14

- Added expanded, mini, and fully closed desktop sidebar modes.
- Added persistent navigation preference across routes.
- Added web sidebar close/reopen controls.
- Added explicit mobile drawer close control.
- Kept mobile menu available on nested screens.
- Refined web command bar and responsive control visibility.
- Refined persistent mobile bottom navigation.
- Upgraded mobile dashboard welcome and search experience.
- Retained the MainDrawer BoxDecoration compile fix.

## 3.0.0+13 — Full Modern Mobile and Web Application

- Rebuilt the authenticated application around one responsive solid design system instead of a dashboard-only theme.
- Added persistent five-destination mobile bottom navigation for Home, Modules, Search, Alerts and Profile.
- Added a dedicated desktop workspace with a fixed slate sidebar, command/search bar and contextual school controls.
- Rebuilt the role-aware dashboard for compact mobile workflows and browser analytics.
- Reworked module, list, form, detail, table, status, empty-state and dialog surfaces across the ERP.
- Migrated student, admissions, attendance, leave, fee, examination, timetable, library, transport, hostel, event and activity screens to the shared shell.
- Rebuilt authentication and account setup screens with a dedicated responsive solid auth layout.
- Replaced the basic web loader with a responsive product-shell skeleton for desktop and mobile.
- Preserved permissions, plan entitlements, tenant/campus/academic-year scope and Firebase/Supabase service behavior.
- Removed the transient student-list scroll-controller allocation from widget build.

## 2.4.2+9 - Web startup and Google sign-in fix

- Deferred splash bootstrap until after the first rendered frame, preventing `SessionState` notifications during widget build.
- Made session initialization idempotent.
- Stopped constructing `GoogleSignIn` on web; Firebase Auth redirect is now used without requiring a `google-signin-client_id` meta tag.
- Kept native Google Sign-In lazy-initialized for Android and iOS.
- Removed the duplicate web viewport declaration and cleaned the active analyzer warnings reported in v2.4.1.


## 2.4.1 - Production login reliability

- Added Firebase Web auth-state fallback when `UserCredential.user` is delayed.
- Forces a fresh ID token before tenant and membership reads.
- Added readable Firestore service, permission, and availability errors.
- Preserves existing tenant, role, subscription, and first-login security checks.

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
- Standardized product branding as SEEF School ERP.
