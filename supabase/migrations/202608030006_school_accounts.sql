begin;

alter table public.tenant_members
  add column if not exists account_category text not null default 'staff'
    check (account_category in ('staff', 'portal')),
  add column if not exists suspension_reason text,
  add column if not exists last_login_at timestamptz;

create index if not exists tenant_members_directory_idx
  on public.tenant_members (tenant_id, is_active, display_name, user_id);

-- Membership and authentication changes are only made by the trusted
-- school-accounts Edge Function. Browser clients retain read-only access.
revoke insert, update, delete on public.tenant_members from authenticated;

commit;
