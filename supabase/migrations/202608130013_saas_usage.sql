begin;

create or replace function public.get_saas_usage(p_tenant_id text)
returns jsonb
security definer
language plpgsql
stable
set search_path = ''
as $$
declare
  v_result jsonb;
begin
  if (select auth.uid()) is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if not (
    private.has_permission(p_tenant_id, 'saas_admin.view')
    or private.has_permission(p_tenant_id, 'subscription.manage')
    or private.has_permission(p_tenant_id, 'tenant.manage')
  ) then
    raise exception 'permission denied' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'students', (
      select count(*) from public.students s
      where s.tenant_id = p_tenant_id and not s.is_archived
    ),
    'staffUsers', (
      select count(*) from public.tenant_members m
      where m.tenant_id = p_tenant_id and m.is_active
        and m.status = 'active'
        and not (m.roles && array['student','parent']::text[])
    ),
    'campuses', (
      select count(*) from public.campuses c
      where c.tenant_id = p_tenant_id and not c.is_archived
    ),
    'storageMb', 0,
    'smsThisMonth', 0,
    'emailThisMonth', 0,
    'aiActionsThisMonth', 0,
    'updatedAt', now()
  ) into v_result;
  return v_result;
end;
$$;

revoke all on function public.get_saas_usage(text) from public, anon;
grant execute on function public.get_saas_usage(text) to authenticated;

commit;
