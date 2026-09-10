# Dependency and artwork review

Do not treat dependency installation or a successful build as redistribution clearance. Existing LICENSE is retained. Review every locked Dart and npm package and preserve their license/NOTICE files in any distribution containing them.

| Material | Required review |
| --- | --- |
| Flutter/Dart and generated engine/font assets | SDK notices and redistribution obligations for binary delivery |
| firebase_*, cloud_firestore, google_sign_in, supabase_flutter | Locked package licenses, transitive licenses, provider terms and trademark restrictions |
| date_time_picker / cupertino_icons / Material icons | Package/font notices and attribution requirements |
| firebase-admin, firebase-functions, cors and transitive npm modules | Lockfile inventory, license notices, vulnerability findings |
| Supabase Edge Function npm imports | Resolve and pin a reviewed dependency version for release; imports pinned to 2.116.0 during this preparation; review transitive Deno resolution |
| assets/*.gif, *.flr, old SVG logos, native/web launcher PNGs | Authorship and commercial redistribution evidence absent; withheld from screened package |
| Existing application source | Confirm seller ownership/contributor grants; MIT notice must remain |

Dependencies are not vendored into the candidate; buyer installation fetches them. This avoids silently redistributing unreviewed dependency trees, but does not eliminate the seller's release obligations. No new third-party artwork was fetched or added. The two school-mark.svg copies are newly authored geometric placeholders and are included; old artwork is withheld.
