# Dashboard Performance Patch 3.3.0+17

Apply this patch to the matching SEEF/JinnTV v3.2.1 source tree.

1. Back up the project.
2. Extract the patch into the project root and replace existing files.
3. Run:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

The patch updates `lib/Screens/home.dart`, the application version and release documentation. It removes the blocking dashboard skeleton, hydrates totals in the background, debounces session updates, bounds aggregate requests, defers heavy panels and adds permission-aware executive analysis.
