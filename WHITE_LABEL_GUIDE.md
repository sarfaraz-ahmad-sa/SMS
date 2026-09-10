# White-label guide

`lib/config/brand_config.dart` defines public defaults. Copy `config/brand.example.json` to an ignored buyer configuration and pass it via `--dart-define-from-file`.

| Key | Effect |
| --- | --- |
| APP_NAME | Flutter title, auth shells, splash and application labels |
| COMPANY_NAME | Default school lockup; persisted tenant name takes precedence |
| LOGO_URL | Default network raster logo; tenant logo wins, painter handles missing/broken images |
| PRIMARY_COLOR / SECONDARY_COLOR | ARGB integers (e.g. 0xFF4F46E5); tenant primary is blended with the theme |
| SUPPORT_EMAIL / SUPPORT_PHONE / WEBSITE_URL | Settings support footer; phone may include a WhatsApp contact |
| CURRENCY / TIME_ZONE | Defaults for new tenant objects/onboarding; existing tenant values remain authoritative |
| DATE_FORMAT | ERP date values: yyyy, MM and dd tokens; ISO strings in other screens retain existing formatting |
| COUNTRY | Public country metadata reserved for regional integrations; no country-specific tax engine |
| RECEIPT_FOOTER | Reserved text for future receipt/PDF integration; there is no complete receipt renderer |

This is centralized application branding, not a claim that every legacy date string or accounting rule is localized. Existing tenants require explicit edits in School Profile. Time zone configuration is not a general conversion engine. SaaS subscription prices remain business configuration and must be reviewed separately.

Web HTML title/splash/manifest and native application labels are build resources. Run `python3 tools/apply_brand.py config/local.json` to synchronize supported metadata from the same source. Inspect the diff before committing. It does not alter bundle IDs, signing or tenant data.

For custom logos, use an HTTPS raster image you own; test offline fallback. Supply your own launcher icons and web splash SVG only after rights review. Preserve attribution notices for retained dependencies/artwork.

Android package/namespace and Kotlin package are in `android/app/build.gradle` and MainActivity.kt. iOS bundle IDs and team are in Runner's Xcode project. Changing identifiers changes app-store identity; choose them before release. Use your own Android keystore / Apple signing assets outside version control.

Supabase is primary: use your own backend settings and migrations. Firebase is optional compatibility, not required for a normal build; reconfigure it completely before enabling it. No Supabase-to-Laravel migration is required or supplied. For a domain, configure DNS/HTTPS, SPA routing and matching Auth redirects. Nothing here automatically publishes a site.
