# Mobile Material & Performance Merge — 3.4.0+18

## Mobile interface

- Compact SEEF School app bar with contextual screen title, account avatar and theme control.
- Rounded global search surface available directly below the app bar.
- Material 3 bottom navigation for Home, Modules, Search, Alerts and Profile.
- Permission-aware dashboard chips for Today, Attendance, Fees and Approvals.
- Horizontally swipeable live KPI cards, two-column quick actions and adaptive module tiles.
- Light and dark surfaces resolve from the active tenant-aware `ColorScheme`.

## Runtime optimization

- Primary bottom-tab navigation uses route replacement instead of clearing and rebuilding the full route stack.
- Dashboard aggregates remain de-duplicated while a matching request is already in flight.
- Dashboard data keeps a three-minute scoped cache capped at eight tenant/user contexts.
- Expired dashboard entries are pruned before new data is retained.
- Lower-cost Material ripple feedback reduces paint pressure on lower-end Android devices and Flutter web.
- Session tenant lists are normalized once and reused without allocating a new wrapper on every rebuild.

## Validation

Run before production deployment:

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release --no-wasm-dry-run
```
