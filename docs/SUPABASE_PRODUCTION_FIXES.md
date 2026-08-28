# Supabase production fixes

Apply the migrations in filename order, then deploy both Edge Functions:

```bash
supabase db push
supabase functions deploy school-accounts
supabase functions deploy request-school-access
```

Configure the deployed web origin in Supabase Authentication redirect URLs and
set `SUPABASE_AUTH_REDIRECT_URL` in Vercel. The Vercel build now passes that
value to Flutter and explicitly enables the Supabase-primary backend.

## Validation

Run the SQL files in `supabase/tests` against a non-production database after
all migrations. `role_access_matrix.sql` validates student, parent, teacher and
admin visibility. `operational_jobs.sql` validates export and backup queue
authorization. Both tests roll back their fixtures.

Run the Edge Function role hierarchy tests with Deno:

```bash
deno test supabase/functions/_shared/role_permissions_test.ts
```

## Operational jobs

CSV export of currently loaded, RLS-visible rows works directly in Flutter Web.
Full exports and manual backups are now inserted only through trusted RPCs.
Deploy an authenticated worker to consume queued `export_jobs` and
`backup_jobs`; the client deliberately does not hold storage or database backup
credentials. The worker must update status, row count/file metadata, retention,
and restore-test results after completing each job.
