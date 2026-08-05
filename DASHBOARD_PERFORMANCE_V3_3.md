# Dashboard Performance and Analysis Upgrade — v3.3.0

## Root causes found

1. The previous `FutureBuilder` replaced the complete dashboard with a full skeleton until every aggregate request completed. A slow or missing aggregate therefore felt like a frozen screen.
2. The dashboard `ListView` used a very large `cacheExtent` (`900` mobile / `1400` web), causing substantial off-screen layout work on entry.
3. The complete desktop dashboard was one large `Column`, so charts, calendar cells, quick-access tiles and operational panels were laid out in the same frame.
4. Session hydration could notify several times while tenant, campus, year and permissions were being resolved, triggering repeated dashboard rebuilds and requests.
5. A single failed aggregate or admission-status count could fail the complete dashboard result.
6. Some calendar cards displayed placeholder event labels rather than live records.

## Changes implemented

- Permission-aware dashboard UI renders on the first frame.
- Live totals hydrate in the background without blocking navigation or scrolling.
- Fresh tenant/user/campus/year cache is reused immediately when returning to Dashboard.
- Cache TTL is three minutes and in-flight requests remain de-duplicated.
- Session changes are debounced by 180 ms.
- Summary reads use a seven-second bound; fallback aggregate reads use eight-second bounds.
- Failed metrics fall back independently instead of taking down the whole dashboard.
- Web/mobile cache extent reduced to `420` / `280`.
- Lower analysis sections are deferred across frames (35–140 ms), distributing layout cost.
- Heavy sections are isolated with `RepaintBoundary`.
- Added Executive Analysis cards:
  - admission approval rate;
  - attendance session activity;
  - payment-record activity;
  - student-to-staff ratio.
- Existing operational totals, admissions pipeline, attendance activity, finance records, quick actions and module navigation remain available.
- Fake event names and fake event markers were removed. Events and Timetable now open the real module workspaces.

## Data behavior

The dashboard prefers pre-aggregated `dashboard_summaries`. When a summary is missing on Firebase, bounded aggregate counts run in the background. Supabase requires an explicit tenant, campus and academic-year scope; incomplete session hydration returns a permission-aware empty state instead of throwing or blocking the UI.

## Validation completed

- 118 Dart source/test files passed lexical and delimiter validation.
- Relative import validation passed.
- 24 ERP modules and 106 workflow collections passed catalog/rules validation.
- JSON and Node syntax validation passed.
- Secure account lifecycle validation passed.

Flutter SDK was not installed in the packaging environment. Run the following on the development machine:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```
