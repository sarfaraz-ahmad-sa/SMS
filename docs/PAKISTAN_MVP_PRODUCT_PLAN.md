# Pakistan School SaaS — Saleable MVP Plan

Product position: a simple, affordable cloud school ERP for Pakistani private
schools, academies, and coaching centres with 100–2,000 students. The first
commercial release targets single-campus schools moving from registers, Excel,
and WhatsApp. Large chains are explicitly out of initial scope.

## Product promise

Mobile- and web-friendly school software that remains usable on slow internet,
supports Urdu and English, and reduces fee follow-up through WhatsApp reminders.

The platform remains multi-tenant internally. Every school record stays below
its tenant path and carries tenant, campus, academic-year, archive, creator, and
timestamp metadata. The initial user experience exposes the small set of
workflows schools use daily; advanced catalog workflows are not MVP claims until
their end-to-end acceptance criteria pass.

## Phase 1 — saleable MVP gates

A feature is complete only when its permissions, empty/loading/error states,
mobile layout, audit trail, export/print output, and tenant isolation tests pass.

- [ ] School self-registration, trial, subscription status, limits, renewal,
  suspension, and owner onboarding.
- [ ] Admin, teacher, accountant, and parent accounts with secure provisioning,
  profile linking, first-login password flow, and role tests.
- [ ] Student admission through enrollment into class and section, including
  guardian linking and migration/import validation.
- [ ] Classes, sections, subjects, academic years, and teacher assignment.
- [ ] Monthly fee generation as an idempotent backend job; discounts, fines,
  arrears, partial payments, and pending dues.
- [ ] Printable branded A4/thermal fee vouchers and receipts with immutable
  receipt numbers.
- [ ] Daily student attendance optimized for one class/section and date, with
  correction audit history.
- [ ] Exams, marks entry, approval/publishing, grading, and printable result
  cards visible to the correct parent/student only.
- [ ] Targeted parent announcements with delivery state and audit history.
- [ ] Opt-in WhatsApp fee reminders using approved templates, consent records,
  retry limits, provider cost tracking, and delivery webhooks.
- [ ] Cash/bank income, expenses, daily closing, outstanding fees, and owner
  dashboard backed by summary documents rather than scan/count fan-out.
- [ ] Scheduled encrypted backups, retention, restore drill, append-only audit
  logs, monitoring, and billing alerts.

## Phase 2 — differentiation after 3–5 paying schools

- Parent/student Android and iOS experience.
- Teacher mobile experience and offline attendance outbox/sync.
- Public online admission form.
- JazzCash, Easypaisa, bank, and payment-gateway integrations.
- Biometric attendance integration.
- Transport, payroll, and staff attendance.
- Multi-branch operations and consolidated owner reporting.
- Homework, assignments, daily diary, and Urdu interface.
- Branded/white-label mobile apps as a paid add-on.

## Commercial plans

| Plan | Active students | Monthly price |
| --- | ---: | ---: |
| Starter | 200 | PKR 3,000 |
| Standard | 500 | PKR 6,000 |
| Professional | 1,000 | PKR 10,000 |

One-time setup is PKR 10,000–25,000. Data migration, custom reports,
biometric hardware, WhatsApp/provider usage, payment fees, and app branding are
separate charges. Enterprise/custom tenants remain supported for negotiated
limits but are not the initial sales target.

## Release sequence

1. Pass every Phase 1 gate in staging.
2. Run a real demo-school pilot with anonymized or consented data.
3. Close and onboard the first paid school.
4. Triage feedback by daily operational impact, not catalog size.
5. Stabilize three paying schools and monthly support operations.
6. Begin Phase 2 integrations and focused marketing.

## Immediate engineering order

1. Complete the Supabase cutover acceptance pass, remove dormant Firebase
   compatibility packages, and keep School Accounts plus trusted fee/result
   writes on PostgreSQL RPCs/Edge Functions.
2. Complete monthly fee generation, voucher/receipt PDFs, dues aging, and daily
   cash closing.
3. Complete class/date attendance workflow and offline-safe retry behavior.
4. Complete marks approval, publication, and result-card PDF.
5. Add announcements and one compliant WhatsApp provider integration.
6. Automate backup/restore tests, monitoring, alerts, and support runbooks.
7. Pilot on Android and web with one school before opening wider signup.
