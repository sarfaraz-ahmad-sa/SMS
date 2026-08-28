# Premium Theme and Branding — v3.7

## What changed

- The generic Flutter icon has been replaced by an original SEEF school crest.
- Flutter login, auth, splash, startup, sidebar and school profile screens now share one brand system.
- A school-provided `logoUrl` automatically replaces the SEEF fallback inside the authenticated tenant workspace.
- The mobile header shows the active school name.
- The static web loader, browser favicon and installable PWA icons now match the application theme.

## Demo preparation

Before presenting a tenant to a school, update its School Profile with:

1. School name and short code.
2. HTTPS logo URL with a square logo and safe padding.
3. Brand colour.
4. Active campus and academic year.

The navigation theme derives a contrast-safe accent from the tenant brand colour while retaining readable common surfaces.

## Deployment

```bash
vercel --prod
```

After deployment, hard refresh the browser so the service worker, favicon and PWA icon cache are replaced.
