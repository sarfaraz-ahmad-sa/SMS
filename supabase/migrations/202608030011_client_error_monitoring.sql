begin;

create table if not exists public.client_error_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id text references public.tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  fingerprint text not null,
  message text not null,
  stack_trace text,
  route text,
  platform text not null,
  app_version text not null,
  severity text not null default 'error'
    check (severity in ('warning', 'error', 'fatal')),
  context jsonb not null default '{}'::jsonb
    check (jsonb_typeof(context) = 'object'),
  occurred_at timestamptz not null default now()
);

create index if not exists client_error_events_tenant_time_idx
  on public.client_error_events (tenant_id, occurred_at desc);
create index if not exists client_error_events_fingerprint_time_idx
  on public.client_error_events (fingerprint, occurred_at desc);

alter table public.client_error_events enable row level security;
alter table public.client_error_events force row level security;

drop policy if exists client_error_events_read_authorized
  on public.client_error_events;
create policy client_error_events_read_authorized
on public.client_error_events
for select to authenticated
using (
  tenant_id is not null
  and private.is_active_member(tenant_id)
  and private.has_permission(tenant_id, 'audit.view')
);

revoke insert, update, delete on public.client_error_events from authenticated;
grant select on public.client_error_events to authenticated;

create or replace function public.report_client_error(
  p_message text,
  p_stack_trace text default null,
  p_route text default null,
  p_platform text default 'unknown',
  p_app_version text default 'unknown',
  p_severity text default 'error',
  p_context jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := (select auth.uid());
  active_tenant text;
  normalized_message text := left(coalesce(nullif(trim(p_message), ''), 'Unknown client error'), 2000);
  normalized_stack text := left(coalesce(p_stack_trace, ''), 12000);
  normalized_severity text := lower(coalesce(nullif(trim(p_severity), ''), 'error'));
  event_id uuid;
begin
  if actor is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if normalized_severity not in ('warning', 'error', 'fatal') then
    normalized_severity := 'error';
  end if;
  if jsonb_typeof(coalesce(p_context, '{}'::jsonb)) <> 'object'
     or octet_length(coalesce(p_context, '{}'::jsonb)::text) > 16384 then
    raise exception 'invalid error context' using errcode = '22023';
  end if;
  if (
    select count(*)
    from public.client_error_events event
    where event.user_id = actor
      and event.occurred_at >= now() - interval '10 minutes'
  ) >= 30 then
    raise exception 'client error rate limit exceeded' using errcode = 'P0001';
  end if;

  select profile.active_tenant_id into active_tenant
  from public.profiles profile
  where profile.user_id = actor;
  if active_tenant is not null and not private.is_active_member(active_tenant) then
    active_tenant := null;
  end if;

  insert into public.client_error_events (
    tenant_id,
    user_id,
    fingerprint,
    message,
    stack_trace,
    route,
    platform,
    app_version,
    severity,
    context
  ) values (
    active_tenant,
    actor,
    encode(extensions.digest(normalized_message || E'\n' || left(normalized_stack, 1000), 'sha256'), 'hex'),
    normalized_message,
    nullif(normalized_stack, ''),
    left(nullif(trim(p_route), ''), 500),
    left(coalesce(nullif(trim(p_platform), ''), 'unknown'), 100),
    left(coalesce(nullif(trim(p_app_version), ''), 'unknown'), 100),
    normalized_severity,
    coalesce(p_context, '{}'::jsonb)
  )
  returning id into event_id;

  return event_id;
end;
$$;

revoke all on function public.report_client_error(text,text,text,text,text,text,jsonb)
  from public;
grant execute on function public.report_client_error(text,text,text,text,text,text,jsonb)
  to authenticated;

commit;
