# Windows CMD setup

Run the full demo from the project root:

```bat
cd /d C:\SMS
start-demo.cmd
```

For Firebase configuration and validation, run:

```bat
cd /d C:\SMS
flutterfire configure
flutter analyze
flutter test
```

`flutterfire configure` does not work from `C:\SMS\tools\firebase_admin` because that folder is not the Flutter project root.

## Firebase Admin credentials

Download a Firebase Admin service-account key from Firebase Console / Google Cloud and keep it outside the repository. Never commit the JSON file.

In Windows CMD:

```bat
set "GOOGLE_APPLICATION_CREDENTIALS=C:\secure\school-management-service-account.json"
```

The environment variable applies only to the current CMD window unless it is configured permanently.

## Seed the first school

```bat
cd /d C:\SMS\tools\firebase_admin
seed-tenant.cmd
```

The script prompts for the project, school, and owner details. It supplies the environment variables in Windows CMD syntax and then runs `npm run seed:tenant`.

## Migrate old flat collections

Run a dry run first:

```bat
cd /d C:\SMS\tools\firebase_admin
set "DRY_RUN=true"
migrate-flat.cmd
```

For the real migration:

```bat
set "DRY_RUN=false"
set "DELETE_SOURCE=false"
migrate-flat.cmd
```

Use the real Firebase Authentication UID for `ACTOR_UID`. Do not enter angle brackets such as `<firebase-admin-uid>` because CMD interprets them as redirection operators.

## Manual Windows CMD environment syntax

Windows CMD uses `set`, not Linux-style `NAME=value command` syntax:

```bat
set "FIREBASE_PROJECT_ID=school-management-app-46a07"
set "TENANT_ID=school_demo"
set "TENANT_NAME=Demo Public School"
set "TENANT_CODE=DPS"
set "USER_EMAIL=owner@example.com"
set "USER_NAME=School Owner"
set "USER_PASSWORD=StrongTemporaryPassword"
npm run seed:tenant
```

Do not add trailing `\` characters. Those are Linux shell line continuations and are not valid CMD syntax.


## Missing Android Gradle wrapper

```bat
cd /d C:\SMS
repair-android-wrapper.cmd
```

## Print Android SHA-1

```bat
cd /d C:\SMS
android-sha1.cmd
```
