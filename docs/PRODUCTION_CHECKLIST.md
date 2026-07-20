# Production Checklist

## Firebase

- [ ] Run `flutterfire configure`
- [ ] Enable Email/Password authentication
- [ ] Enable and configure Google authentication
- [ ] Deploy Firestore rules
- [ ] Deploy indexes
- [ ] Deploy Storage rules
- [ ] Configure authorized web domains
- [ ] Test rules with Firebase Emulator Suite
- [ ] Create the first tenant through trusted tooling
- [ ] Create memberships for all test accounts

## Flutter

- [ ] Run `flutter analyze`
- [ ] Run `flutter test`
- [ ] Run Android debug and release builds
- [ ] Run iOS build and signing validation
- [ ] Run web release build
- [ ] Replace app icons and splash assets
- [ ] Add Urdu localization and RTL verification
- [ ] Add accessibility testing
- [ ] Add crash and performance monitoring
- [ ] Add push notification implementation

## Android

- [ ] Replace `com.example.school_management` with the production application ID
- [ ] Re-run `flutterfire configure` after changing application ID
- [ ] Configure Play App Signing
- [ ] Remove debug release signing
- [ ] Add privacy policy URL

## SaaS security

- [ ] MFA for privileged roles
- [ ] Access reviews
- [ ] Tenant isolation tests
- [ ] Audit logs
- [ ] Backup and restore tests
- [ ] Rate limiting
- [ ] Malware scanning for uploaded documents
- [ ] Data retention and consent policies
- [ ] Incident response plan

## Laravel transition

- [ ] Central SaaS database
- [ ] Tenant database provisioning
- [ ] Firebase token exchange endpoint
- [ ] Server-enforced RBAC
- [ ] Redis queues and cache
- [ ] Object storage
- [ ] Payment reconciliation
- [ ] Monitoring and alerting
