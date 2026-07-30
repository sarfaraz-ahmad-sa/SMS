# Production Readiness and External Integrations

## Included in the source

- Multi-tenant membership and tenant switching.
- Server-derived role permissions and campus scope.
- Student, parent, teacher and administrative account provisioning.
- Temporary-password and email-link account setup.
- Mandatory first-login password replacement with recent-authentication verification.
- Student and guardian master-profile linking with personal-scope Firestore rules.
- Portal-account versus paid staff-seat accounting.
- Account suspension, reactivation, password reset and setup-email resend.
- SaaS plans, module entitlements, usage limits and subscription guards.
- Trusted student, campus and staff quota enforcement.
- Approval inbox and append-only audit records.
- Responsive desktop, tablet and mobile shell with tenant branding and dark mode.
- Twenty-four ERP modules and 105 tenant-scoped workflow collections.

## Environment configuration still required

These capabilities require credentials, contracts or physical devices and therefore cannot be preconfigured in a distributable source archive:

| Capability | Required production configuration |
|---|---|
| Online payments | Gateway merchant account, webhook secret, idempotency and settlement reconciliation |
| SMS | Provider account, sender ID, templates, delivery callbacks and quota pricing |
| WhatsApp | Approved business account, templates, access token and webhook verification |
| Email | Transactional provider/domain, SPF, DKIM, DMARC, templates and bounce callbacks |
| Push notifications | APNs credentials, Firebase Cloud Messaging configuration and device-token lifecycle |
| GPS transport | Vehicle device/provider API, webhook/API credentials and location retention policy |
| Biometric attendance | Device model, network protocol, pairing credentials and clock-sync rules |
| Bank payroll | Bank file/API specification, maker-checker approval and encryption keys |
| Signed certificates | Organisation signing key, public verification URL and key-rotation policy |
| Backups | Export destination, retention, encryption, restore drills and access controls |
| Custom domains | DNS, TLS certificate, Firebase Hosting or reverse-proxy configuration |
| Mobile release | Production bundle IDs, signing certificates, store accounts and privacy URLs |

## Required deployment order

1. Back up the existing Firebase project.
2. Enable Email/Password authentication and configure authorized domains.
3. Deploy Functions, Firestore rules, indexes and Storage rules.
4. Run the SaaS migration for existing tenants.
5. Run portal-link migration in dry-run mode and review the output.
6. Apply the portal-link migration.
7. Create test student, parent, teacher and administrator accounts from **School Accounts**.
8. Execute the access-control test matrix below.
9. Configure external providers one at a time in a test project.
10. Promote provider credentials through a secret manager; never store them in Flutter source or Firestore documents readable by clients.

## Minimum account and permission test matrix

- Student A can see Student A records and cannot read Student B records.
- Parent A can see every linked child and no unlinked child.
- Teacher sees only assigned modules and campus scope.
- Accountant cannot publish results or modify roles.
- School administrator cannot assign a role above their delegation ceiling.
- Suspended membership cannot read tenant data.
- Expired or suspended subscription cannot access plan-gated modules through navigation, search or direct route.
- Portal accounts do not increase `staffUsers`; teacher and administrative accounts do.
- First login cannot skip password replacement or clear the setup flag without recent authentication.
- Password reset, role change, suspension, approval and quota operations create audit events.
- Direct Firestore writes cannot bypass metered creation or personal-scope relationships.

## Release verification

Run on the development Mac after extracting the delivery archive:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build web --release --no-wasm-dry-run
```

Then deploy to a non-production Firebase project and complete Emulator Suite or equivalent integration testing before production promotion.
