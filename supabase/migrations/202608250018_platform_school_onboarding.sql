begin;

create or replace function public.provision_school_tenant(
  p_tenant_id text,
  p_school_name text,
  p_school_code text,
  p_timezone text,
  p_currency text,
  p_subscription jsonb,
  p_owner_user_id uuid,
  p_owner_email text,
  p_owner_name text,
  p_owner_must_change_password boolean,
  p_campus_id text,
  p_campus_code text,
  p_campus_name text,
  p_academic_year_id text,
  p_academic_year_name text,
  p_academic_year_start date,
  p_academic_year_end date,
  p_actor_user_id uuid
)
returns jsonb
security definer
language plpgsql
set search_path = ''
as $$
begin
  if p_tenant_id is null or trim(p_tenant_id) = '' then
    raise exception 'tenant id is required' using errcode = '22023';
  end if;
  if char_length(trim(p_school_name)) not between 2 and 160 then
    raise exception 'school name is invalid' using errcode = '22023';
  end if;
  if upper(trim(p_school_code)) !~ '^[A-Z0-9_-]{2,32}$' then
    raise exception 'school code is invalid' using errcode = '22023';
  end if;
  if p_owner_user_id is null or p_actor_user_id is null then
    raise exception 'owner and actor are required' using errcode = '22023';
  end if;
  if p_academic_year_end <= p_academic_year_start then
    raise exception 'academic year dates are invalid' using errcode = '22023';
  end if;

  insert into public.tenants (
    id, name, code, timezone, currency, is_active, subscription,
    active_academic_year_id
  ) values (
    p_tenant_id,
    trim(p_school_name),
    upper(trim(p_school_code)),
    coalesce(nullif(trim(p_timezone), ''), 'Asia/Karachi'),
    coalesce(nullif(upper(trim(p_currency)), ''), 'PKR'),
    true,
    coalesce(p_subscription, '{}'::jsonb),
    p_academic_year_id
  );

  insert into public.campuses (
    tenant_id, id, code, name, is_archived, created_by, updated_by
  ) values (
    p_tenant_id,
    p_campus_id,
    upper(trim(p_campus_code)),
    trim(p_campus_name),
    false,
    p_actor_user_id,
    p_actor_user_id
  );

  insert into public.academic_years (
    tenant_id, id, name, starts_on, ends_on, status, is_archived,
    created_by, updated_by
  ) values (
    p_tenant_id,
    p_academic_year_id,
    trim(p_academic_year_name),
    p_academic_year_start,
    p_academic_year_end,
    'active',
    false,
    p_actor_user_id,
    p_actor_user_id
  );

  insert into public.profiles as existing_profile (
    user_id, display_name, active_tenant_id
  ) values (
    p_owner_user_id,
    trim(p_owner_name),
    p_tenant_id
  )
  on conflict (user_id) do update
  set display_name = case
        when trim(existing_profile.display_name) = '' then excluded.display_name
        else existing_profile.display_name
      end,
      active_tenant_id = coalesce(
        existing_profile.active_tenant_id,
        excluded.active_tenant_id
      ),
      updated_at = now();

  insert into public.tenant_members (
    tenant_id, user_id, email, display_name, roles, permissions,
    denied_permissions, campus_ids, status, is_active,
    must_change_password, account_category
  ) values (
    p_tenant_id,
    p_owner_user_id,
    lower(trim(p_owner_email)),
    trim(p_owner_name),
    array['schoolOwner']::text[],
    array['*']::text[],
    '{}'::text[],
    array[p_campus_id]::text[],
    'active',
    true,
    p_owner_must_change_password,
    'staff'
  );

  insert into public.dashboard_summaries (
    tenant_id, campus_id, academic_year_id, counts, status_counts
  ) values (
    p_tenant_id,
    p_campus_id,
    p_academic_year_id,
    '{}'::jsonb,
    '{}'::jsonb
  ) on conflict do nothing;

  insert into public.audit_logs (
    tenant_id, actor_user_id, action, table_name, record_id, new_data
  ) values (
    p_tenant_id,
    p_actor_user_id,
    'platform.school.created',
    'tenants',
    p_tenant_id,
    jsonb_build_object(
      'schoolCode', upper(trim(p_school_code)),
      'ownerUserId', p_owner_user_id,
      'campusId', p_campus_id,
      'academicYearId', p_academic_year_id,
      'subscription', p_subscription
    )
  );

  return jsonb_build_object(
    'tenantId', p_tenant_id,
    'schoolCode', upper(trim(p_school_code)),
    'ownerUserId', p_owner_user_id,
    'campusId', p_campus_id,
    'academicYearId', p_academic_year_id
  );
end;
$$;

revoke all on function public.provision_school_tenant(
  text,text,text,text,text,jsonb,uuid,text,text,boolean,
  text,text,text,text,text,date,date,uuid
) from public, anon, authenticated;
grant execute on function public.provision_school_tenant(
  text,text,text,text,text,jsonb,uuid,text,text,boolean,
  text,text,text,text,text,date,date,uuid
) to service_role;

commit;
