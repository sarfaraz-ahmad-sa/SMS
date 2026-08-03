begin;

alter table public.tenants
  add column if not exists logo_url text,
  add column if not exists brand_color integer;

create or replace function public.update_tenant_profile(
  p_tenant_id text, p_name text, p_code text, p_timezone text,
  p_currency text, p_active_academic_year_id text, p_logo_url text
)
returns public.tenants
security definer
language plpgsql
set search_path = ''
as $$
declare
  previous public.tenants;
  updated public.tenants;
begin
  if not private.has_permission(p_tenant_id, 'tenant.manage')
     and not private.has_permission(p_tenant_id, 'school_setup.manage') then
    raise exception 'permission denied' using errcode = '42501';
  end if;
  if char_length(trim(p_name)) not between 2 and 160
     or char_length(trim(p_code)) not between 2 and 40
     or char_length(trim(p_timezone)) not between 3 and 80
     or char_length(trim(p_currency)) <> 3 then
    raise exception 'invalid school profile fields' using errcode = '22023';
  end if;
  if nullif(trim(p_active_academic_year_id), '') is not null and not exists (
    select 1 from public.academic_years year
    where year.tenant_id = p_tenant_id
      and year.id = trim(p_active_academic_year_id) and not year.is_archived
  ) then
    raise exception 'academic year does not belong to this school' using errcode = '22023';
  end if;
  if nullif(trim(p_logo_url), '') is not null
     and trim(p_logo_url) !~ '^https://[A-Za-z0-9]' then
    raise exception 'logo URL must use HTTPS' using errcode = '22023';
  end if;

  select * into previous from public.tenants where id = p_tenant_id for update;
  if not found then raise exception 'school not found' using errcode = 'P0002'; end if;
  update public.tenants set
    name = trim(p_name), code = upper(trim(p_code)), timezone = trim(p_timezone),
    currency = upper(trim(p_currency)),
    active_academic_year_id = nullif(trim(p_active_academic_year_id), ''),
    logo_url = nullif(trim(p_logo_url), '')
  where id = p_tenant_id returning * into updated;

  insert into public.audit_logs (
    tenant_id, actor_user_id, action, table_name, record_id, old_data, new_data
  ) values (
    p_tenant_id, (select auth.uid()), 'update', 'tenants', p_tenant_id,
    to_jsonb(previous), to_jsonb(updated)
  );
  return updated;
end;
$$;

revoke all on function public.update_tenant_profile(text,text,text,text,text,text,text) from public;
grant execute on function public.update_tenant_profile(text,text,text,text,text,text,text) to authenticated;

commit;
