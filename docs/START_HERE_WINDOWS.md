# Start Here — Windows

## Demo

```bat
cd /d C:\SMS
flutter clean
flutter pub get
flutter run -d chrome
```

Click **Open Full ERP Demo**.

## Real Firebase school

```bat
cd /d C:\SMS
flutterfire configure
firebase deploy --only firestore:rules,firestore:indexes,storage

cd /d C:\SMS\tools\firebase_admin
set "GOOGLE_APPLICATION_CREDENTIALS=C:\secure\firebase-service-account.json"
seed-tenant.cmd
seed-enterprise-data.cmd
```

Enable Firebase Authentication providers before real login.


## Android wrapper or SHA-1

If `gradlew` is missing, run from the project root:

```bat
repair-android-wrapper.cmd
```

To print the Android debug certificate fingerprints:

```bat
android-sha1.cmd
```
