# First-login Password Completion Fix — 3.6.1+21

## Root cause and protection

The production app runs in Supabase-primary mode. Supabase authentication and School Accounts backend failures were not handled by the first-login screen, so every such failure appeared as the same generic password error. An optional verification step could also report failure after password setup had already completed.

The screen now:

- rejects a new password that matches the temporary password;
- maps Supabase credential, password-policy and network errors;
- shows School Accounts backend errors;
- treats email verification as optional after successful password completion;
- treats post-change token refresh as optional after the trusted update succeeds;
- refreshes a rotated Supabase session and retries the idempotent membership update once;
- clearly reports the rare case where the password changed but membership finalization did not.

## Required production deployment

Deploy the checked-in School Accounts function, then rebuild the Vercel frontend:

```bash
npx supabase functions deploy school-accounts --project-ref mmixwroevlfucxialdix
vercel --prod
```

The frontend fix improves validation and recovery, but the deployed Edge Function must contain the `completePasswordChange` action for the account flag to be finalized.
