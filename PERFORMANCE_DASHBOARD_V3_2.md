# SEEF School ERP v3.2.0 — Performance and Dashboard Upgrade

## What changed

### Faster startup

The application now paints a lightweight startup view immediately. Firebase and Supabase are initialized after the first UI render and independent backend initialization runs in parallel. Bootstrap failures show a retry action instead of leaving the browser on a blank or apparently frozen screen.

The branded splash animation remains, but its forced minimum display time has been reduced from 1,100 ms to 360 ms.

### Faster dashboard data

Dashboard summary requests are cached for 75 seconds using a scope key that includes the active tenant, user, role/permissions, campus and academic year. Repeated route visits reuse the scoped result immediately. Concurrent requests for the same scope share one in-flight Future.

Independent counts now load in parallel. The previous sequence could wait for students, admissions and status aggregates one after another. The updated flow resolves students, employees, attendance, fees, payments, exams, expenses and admissions concurrently.

### Reduced rebuild and paint work

- Removed a redundant `ListenableBuilder` around the complete dashboard.
- Added `PageStorageKey` and dashboard scroll-state retention.
- Added repaint boundaries around web analytics panels and entity record lists.
- Added 140 ms debounce handling to module search, global search, drawer search and entity list filters.
- Kept existing paginated ERP data loading; no full-collection download was introduced.

## Web dashboard

The dashboard now behaves as an operational workspace rather than a static mockup.

- Permission-aware Command Center
- Working Students, Attendance, Fee, Examination and Reports shortcuts
- Clickable KPI cards
- Operations Overview built from real scoped totals
- Clickable Payments and Expenses summary chips
- Working Events Calendar navigation
- Working Admissions and Attendance panels
- Working Quick Access modules
- Manual refresh button
- Summary freshness indicator when the backend supplies `updatedAt`

Synthetic monthly finance data and the calculated fake attendance percentage were removed.

## Mobile dashboard

- Persistent bottom navigation retained
- Permission-aware three-column module workspace
- Working quick-action carousel
- Clickable KPI cards
- `View all modules` action when more than nine modules are available
- Events and E-Learning cards now open their real modules

## Recommended validation commands

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

For production web:

```bash
flutter build web --release --no-wasm-dry-run
```

For Android profiling:

```bash
flutter run --profile
```

Use Flutter DevTools Performance view while scrolling the dashboard and opening high-volume entity lists.

## Validation completed in the packaging environment

- Project lexical/delimiter validation: PASS
- Relative import validation: PASS
- ERP catalog/entitlement validation: PASS
- Firestore collection coverage validation: PASS
- JSON validation: PASS
- Node syntax validation: PASS
- Cloud Functions role-permission tests: 4/4 PASS

The Flutter SDK was not installed in the packaging environment, so Flutter analyzer, widget tests and release compilation must be run on the target development machine.
