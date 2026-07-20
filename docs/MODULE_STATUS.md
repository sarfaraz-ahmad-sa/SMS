# Module Implementation Status

## Connected to tenant-scoped Firebase data

- Authentication and session restore
- Tenant membership validation
- Multi-school switching
- Role and permission based dashboard
- Student creation, listing, and archiving
- Event creation, listing, and archiving
- Profile display-name update
- Password reset
- School access request

## Existing interactive UI prototypes

- Admissions
- Teacher management
- HR and payroll
- Accounting
- Fees
- Attendance
- Examination results
- Timetable
- Library
- Transport
- Hostel
- Inventory
- Reports
- Activities
- Leave application
- Notifications

These screens remain useful UI prototypes but are not yet authoritative ERP workflows. Their transactional implementation belongs in the Laravel/MySQL API described in `docs/LARAVEL_HANDOFF.md`.

## Not represented as production workflows yet

- Double-entry accounting and bank reconciliation
- Fee invoice/payment allocation and gateway reconciliation
- Examination moderation, result locking, transcripts, GPA/CGPA
- Payroll approval and disbursement
- Biometric/RFID ingestion
- Procurement and inventory ledger
- Hostel allocation ledger
- GPS transport integration
- Document templates, certificate verification, and digital signatures
- Audit log and sensitive-read log
- SaaS subscription billing and automated tenant provisioning
- AI features

No placeholder UI should be interpreted as production-complete until its Laravel API, database schema, authorization policies, validation, audit trail, and automated tests are implemented.
