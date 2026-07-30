# Production Checklist

## Delivered application controls

- [x] Multi-tenant memberships and school switching
- [x] Server-derived role permissions and campus scope
- [x] Administrator-created student, parent, teacher and staff accounts
- [x] Temporary password and email-link setup methods
- [x] Mandatory first-login password replacement
- [x] Student and guardian personal-scope Firestore access
- [x] Portal-account versus paid staff-seat classification
- [x] Account suspension, reactivation and password reset
- [x] SaaS plans, feature entitlements and quota enforcement
- [x] Approval inbox and append-only audit records for trusted operations
- [x] Responsive tenant-branded light/dark UI shell
- [x] Firestore default-deny collection coverage for all 105 workflows

## Firebase environment

- [ ] Back up the existing Firebase project
- [ ] Run `flutterfire configure` for the production application IDs
- [ ] Enable Email/Password authentication
- [ ] Enable Google authentication only when the organisation requires it
- [ ] Configure authorized web domains and password-reset redirect URLs
- [ ] Customise authentication email templates and sender domain
- [ ] Deploy Cloud Functions
- [ ] Deploy Firestore rules and indexes
- [ ] Deploy Storage rules
- [ ] Run Firestore Emulator Suite tenant-isolation tests
- [ ] Create the first tenant through trusted Admin tooling
- [ ] Run SaaS and portal-link migrations for existing tenants
- [ ] Store provider secrets in Secret Manager, not Flutter or Firestore

## Flutter release

- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Run `flutter analyze`
- [ ] Run `flutter test`
- [ ] Run `flutter build web --release --no-wasm-dry-run`
- [ ] Run Android debug and signed release builds
- [ ] Run iOS build and signing validation
- [ ] Replace app icons and splash assets with approved production branding
- [ ] Add Urdu localisation and RTL verification when required
- [ ] Complete accessibility, keyboard and screen-reader testing
- [ ] Configure crash and performance monitoring

## Account acceptance tests

- [ ] School admin can create a student login with a temporary password
- [ ] Student is forced to replace the password at first login
- [ ] Student can read only their linked attendance, fees and results
- [ ] Parent account creation is blocked until at least one child is linked
- [ ] Parent can read every linked child and no unlinked child
- [ ] Teacher sees only assigned role modules and campus scope
- [ ] Suspended membership cannot access tenant data
- [ ] Direct module URLs cannot bypass role or plan entitlements
- [ ] Portal accounts do not increase paid `staffUsers`
- [ ] Teacher and administrative accounts do increase paid `staffUsers`
- [ ] Role changes, suspension and password operations generate audit events

## External providers

- [ ] Payment gateway callbacks, idempotency and reconciliation
- [ ] SMS sender ID, templates, callbacks and quota accounting
- [ ] Transactional email SPF/DKIM/DMARC, templates and bounce handling
- [ ] WhatsApp Business templates and webhook verification
- [ ] Push notification device-token lifecycle
- [ ] GPS and biometric device integration
- [ ] Payroll bank integration and maker-checker approval
- [ ] Signed certificate verification and key rotation
- [ ] Scheduled encrypted backups and restore drills

## Android and iOS identity

- [ ] Replace `com.example.school_management` with the production application ID
- [ ] Re-run `flutterfire configure` after changing application IDs
- [ ] Configure Play App Signing and iOS distribution certificates
- [ ] Remove debug release signing
- [ ] Add privacy policy, terms and support URLs

## Security and operations

- [ ] MFA for privileged roles
- [ ] Quarterly access reviews
- [ ] Rate limiting and abuse monitoring
- [ ] Malware scanning for uploaded documents
- [ ] Data retention, consent and deletion procedures
- [ ] Incident response and breach-notification plan
- [ ] Backup restore test with documented recovery objectives
- [ ] Monitoring and alerting for failed Functions and provider callbacks
