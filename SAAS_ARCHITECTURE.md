# CARTZ Link SMS — SaaS Architecture

This document describes the multi-tenant SaaS foundation added to the School
Management System and the roadmap to a production-ready platform.

## Concept

The app is now structured as a **multi-tenant SaaS**: one codebase serves many
schools ("tenants"). Each tenant has its own users, data, branding, and
subscription. Platform staff (CARTZ Link) act as `superAdmin`.

## Data model (Firestore)

```
tenants/{tenantId}                     -> Tenant  (name, logo, brandColor, subscription)
tenants/{tenantId}/students/{id}
tenants/{tenantId}/attendance/{id}
tenants/{tenantId}/exams/{id}
users/{uid}                            -> UserModel (email, displayName, tenantId, role)
```

Everything a school owns lives under `tenants/{tenantId}/…`. This makes tenant
isolation enforceable with a single Firestore security rule that checks the
requesting user's `tenantId` against the document path.

## Code added

| File | Purpose |
|------|---------|
| `lib/services/models/tenant.dart` | Tenant/organization model + Firestore (de)serialization |
| `lib/services/models/subscription.dart` | `SubscriptionTier` (trial/starter/pro/enterprise) + plan limits |
| `lib/services/models/user_role.dart` | RBAC roles (superAdmin/admin/teacher/student/parent) + permission helpers |
| `lib/services/UserModel.dart` | User now scoped to a tenant + role |
| `lib/services/tenant_service.dart` | Data-access layer for tenant/user lookups |
| `lib/services/session_state.dart` | App-wide session (current user, tenant, theme) via `provider` |
| `lib/theme/app_theme.dart` | Centralized Material 3 theme (light + dark) |

## Roles & permissions

`UserRole` exposes helpers such as `canManageTenant`, `canManagePlatform`, and
`canTakeAttendance` so screens can gate features by role.

## Roadmap to production SaaS

1. **Sign-up / onboarding flow** — create a tenant + first admin, seed a trial subscription.
2. **Firestore security rules** — enforce `tenantId` isolation and role checks server-side.
3. **Billing** — integrate Stripe (or similar) and sync `Subscription` state via webhooks/Cloud Functions.
4. **Per-tenant theming** — apply `Tenant.brandColor` / `logoUrl` at runtime so each school is branded.
5. **Real data screens** — replace the hardcoded student/exam/attendance data with tenant-scoped Firestore queries.
6. **Admin console** — user management, invites, plan/seat limits enforcement.

## Suggested Firestore security rule (starting point)

```
match /tenants/{tenantId}/{document=**} {
  allow read, write: if request.auth != null
    && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.tenantId == tenantId;
}
```
