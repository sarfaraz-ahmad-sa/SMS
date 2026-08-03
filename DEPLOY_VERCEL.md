# Deploy SEEF School ERP Web

## Recommended: build locally and deploy static output

```bash
flutter clean
flutter pub get
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=APP_VERSION="$(git rev-parse --short HEAD)"
npm install -g vercel
cd build/web
vercel --prod
```

The included rewrite sends browser routes back to `index.html` for Flutter web
navigation. Static Flutter assets and CanvasKit files receive immutable cache
headers; the app also receives safe content-type, framing, referrer and browser
permission headers.

## Git-based Vercel build

`vercel.json` can clone Flutter stable and build the project automatically. This is convenient but slower and less deterministic than building with the Flutter version used by your development and CI environments.

For controlled production releases, build in CI with a pinned Flutter SDK and deploy only `build/web`.

## Supabase production configuration

1. Set only `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` as Vercel client build
   variables. The publishable key is intentionally public.
2. Never add a Supabase secret/service-role key or direct database password to
   Vercel client variables.
3. Add the exact Vercel/custom HTTPS origin and recovery callback to Supabase
   Authentication URL Configuration.
4. Apply every migration in `supabase/migrations` and verify RLS before a
   production deployment.
5. Keep server secrets in Supabase Edge Function secrets. Private documents,
   exports and backups must use the scoped Storage buckets created by migration
   `202608030010_private_school_storage.sql`.
