# Firebase Data Migration Guide

The enterprise merge moves operational records from global collections into tenant-scoped paths.

## Old paths

```text
students/{studentId}
events/{eventId}
users/{uid}.tenantId + role
```

## New paths

```text
users/{uid}
tenants/{tenantId}
tenants/{tenantId}/members/{uid}
tenants/{tenantId}/students/{studentId}
tenants/{tenantId}/events/{eventId}
```

## Required migration order

1. Back up Firestore.
2. Create every `tenants/{tenantId}` document.
3. Add `tenantIds` and `activeTenantId` to every user profile.
4. Create `tenants/{tenantId}/members/{uid}` with roles, permissions, status, and campus scope.
5. Copy each student into the correct tenant subcollection.
6. Add these required student fields when missing:
   - `tenantId`
   - `isArchived: false`
   - `createdBy`
   - `createdAt`
   - `updatedAt`
7. Copy each event into the correct tenant subcollection.
8. Add these required event fields when missing:
   - `tenantId`
   - `isArchived: false`
   - `createdBy`
   - `createdAt`
   - `updatedAt`
9. Deploy `firestore.rules`, `storage.rules`, and `firestore.indexes.json`.
10. Test each role in the Firebase Emulator Suite before deleting old collections.

## Important

Do not migrate by allowing the Flutter client to assign roles or create tenants. Use a trusted Laravel command, Firebase Admin SDK script, or Cloud Function.

Archived records are retained. The application intentionally does not hard-delete students or events.
