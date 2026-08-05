# UserRole Compile Fix v3.2.1

## Fixed

`lib/Screens/home.dart` used the `UserRoleX` extension getters `isLearner` and `isGuardian` without importing the extension library.

Added:

```dart
import '../services/models/user_role.dart';
```

The getters already exist in `lib/services/models/user_role.dart`; no role behavior was changed.

## Verification

- Scanned all Dart files using `.isLearner` or `.isGuardian`.
- `home.dart` was the only file missing the direct extension import.
- Version updated to `3.2.1+16`.
