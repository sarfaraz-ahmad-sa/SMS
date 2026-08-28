# Lightweight Dashboard — 3.6.0+20

## What changed

The active dashboard now renders only the information needed for daily work:

- user, school and date header;
- permission-aware live totals;
- four frequent actions;
- a small role-aware module list;
- one admissions overview when permitted.

The previous dashboard's nested grids, horizontally scrolling KPI list, delayed timers, executive charts, calendar, events and learning panels are no longer part of the active render path.

## Performance behavior

- Data loads after the first frame and never blocks module navigation.
- Dashboard results remain tenant, user, campus and academic-year scoped.
- Fresh results use the bounded three-minute cache.
- Duplicate in-flight requests are reused.
- Aggregate calls time out after four seconds and fallback counts after five seconds.
- Missing admission status aggregates use one total query instead of eight status queries.

## Validation

The static validator now confirms that the lightweight dashboard is active and rejects admission status-query fan-out. Before deployment also run:

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release --no-wasm-dry-run
```
