# Feature status

No end-to-end backend workflow is certified complete by this preparation. A successful build verifies compilation, not business behavior.

## Verified in code and automated checks

- Catalog structure: 24 modules, 106 entities; generic record fields/forms/list definitions.
- Role/permission mapping and delegation helpers; 16 supported roles.
- Tenant/student mappers, ERP access filtering helpers, entitlement limits, dashboard parsing, storage path checks and error-reporter redaction through existing unit tests.
- CSV formula neutralization including exported identifiers through a new unit test.
- Flutter web release compilation with inert configuration.

## Implemented, requires isolated integration acceptance

| Area | Evidence / limitation |
| --- | --- |
| School onboarding and multi-school sessions | Screens, Edge Function, tenant provisioning RPC, campus/year and session switching; needs two-school test |
| Classes, sections, subjects, timetable | ERP entities; no proven scheduling/conflict automation |
| Students, parents, teachers, staff | Screens/services and account linking; lifecycle and quota concurrency need verification |
| Admissions and promotions | Record workflows; promotion rollback and academic-year migration not certified |
| Attendance | Native tables and generic screens; full teacher/student workflow unverified |
| Fees, invoices, discounts, payments | Record definitions plus trusted RPCs; gateway reconciliation, ledger posting and receipts not certified |
| Exams, marks and results | Record definitions/RPCs/RLS; moderation and publication acceptance pending |
| Homework, announcements, events | Generic entities and service routes; delivery notifications require provider integration |
| Reports/CSV | Web export is implemented; mobile export throws UnsupportedError; PDF printing/report workers incomplete |
| Backups | Job records/private bucket exist; scheduled execution and restore drill absent |
| Dashboards/navigation | Role-aware/responsive code; full desktop/mobile acceptance pending |
| Error/empty/loading/offline states | Several code paths exist; offline sync is not an implemented product guarantee |
| Library, hostel, transport, HR, inventory | Generic records; not proven specialized automation |

## Not included as complete features

Live payment/SMS/WhatsApp connectors, payroll disbursement, production backup workers, SLA monitoring, SSO/MFA administration, production AI inference, signed mobile-store binaries, verified push notifications, PDF receipt generation and fully localized financial logic.

## Third-party services

Supabase project/Auth/email/Storage and Edge Functions require buyer configuration; hosting, mail, storage and usage may incur provider costs. Firebase compatibility requires a separately configured project, App Check and potentially billable Functions. Google sign-in is a compatibility feature, not verified in primary Supabase mode. Apple/Google store accounts and signing are buyer responsibilities. No paid integration is activated here.
