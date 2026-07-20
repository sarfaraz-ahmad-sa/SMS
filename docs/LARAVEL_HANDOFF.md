# Laravel Handoff Plan

The Flutter repository is now prepared for a later Laravel transactional API.

## Authentication exchange

```text
POST /api/v1/auth/firebase/exchange
Authorization: Bearer <Firebase ID token>
```

Laravel should:

1. Verify the Firebase ID token.
2. Resolve the global user.
3. Validate tenant membership and subscription.
4. Load roles, permissions, campus scope, and academic year.
5. Return a short-lived Laravel API token and session context.

## Response shape

```json
{
  "data": {
    "access_token": "token",
    "user": {
      "id": "user-id",
      "firebase_uid": "firebase-uid",
      "display_name": "User",
      "roles": ["teacher"],
      "permissions": ["attendance.mark"],
      "campus_ids": ["main-campus"]
    },
    "tenant": {
      "id": "tenant-id",
      "name": "School",
      "timezone": "Asia/Karachi",
      "currency": "PKR"
    },
    "active_campus_id": "main-campus",
    "active_academic_year_id": "2026-2027"
  }
}
```

## API groups

```text
/api/v1/auth
/api/v1/me
/api/v1/context
/api/v1/school-setup
/api/v1/admissions
/api/v1/students
/api/v1/guardians
/api/v1/attendance
/api/v1/academics
/api/v1/examinations
/api/v1/fees
/api/v1/accounting
/api/v1/hr
/api/v1/payroll
/api/v1/library
/api/v1/transport
/api/v1/hostel
/api/v1/inventory
/api/v1/communications
/api/v1/documents
/api/v1/reports
```

## Mandatory backend controls

- Never accept tenant authority from a request body.
- Resolve tenant from token membership and trusted domain/context.
- Apply Laravel policies to every record operation.
- Use database transactions for fees, accounting, payroll, and result publication.
- Use idempotency keys for payments and imports.
- Record sensitive reads, exports, and modifications in audit logs.
