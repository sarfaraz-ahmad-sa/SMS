# SaaS Architecture

## Current Firebase phase

```text
Firebase Auth identity
        |
users/{uid}
        |
activeTenantId / tenantIds
        |
tenants/{tenantId}/members/{uid}
        |
roles + permissions + campus scope
        |
tenants/{tenantId}/students|events|...
```

### Trust boundaries

1. Firebase Authentication proves identity.
2. Tenant membership determines which school can be opened.
3. Membership roles and permissions determine visible modules.
4. Firestore rules validate every mobile/web read and write.
5. The client cannot create tenants, assign roles, or activate subscriptions.

## Target enterprise phase

```text
Flutter Parent / Student / Staff apps
Flutter Web administration portal
                 |
        WAF / Load Balancer
                 |
          Laravel API nodes
                 |
     Redis / Queue / Object Storage
                 |
Central SaaS DB + tenant MySQL databases
```

### Central control-plane database

- tenants
- tenant_domains
- global_users
- user_tenant_memberships
- plans
- subscriptions
- tenant_database_instances
- provisioning_jobs
- platform_audit_logs

### Tenant database

- school setup
- users and role assignments
- students and guardians
- attendance
- examinations
- fees and accounting
- HR and payroll
- library
- transport
- hostel
- inventory
- communication
- documents
- audit logs

## Migration approach

1. Keep Firebase Authentication.
2. Exchange the Firebase ID token with Laravel.
3. Laravel validates Firebase identity and tenant membership.
4. Laravel issues a short-lived application token.
5. Move transactional modules from Firestore to tenant MySQL databases.
6. Keep Firestore only for selected realtime features if required.

## Scale principles

- Stateless Laravel nodes
- Redis cache and queues
- Tenant-aware background jobs
- Database-per-tenant or hybrid tenant isolation
- Private object storage with signed URLs
- Outbox pattern for notifications and integrations
- Immutable financial and audit records
- Read replicas or analytics warehouse for large reporting workloads
