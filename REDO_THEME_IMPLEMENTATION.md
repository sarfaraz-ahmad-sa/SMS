# Solid School Theme Redo

This release was rebuilt from the original `SMS(4).zip` project and the supplied six-screen School Management reference set. It does not reuse the previously delivered theme patch.

## Visual system

- Solid blue-slate navigation: `#40566B`
- Pale blue-grey work area: `#F1F5F9`
- White cards with restrained `#E6ECF2` borders
- Compact 8–14 px corner radii
- Coral, cyan, gold, violet and green functional accents
- No glassmorphism and no decorative Google-blue treatment

## Responsive application shell

- Desktop uses a fixed dark sidebar, separate white command/search bar and open workspace.
- Tablet uses the same surfaces with a drawer-based navigation.
- Mobile uses the same palette and a simple page header without a competing bottom-navigation treatment.
- Tenant and academic context remain available through the command bar or context sheet.

## Rebuilt screens and shared components

- Splash screen and web boot loader
- Login and first-password screens
- Desktop and mobile dashboards
- Mobile three-column Academics grid
- Desktop KPI, overview, calendar, quick-access and admissions panels
- Desktop student master/detail directory
- Shared ERP list, table, mobile list and form styling through the global theme
- Profile, settings, search, notifications, SaaS, onboarding and accounts through the shared responsive shell
- Drawer navigation, selected states, module expansion and logout treatment

## Data integrity

Dashboard values continue to use the existing tenant-scoped services and permission checks. The UI does not add sample students, fake revenue or fake event records. The mini calendar uses the current month and surfaces available admissions/exam counts only.

## Validation completed

`python tools/validate_project.py` passes:

- Dart lexical and delimiter validation
- Relative import validation
- ERP module and entitlement mapping
- Firestore collection coverage
- Permission references
- JSON and Node syntax
- Secure account lifecycle checks

Flutter SDK was not available in the execution environment. Run these commands on the Flutter workstation before deployment:

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release --no-wasm-dry-run
```
