# Production UX & Reliability — 3.5.0+19

## Experience

- The indigo and emerald tenant-aware Material 3 system remains consistent on mobile, tablet, web and desktop.
- Password recovery and login-request surfaces now resolve their background, text and accents correctly in light and dark mode.
- Horizontally scrollable mobile metrics and desktop data surfaces support touch, mouse and trackpad dragging.
- Unknown or stale deep links show an actionable page and return to sign-in or the dashboard based on session state.

## Reliability and performance

- Release builds no longer expose raw backend bootstrap details to end users.
- Legacy attendance animations that restarted during widget builds were replaced with static, lower-cost Material cards.
- Legacy user cards read the active signed-in user and tenant instead of displaying hard-coded demo identity data.
- Access request forms support keyboard submission and validate a usable minimum phone number length.

## Accessibility

- Attendance, session-half status, profile and leave cards include semantic summaries.
- Interactive app-bar actions include tooltips and Material-sized touch targets.
- Status is conveyed with readable labels and icons rather than color alone.

## Required release checks

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release --no-wasm-dry-run
```

The delivery environment also runs the repository static validator and Firebase role-permission tests.
