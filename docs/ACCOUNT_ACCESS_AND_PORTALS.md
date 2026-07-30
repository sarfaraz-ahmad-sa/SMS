# Account Access and Role-Secured Portals

## Required Firebase setup

Enable Email/Password authentication. Deploy Functions, Firestore rules, indexes and Storage rules before creating production accounts. Password-reset and setup-link delivery also requires an authorized Firebase Authentication email domain/template.

## Administrator account creation

Authorized administrators open **School Accounts** and provide name, email, role, campus scope and setup method.

- **Temporary password:** a strong password is generated or entered. The user must replace it at first login.
- **Email setup link:** Firebase sends the password setup/reset link. Delivery depends on the configured Authentication email provider and authorized domain.

The Cloud Function validates subscription status, staff quota, delegated-role authority and linked profile compatibility before committing the account. It creates or reuses the Firebase Authentication identity, writes `users/{uid}`, writes `tenants/{tenantId}/members/{uid}`, derives permissions on the server and records an append-only audit event.

Student and parent logins are classified as **portal accounts** and do not consume a paid staff seat. Teacher and administrative roles are classified as **staff accounts** and are counted against the plan's staff-user quota. Role changes, suspension, reactivation, usage refresh and legacy migration all preserve this distinction.

## Linked portal identities

Portal accounts require an existing ERP master record:

| Role | Required profile | Result |
|---|---|---|
| Student | `students/{recordId}` | User can access only records linked to that student |
| Parent | `guardians/{recordId}` with at least one `student_guardians` link | User can access only linked children |
| Teacher/Class Teacher | `teachers/{recordId}` | Membership is linked to the teacher master profile |
| Administrative roles | None | Access is defined by role, explicit permissions and campus scope |

Student-sensitive records carry trusted `studentRecordId`, `authUid` and `guardianUids` relationship metadata. Firestore rules validate that metadata against the student master record. A user cannot gain access by guessing a document ID or changing client-side navigation.

## First login

A temporary-password user is routed to a non-dismissible secure-account screen. The new password must contain uppercase, lowercase, number and special character and be at least 10 characters. The client reauthenticates with the temporary password and refreshes the ID token. The trusted completion function requires a recent authentication event, validates and applies the new password, verifies that initial setup is still pending, clears `mustChangePassword` and audits the event.

## Ongoing account management

Authorized administrators can:

- change role and campus scope;
- reset a temporary password;
- resend a setup email;
- suspend or reactivate membership;
- copy newly generated credentials;
- review linked ERP identity and account state.

Shared Authentication identities are protected: a tenant administrator cannot reset a global password when the same identity belongs to multiple schools.

## Existing data migration

After the SaaS tenant migration, run the portal-link migration in dry-run mode first:

```bash
cd tools/firebase_admin
npm install
export GOOGLE_APPLICATION_CREDENTIALS=/secure/firebase-service-account.json
export FIREBASE_PROJECT_ID=your-project-id
export DRY_RUN=true
npm run backfill:portal-links
```

Review the output, then apply:

```bash
export DRY_RUN=false
npm run backfill:portal-links
```

Set `TENANT_ID` to limit the migration to one school.

## Security verification

Before release, verify at minimum:

1. A student cannot read another student's attendance, fees or results.
2. A parent can read all linked children and no unlinked child.
3. A teacher sees only authorized modules and assigned campus scope.
4. Suspended users cannot read tenant data.
5. Expired subscriptions cannot access plan-gated modules.
6. Direct URLs do not bypass role or plan authorization.
7. Password reset and first-login flows produce audit events.
