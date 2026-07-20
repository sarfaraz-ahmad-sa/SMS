# Firestore Data Model

## Platform collections

```text
users/{uid}
tenants/{tenantId}
tenants/{tenantId}/members/{uid}
accessRequests/{requestId}
```

## Tenant collections currently implemented

```text
tenants/{tenantId}/students/{studentId}
tenants/{tenantId}/events/{eventId}
```

All future Firebase-phase operational collections must remain under the tenant document.

## User document

The user document stores only identity preferences and the IDs of schools the user can select. It must not be used as the only source of role authority.

Recommended fields:

```text
email
displayName
photoUrl
tenantIds[]
activeTenantId
activeCampusId
activeAcademicYearId
isActive
createdAt
updatedAt
```

## Membership document

Roles and permissions are tenant-specific:

```text
status: active | inactive | suspended
roles[]
permissions[]
deniedPermissions[]
campusIds[]
activeCampusId
activeAcademicYearId
createdAt
updatedAt
```

## Data creation policy

The following operations must run through a trusted backend:

- Tenant creation
- Subscription activation
- Membership creation
- Role and permission assignment
- Cross-tenant reporting
- Bulk user provisioning
- Permanent record deletion

## Student records

Student deletion is implemented as archiving:

```text
isArchived
archivedAt
archivedBy
```

This keeps history and avoids accidental destructive removal.
