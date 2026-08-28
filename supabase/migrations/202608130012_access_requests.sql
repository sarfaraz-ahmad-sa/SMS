begin;

create table if not exists public.access_requests (
  id uuid primary key default gen_random_uuid(),
  tenant_id text not null references public.tenants(id) on delete cascade,
  school_code text not null,
  full_name text not null check (char_length(trim(full_name)) between 2 and 120),
  roll_or_employee_id text not null check (char_length(roll_or_employee_id) <= 64),
  class_or_department text not null check (char_length(class_or_department) <= 120),
  email text not null check (char_length(email) <= 254),
  phone text not null check (char_length(phone) between 7 and 32),
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'cancelled')),
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  review_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists access_requests_tenant_status_created_idx
  on public.access_requests (tenant_id, status, created_at desc);
create index if not exists access_requests_rate_limit_idx
  on public.access_requests (tenant_id, email, created_at desc);

alter table public.access_requests enable row level security;
alter table public.access_requests force row level security;

drop policy if exists access_requests_manage on public.access_requests;
create policy access_requests_manage on public.access_requests
for all to authenticated
using (private.has_permission(tenant_id, 'users.manage'))
with check (private.has_permission(tenant_id, 'users.manage'));

grant select, update on public.access_requests to authenticated;
revoke insert, delete on public.access_requests from anon, authenticated;

drop trigger if exists access_requests_set_updated_at on public.access_requests;
create trigger access_requests_set_updated_at
before update on public.access_requests
for each row execute function private.set_updated_at();

commit;
