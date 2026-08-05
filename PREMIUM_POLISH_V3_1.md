# SEEF School ERP — Premium Navigation & UI Polish v3.1.0

## Scope

This release improves the existing v3.0.1 application without changing tenant, permissions, Firebase/Supabase, ERP workflows, or business rules.

## Web improvements

- Persistent three-state sidebar:
  - Expanded navigation
  - Mini icon rail
  - Fully hidden focus mode
- Sidebar state remains stable while moving between named routes.
- Dedicated sidebar collapse and close controls.
- Top-bar menu control always restores a hidden sidebar.
- Responsive top-bar behavior hides non-essential controls on narrower desktop widths to prevent overflow.
- Stronger global search affordance, workspace subtitle, bordered action buttons, and compact profile presentation.
- Improved sidebar tooltips, scroll behavior, selected states, account footer, and logout access.

## Mobile and tablet improvements

- Explicit close button inside the drawer.
- Rounded solid drawer with a stronger overlay.
- Nested screens now show Back and retain direct Menu access.
- Search is always accessible from the app bar.
- Refined persistent bottom navigation with:
  - Home
  - Modules
  - Search
  - Alerts
  - Profile
- Stronger selected indicators and a prominent center Search action.
- Upgraded solid dashboard welcome card and module shortcut.

## Compile fix retained

The invalid direct `Border` assignment in `MainDrawer` remains corrected through `BoxDecoration(border: ...)`.

## Validation performed

- Dart lexical and delimiter validation: PASS
- Relative import validation: PASS
- ERP catalog and entitlement mapping: PASS
- Firestore collection rule coverage: PASS
- JSON validation: PASS
- Node syntax validation: PASS
- Secure account lifecycle validation: PASS

Flutter SDK is not installed in the packaging environment. Run the following on the development machine:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```
