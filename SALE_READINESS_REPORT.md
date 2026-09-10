# Commercial source release assessment — 2026-09-10

## Executive summary

**NO-GO for sale as a production-ready white-label product. Estimated readiness: 58/100.** The code is a substantial Flutter/Supabase foundation, with Firebase retained for compatibility. Safe source fixes, buyer documentation and a local screened candidate are prepared. Backend acceptance, rights clearance and signed-device validation remain blockers. Nothing was uploaded, deployed, published, sold or transferred. No live customer database was accessed.

Scoring is a judgment rubric, not certification: security/configuration 15/25; functionality/verification 12/25; documentation/rebranding 18/20; demo/operations 7/15; commercial delivery/rights 6/15. Passing builds and unit tests support the foundation; they do not establish financial correctness, complete school workflows or secure deployed policies.

## Critical fixes completed in source

- Removed bundled seller Supabase connection defaults. Missing buyer configuration now fails closed; recognizable server-secret keys are rejected. Required public settings remain external build inputs.
- Removed tracked Vercel and iOS Firebase deployment files from the Git index while retaining their ignored local copies. Removed the iOS build dependency on the seller plist and expanded ignore rules.
- Added migration 020 to require active membership for linked portal access, including suspended parent/guardian access. Added suspension regression assertions to the SQL role matrix. **Not applied or executed against a database.**
- Guarded account mutations against existing target privileges, blocked self-provisioning and existing privileged-account overwrite paths, and blocked tenant-scoped password resets of identities shared across schools. These source changes type-check; deployed integration tests remain required.
- Applied spreadsheet-formula neutralization at CSV encoding so record IDs and headers receive the same protection as field values.
- Centralized application branding/default tenant currency/timezone, introduced platform-label synchronization, and replaced web artwork references with newly authored geometric placeholders.
- Fictionalized 102 sample contact/person/medical/location labels in catalog demo fixtures and replaced the misleading default demo launcher with an explicit isolated-Supabase configuration requirement.
- Applied compatible npm audit fixes without forced major upgrades. Pinned Supabase Edge Function imports to the tested 2.116.0 version and corrected SDK client type annotations.
- Removed the nonexistent RunnerTests Podfile target encountered during the iOS build. Recorded Flutter 3.44.9's automatic iOS project migrations.

## Remaining blockers and risks

1. Existing MIT rights conflict with a blanket ban on source redistribution/resale. The original LICENSE remains unchanged. Confirm ownership/contributor grants and have the commercial draft reviewed before use.
2. Run all six SQL integration files on a new sandbox after all 20 migrations. Verify every role, campus boundary, two-school isolation, storage upload/download rules, denied writes, suspension, recovery and logout.
3. Verify the three deployed Edge Functions, including attempts to demote/reset a higher-privilege target, duplicate provisioning, concurrent role changes and partial Auth/database failures.
4. Mandatory first-password-change enforcement remains incomplete at the backend boundary. Payment reconciliation, payroll disbursement, result moderation, scheduled backups/restore and PDF receipt generation are not production-certified.
5. Clear artwork/dependency licenses, supply buyer-owned mobile icons and signing identities, then test real devices. Original unverified artwork is withheld from the candidate.
6. Moderate npm advisories and legacy Flutter analyzer findings remain. The Firebase compatibility backend needs its own emulator and integration acceptance before sale.
7. The sandbox demo process is documented but has not been provisioned or exercised. Listed demo accounts are fictional setup specifications, not working credentials.

## Exact changes and checks

`FILE_CHANGES.md` lists every created, modified or untracked-from-Git source file and the reason. `TEST_RESULTS.md` records commands, outcomes and unexecuted checks. `release/PACKAGE_MANIFEST.json` lists every candidate member with a SHA-256 digest.

## Verified feature scope

Automated checks cover catalog/access helpers, 16-role permissions, tenant/student mapping, entitlement logic, dashboard parsing, storage path validation, error redaction and CSV encoding. The catalog contains 24 modules and 106 entities. Desktop/mobile login layout, empty login validation and recovery navigation were observed in a local browser using an inert backend hostname.

Onboarding, student/staff/parent management, academic setup, admissions, attendance, fees, exams, communications and operational records exist in source; their complete workflows are **not** verified. Refer to FEATURES.md before making product claims.

## Recommended screenshots and demo-video flow

Capture only a dedicated fictional sandbox; keep operator credentials and infrastructure details off screen.

1. Branded login on desktop, then mobile (10–15 seconds).
2. School-owner dashboard and navigation (20 seconds).
3. Fictional class/student list, create and edit one student (30 seconds).
4. Record a fictional attendance session (20 seconds).
5. Show a sample invoice and fee record; describe unimplemented payment integration accurately (20 seconds).
6. Show sample marks/results; do not claim moderation/publication verified without acceptance (20 seconds).
7. Switch to teacher, student and parent accounts to demonstrate permitted views; show rejection of an unrelated record (30 seconds).
8. Show School Profile branding, CSV export, then logout (20 seconds).

Useful stills: desktop dashboard, mobile dashboard, students form/list, attendance, fee records, parent portal, branding settings and permission-denied state. Do not reuse historical customer screenshots.

## Suggested commercial packages (scope proposals, no prices promised)

| Package | Proposed scope | Explicit boundaries |
| --- | --- | --- |
| Single School License | One named school; rebranding and deployment rights for the agreed Seller-owned deliverable | No competing source-product resale; final rights subject to existing licenses and legal review |
| Agency / White-Label License | Buyer internal work and a defined number or unlimited named client deployments, as agreed | Define client source handover separately; no marketplace/source-kit redistribution |
| Extended Support | Agreed support period, channel, supported versions and response targets | Third-party outages, custom code and data repair excluded unless specified |
| Customization and Deployment | Separate statement of work for branding, backend setup, import, training and hosting | Acceptance milestones, migration backup/rollback, provider bills and ongoing maintenance separately defined |

The draft proposes 30 calendar days of installation/defect support. The owner must approve that commitment; updates/custom development are separate.

## Delivery recommendation

The ZIP is a **screened review candidate**, not an approved commercial release. It excludes Git history, dependency/build caches, private configuration, customer exports, historical reports and unverified artwork. Its web assets use new placeholders; mobile artwork replacement remains required. Do not distribute it until the blockers above are closed and the owner explicitly approves delivery.

Legal review basis: the [MIT License](https://opensource.org/license/mit) permits distribution, sublicensing and sale subject to notice conditions; the proposed restrictions cannot be assumed to override those existing permissions.
