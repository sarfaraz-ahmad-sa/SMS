# Enterprise Module Inventory

Current build contains **24 modules** and **105 tenant-scoped workflows**.

Every workflow uses the shared responsive list/form engine, permission filtering, tenant metadata, search, status filters, create/update, record details, and archive instead of hard delete.

## 1. School Setup

Campuses, academic years, classes, subjects and master data.

- Campuses
- Academic Years
- Departments
- Classes
- Sections
- Subjects
- Grading Schemes
- Holidays

## 2. Admissions

Inquiry-to-enrollment workflow with approvals and documents.

- Admission Inquiries
- Applications
- Admission Offers

## 3. Student Management

Complete student lifecycle, enrollment, promotion and records.

- Students
- Enrollments
- Promotions
- Transfers & Migration
- Discipline Records
- Achievements
- Alumni

## 4. Parent Management

Guardians, child links, custody restrictions and preferences.

- Parents & Guardians
- Child Links
- Parent Meetings

## 5. Teacher Management

Teacher profiles, workload, qualifications and evaluations.

- Teachers
- Subject Assignments
- Teacher Evaluations

## 6. HR & Payroll

Employees, contracts, leave, payroll and performance.

- Employees
- Contracts
- Leave Requests
- Payroll Runs
- Payslips

## 7. Attendance

Student and staff attendance, devices, corrections and alerts.

- Attendance Sessions
- Student Attendance
- Staff Attendance
- Student Leave Requests
- Attendance Devices

## 8. Academic Management

Curriculum, syllabus, lesson plans, assignments and materials.

- Syllabus
- Lesson Plans
- Assignments & Homework
- Study Materials

## 9. Examinations

Exam setup, schedules, marks, results and transcripts.

- Exams
- Exam Schedules
- Marks Entry
- Results
- Transcripts

## 10. Fee Management

Fee structures, invoices, collections, concessions and refunds.

- Fee Structures
- Student Invoices
- Payments & Receipts
- Scholarships & Discounts
- Refunds

## 11. Accounting

Double-entry finance, journals, banks, expenses and statements.

- Chart of Accounts
- Journal Entries
- Bank Accounts
- Expenses
- Budgets

## 12. Library

Catalog, copies, loans, reservations, fines and stock checks.

- Book Catalog
- Issue & Return
- Reservations

## 13. Transport

Routes, vehicles, drivers, stops, assignments and GPS readiness.

- Routes & Stops
- Vehicles
- Drivers & Attendants
- Student Assignments

## 14. Hostel

Rooms, beds, resident allocation, attendance and visitors.

- Rooms & Beds
- Bed Allocations
- Visitor Log

## 15. Inventory & Assets

Stock, procurement, assets, maintenance and warehouse control.

- Inventory Items
- Purchase Orders
- Stock Movements
- Fixed Assets

## 16. Communication

Announcements, circulars, campaigns and delivery tracking.

- Announcements
- Circulars
- Message Campaigns

## 17. Events & Activities

School events, competitions, seminars and registrations.

- School Events
- Competitions
- Event Registrations

## 18. Documents & Certificates

Templates, certificates, serials and public verification.

- Document Templates
- Certificate Requests
- Issued Certificates

## 19. Timetable

Class, teacher and exam timetables with conflict tracking.

- Class Timetable
- Teacher Substitutions
- Conflict Register

## 20. Student Welfare

Health, counseling, safeguarding and learning support records.

- Medical Profiles
- Clinic Visits
- Counseling Cases
- Safeguarding Cases
- Learning Support

## 21. Administration & SaaS

Users, roles, subscriptions, integrations, compliance and operations.

- Users & Access
- Roles & Permissions
- Subscription & Billing
- Integrations
- Feature Flags
- Data Imports
- Backup & Restore
- Audit Reviews
- Consent Management
- Data Retention

## 22. AI & Automation

Human-reviewed insights, automation rules and report generation.

- AI Insights
- Automation Rules
- Chatbot Knowledge
- Generated Reports

## 23. Reports & Analytics

Saved reports, scheduled exports, KPIs and audit-ready output.

- Report Catalog
- Scheduled Reports
- Export Jobs

## 24. Reception & Helpdesk

Support tickets, complaints, visitors and appointments.

- Support Tickets
- Complaints & Feedback
- Visitor Log
- Appointments

## Production boundary

The Flutter/Firebase build provides the complete operational UI and tenant-scoped data foundation. The following actions must be executed by a trusted Laravel API or Firebase Cloud Functions before live financial or regulatory use:

- Payment gateway callbacks, receipt idempotency, settlement and reconciliation.
- Double-entry posting, period close, reversals and financial approvals.
- Payroll calculation approval and bank disbursement.
- User provisioning, role elevation and support impersonation.
- Examination locking, moderation and final result publication.
- Certificate signing, serial allocation and public verification.
- Immutable audit-event ingestion and sensitive-record access logs.
- Backups, restore testing, retention enforcement and legal holds.
- AI model execution, privacy controls and human-review enforcement.
