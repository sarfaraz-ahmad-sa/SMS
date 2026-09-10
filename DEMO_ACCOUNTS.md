# Fictional demo setup

No live accounts or shared passwords are bundled. The current default is Supabase, so `start-demo.cmd` requires ignored `config/demo.json` pointing at a separate disposable project. Do not use the old developer login as authentication evidence. The Firebase-only developer shortcut is debug-only and remains a local UI development aid.

1. Create a separate empty backend and apply all migrations and functions per INSTALLATION.md. Disable outbound integrations. Use temporary-password setup instead of sending mail to fictional addresses.
2. Create the initial platform operator administratively. Use the onboarding screen to create **Example Academy (Fictional Demo)**, campus **Fictional Main Campus**, academic year **2026–2027**, and a school owner. Provision the following accounts through School Accounts with unique locally generated passwords. Never publish the platform operator in a public demo.
3. Create a second fictional school and separate user to test cross-school rejection. Create two students, link the student account to one and parent to that student's guardian. Verify access to the other student is denied.
4. Create a small class, subject, timetable, attendance session, invoice and exam with explicitly fictional labels and nominal amounts. Do not import customer exports or execute legacy migration utilities on production.
5. Demo payments are sample records only. Do not connect real payment gateways or trigger SMS/email campaigns.
6. Reset by recreating the disposable sandbox and repeating these steps. This is a documented manual reset; an automated Supabase seed/reset has not been verified. The in-memory Firebase demo resets on application restart.

| Role identifier | Fictional account |
| --- | --- |
| superAdmin | operator@example.invalid |
| schoolOwner | owner@example.invalid |
| principal | principal@example.invalid |
| vicePrincipal | viceprincipal@example.invalid |
| adminStaff | admin@example.invalid |
| accountant | accountant@example.invalid |
| teacher | teacher@example.invalid |
| classTeacher | classteacher@example.invalid |
| student | student@example.invalid |
| parent | parent@example.invalid |
| librarian | librarian@example.invalid |
| hrManager | hr@example.invalid |
| receptionist | reception@example.invalid |
| transportManager | transport@example.invalid |
| hostelManager | hostel@example.invalid |
| itAdmin | itadmin@example.invalid |

School Admin is represented by School Owner, leadership, or Admin Staff according to the permissions required; there is no separate schoolAdmin enum. These are setup specifications, **not existing logins**. Passwords must be generated privately and must satisfy backend requirements. Test first-login change, reset, logout, suspension and role changes for each relevant role before recording the demo.
