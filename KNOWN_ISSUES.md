# Known issues and release blockers

- Restrictive commercial terms conflict with the existing MIT grant. Establish ownership and contributor/asset rights; do not replace LICENSE without legal review.
- No disposable backend was available. Migrations, RLS/Storage rules, Edge Function mutations, Auth recovery, two-school isolation and all live workflows remain unverified.
- New migration 020 and account-management guards are source fixes only; deploy and run regression tests on a sandbox before production.
- Account provisioning/password update and membership/audit changes span separate services, so partial failures and concurrent role changes need integration testing and recovery procedures.
- First-password-change completion is a client-invoked action; backend-wide enforcement and session revocation need further review. Do not market mandatory password rotation or MFA enforcement as complete.
- Firebase compatibility rules have not been emulator-tested; do not enable that backend for buyers without a separate acceptance pass.
- Moderate Node transitive dependency advisories remain where compatible fixes are unavailable. Node 25 was available locally rather than the Functions target Node 22.
- Flutter analysis retains legacy warnings/info findings. See TEST_RESULTS.md for actual results.
- Country and receipt-footer settings are reserved configuration; no complete country tax/receipt engine exists. Date formatting is partially centralized. SaaS prices still require business review.
- No automatically seeded Supabase demo accounts; setup/reset is manual and must be exercised.
- Mobile exports, production PDF receipts, scheduled backup execution, payment reconciliation, payroll disbursement and result moderation are not certified complete.
- Asset provenance is unresolved. Original GIF/Flare files are no longer bundled by pubspec; new geometric SVG placeholders are included for web. The screened candidate omits unverified artwork and is not a turnkey mobile release until replacements are supplied.
- Android/iOS signing and distribution identities are placeholders/buyer-owned tasks; responsive/device acceptance and browser navigation acceptance remain pending.
- Historical docs are not current validation and are excluded from the candidate.
