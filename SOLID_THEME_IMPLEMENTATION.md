# Solid School Theme Implementation

This revision replaces the prior Google Workspace-inspired styling with the visual system from the supplied school-management references.

## Design system

- Navigation: solid slate `#40566A`
- Navigation depth: `#354B60`
- App background: pale blue-grey `#F1F5FA`
- Cards and controls: white `#FFFFFF`
- Primary text: `#2F4052`
- Secondary text: `#8A97A5`
- Dividers: `#E5EBF1`
- Accent palette: cyan, gold, coral, lavender, green and blue
- Card radius: 11px
- Control radius: 9px
- No glassmorphism, decorative glow, or multicolour UI gradients

## Updated areas

- Shared Flutter light/dark theme
- Desktop responsive application shell
- Tablet navigation rail
- Mobile app bar and page shell
- Solid slate ERP drawer and selected navigation state
- Dashboard KPI cards
- Mobile three-column academics/module grid
- Search fields and controls
- Login screen and desktop login presentation
- First-login password screen
- Legacy user and dashboard cards
- Web loading screen and PWA theme colours

## Validation completed

- Dart lexical and delimiter validation
- Relative import validation
- ERP module and entitlement mapping
- Firestore collection coverage
- JSON validation
- Node syntax validation
- Secure account lifecycle checks

Run on a Flutter workstation before release:

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release --no-wasm-dry-run
```
