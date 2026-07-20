# Deploy CARTZ Link SMS Web

## Recommended: build locally and deploy static output

```bash
flutter clean
flutter pub get
flutter build web --release
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
4. Deploy the included production rules and indexes:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

5. Create tenant and membership records using trusted backend tooling.
6. Test authorization with the Firebase Emulator Suite.

Never replace the included rules with public `allow read, write: if true` rules, even for a temporary production deployment.
