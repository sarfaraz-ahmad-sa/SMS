# Deploy SEEF School ERP Web

## Recommended: build locally and deploy static output

```bash
flutter clean
flutter pub get
flutter build web --release \
  --dart-define=FIREBASE_APPCHECK_RECAPTCHA_KEY="$FIREBASE_APPCHECK_RECAPTCHA_KEY"
npm install -g vercel
cd build/web
vercel --prod
```

The included rewrite sends browser routes back to `index.html` for Flutter web navigation.

## Git-based Vercel build

`vercel.json` can clone Flutter stable and build the project automatically. This is convenient but slower and less deterministic than building with the Flutter version used by your development and CI environments.

For controlled production releases, build in CI with a pinned Flutter SDK and deploy only `build/web`.

## Firebase configuration required

1. Run `flutterfire configure` after confirming Android package ID, iOS bundle ID, and web app.
2. Add the Vercel/custom domain in Firebase Authentication authorized domains.
3. Enable Email/Password and Google sign-in providers.
4. Register the web, Android, and Apple apps with Firebase App Check. Use
   reCAPTCHA v3 for web, Play Integrity for Android, and App Attest with
   DeviceCheck fallback for Apple platforms.
5. Set `FIREBASE_APPCHECK_RECAPTCHA_KEY` in the Vercel project environment.
   This is the public reCAPTCHA site key; keep provider secret keys in Secret
   Manager or Vercel encrypted environment variables.
6. Deploy the included production rules and indexes:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

7. Deploy Cloud Functions before enabling App Check enforcement for callable
   clients, then verify signed-in web, Android, and Apple requests.
8. Enable App Check enforcement for Firestore, Authentication, Storage, and
   Cloud Functions in the Firebase console after monitoring metrics.
9. Create tenant and membership records using trusted backend tooling.
10. Test authorization with the Firebase Emulator Suite.

Never replace the included rules with public `allow read, write: if true` rules, even for a temporary production deployment.
