# Controlled Multi-School Onboarding — v3.8.0+25

## Production account policy

Public self-signup stays disabled. This prevents an unverified visitor from
creating a school, assigning roles or consuming a tenant subscription.

There are now three controlled paths:

1. A platform `superAdmin` creates a new school and its first `schoolOwner`.
2. A School Owner or authorized administrator creates staff, teacher, parent
   and student accounts from **School Accounts**.
3. A prospective user submits **Request a school login ID**. After verification,
   an administrator approves the request and receives a prefilled account form.

## Multi-school owners

When the owner email already belongs to a Supabase Auth user, onboarding reuses
that identity and adds a new `schoolOwner` membership. The existing tenant
switcher then lets the owner move between authorized schools without maintaining
separate passwords.

## One-time platform operator setup

The **New School** menu is intentionally invisible until an existing trusted
membership contains the `superAdmin` role. Establish the first platform operator
once from the Supabase SQL Editor after verifying the exact Auth user UUID and
tenant ID. Do not expose this operation through the public client:

```sql
update public.tenant_members
set roles = case
      when roles @> array['superAdmin']::text[] then roles
      else array_append(roles, 'superAdmin')
    end,
    permissions = array['*']::text[],
    updated_at = now()
where tenant_id = 'YOUR_PLATFORM_TENANT_ID'
  and user_id = 'YOUR_VERIFIED_AUTH_USER_UUID'::uuid
  and is_active = true;
```

Confirm that exactly one intended row changed. Keep the number of platform
operators minimal; normal School Owners do not need this role.

## Demo versus real schools

- Use **Invite** for real schools. Supabase sends the owner a secure email link.
- Use **Demo password** only for controlled demonstrations. A cryptographically
  generated strong temporary password is shown once and the owner must replace
  it at first login.
- Never publish shared credentials on a public page or reuse one demo owner
  between unrelated schools.

## Security model

- The Flutter client never receives the Supabase service-role key.
- The Edge Function verifies the caller's authenticated `superAdmin` role.
- The PostgreSQL provisioning RPC is executable only by `service_role`.
- Tenant, campus, academic year, owner membership, dashboard seed and audit log
  are created in one database transaction.
- If a new Auth user was created but the database transaction fails, the Edge
  Function removes that new user as compensation.
- School codes are normalized and unique.

## Deploy to the current Supabase project

From the project root:

```bash
npx supabase login
npx supabase link --project-ref mmixwroevlfucxialdix
npx supabase db push
npx supabase functions deploy platform-onboarding --project-ref mmixwroevlfucxialdix
npx supabase functions deploy request-school-access --project-ref mmixwroevlfucxialdix
npx supabase functions deploy school-accounts --project-ref mmixwroevlfucxialdix
```

In Supabase Authentication, keep public self-signup disabled and configure the
production Site URL and allowed redirect URLs before sending owner invitations.

Then deploy the Flutter web application:

```bash
vercel --prod
```

## Acceptance check

1. Sign in with a real `superAdmin` membership.
2. Open **New School**, create a trial school and verify success details.
3. Sign in as the new owner and confirm the new tenant/campus/year context.
4. Create one staff account and one portal account from **School Accounts**.
5. Submit a public access request with the school code; approve it and confirm
   the account form is prefilled.
6. Verify a non-super-admin cannot open or call platform onboarding.
7. Verify an existing owner email gains the second school in the tenant switcher.

The delivery environment performs static source validation and role tests. Run
`flutter analyze`, `flutter test`, and a release web build on the development Mac
before the final production deployment.
