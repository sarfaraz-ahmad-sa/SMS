# Deploying CARTZ Link SMS (Flutter Web) to Vercel

You have two options. **Option A (local build) is the most reliable** — Vercel
doesn't ship Flutter, so the git-based build (Option B) works but is slow and can
hit build-time limits on the free tier.

---

## Option A — Build locally, deploy the output (recommended)

1. Build the web app on your machine:
   ```bash
   flutter pub get
   flutter build web --release
   ```
   This creates the `build/web/` folder.

2. Install the Vercel CLI (once):
   ```bash
   npm i -g vercel
   ```

3. Deploy the built folder:
   ```bash
   cd build/web
   vercel --prod
   ```
   First run asks you to log in and link/create a project. Done — you get a live URL.

> Re-run steps 1 and 3 each time you want to publish updates.

---

## Option B — Auto-deploy from GitHub (Vercel builds Flutter)

The included `vercel.json` clones the Flutter SDK and builds on Vercel.

1. Push this project to a GitHub repo.
2. On vercel.com → **Add New → Project → Import** your repo.
3. Framework preset: **Other**. Leave build settings as-is (they come from
   `vercel.json`). Deploy.

`vercel.json` already sets:
- `buildCommand`: clones Flutter stable, enables web, `pub get`, `build web --release`
- `outputDirectory`: `build/web`
- SPA `rewrites`: every path → `/index.html` (so page refresh/deep links work)

If the build times out on the free plan, use Option A instead.

---

## REQUIRED: Firebase settings for the live site

Your app uses Firebase Auth + Firestore, so after you have the Vercel URL:

1. **Authorize the domain** — Firebase Console → Authentication → Settings →
   **Authorized domains** → add your Vercel domain (e.g. `your-app.vercel.app`).
   Without this, Google/Email sign-in is blocked on the live site.

2. **Firestore enabled** — Firebase Console → Firestore Database → Create
   database (production or test mode).

3. **Security rules** — for a quick test you can allow access, but lock this down
   before real use:
   ```
   // TEST ONLY — do not ship to production
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} { allow read, write: if true; }
     }
   }
   ```

4. **Custom domain (optional)** — Vercel → Project → Settings → Domains. Add the
   new domain to Firebase Authorized domains too.

---

## Notes

- `<base href="/">` in `web/index.html` is correct for a root Vercel domain. If you
  ever host under a sub-path, change it accordingly.
- The demo "Continue as Guest" login does not use Firebase Auth, so Firestore
  writes require test-mode rules (or real login) as noted above.
