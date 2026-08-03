begin;

-- Rebuilds one exact tenant/campus/year row. It is intentionally private:
-- clients receive SELECT-only access through RLS and cannot forge counts.
create or replace function private.rebuild_dashboard_summary(
  p_tenant_id text,
  p_campus_id text,
  p_academic_year_id text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_counts jsonb;
  v_status_counts jsonb;
begin
  if nullif(trim(p_tenant_id), '') is null
     or nullif(trim(p_campus_id), '') is null
     or nullif(trim(p_academic_year_id), '') is null then
    raise exception 'Dashboard summary scope cannot be empty';
  end if;

  select jsonb_build_object(
    'students', (
      select count(*) from public.students s
      where s.tenant_id = p_tenant_id
        and s.campus_id = p_campus_id
        and s.academic_year_id = p_academic_year_id
        and not s.is_archived
    ),
    'fee_invoices', (
      select count(*) from public.fee_invoices i
      where i.tenant_id = p_tenant_id
        and i.campus_id = p_campus_id
        and i.academic_year_id = p_academic_year_id
        and not i.is_archived
    ),
    'payments', (
      select count(*) from public.payments p
      where p.tenant_id = p_tenant_id
        and p.campus_id = p_campus_id
        and p.academic_year_id = p_academic_year_id
    ),
    'attendance_sessions', (
      select count(*) from public.attendance_sessions a
      where a.tenant_id = p_tenant_id
        and a.campus_id = p_campus_id
        and a.academic_year_id = p_academic_year_id
        and not a.is_archived
    ),
    'exams', (
      select count(*) from public.exams e
      where e.tenant_id = p_tenant_id
        and e.campus_id = p_campus_id
        and e.academic_year_id = p_academic_year_id
        and not e.is_archived
    ),
    'expenses', (
      select count(*) from public.expenses e
      where e.tenant_id = p_tenant_id
        and e.campus_id = p_campus_id
        and e.academic_year_id = p_academic_year_id
        and not e.is_archived
    )
  ) into v_counts;

  select jsonb_build_object(
    'students', coalesce((
      select jsonb_object_agg(status, total)
      from (
        select s.status, count(*) total
        from public.students s
        where s.tenant_id = p_tenant_id
          and s.campus_id = p_campus_id
          and s.academic_year_id = p_academic_year_id
          and not s.is_archived
        group by s.status
      ) grouped
    ), '{}'::jsonb),
    'fee_invoices', coalesce((
      select jsonb_object_agg(status, total)
      from (
        select i.status, count(*) total
        from public.fee_invoices i
        where i.tenant_id = p_tenant_id
          and i.campus_id = p_campus_id
          and i.academic_year_id = p_academic_year_id
          and not i.is_archived
        group by i.status
      ) grouped
    ), '{}'::jsonb),
    'payments', coalesce((
      select jsonb_object_agg(status, total)
      from (
        select p.status, count(*) total
        from public.payments p
        where p.tenant_id = p_tenant_id
          and p.campus_id = p_campus_id
          and p.academic_year_id = p_academic_year_id
        group by p.status
      ) grouped
    ), '{}'::jsonb),
    'attendance_sessions', coalesce((
      select jsonb_object_agg(status, total)
      from (
        select a.status, count(*) total
        from public.attendance_sessions a
        where a.tenant_id = p_tenant_id
          and a.campus_id = p_campus_id
          and a.academic_year_id = p_academic_year_id
          and not a.is_archived
        group by a.status
      ) grouped
    ), '{}'::jsonb),
    'exams', coalesce((
      select jsonb_object_agg(status, total)
      from (
        select e.status, count(*) total
        from public.exams e
        where e.tenant_id = p_tenant_id
          and e.campus_id = p_campus_id
          and e.academic_year_id = p_academic_year_id
          and not e.is_archived
        group by e.status
      ) grouped
    ), '{}'::jsonb),
    'expenses', coalesce((
      select jsonb_object_agg(status, total)
      from (
        select e.status, count(*) total
        from public.expenses e
        where e.tenant_id = p_tenant_id
          and e.campus_id = p_campus_id
          and e.academic_year_id = p_academic_year_id
          and not e.is_archived
        group by e.status
      ) grouped
    ), '{}'::jsonb)
  ) into v_status_counts;

  insert into public.dashboard_summaries (
    tenant_id,
    campus_id,
    academic_year_id,
    counts,
    status_counts,
    updated_at
  ) values (
    p_tenant_id,
    p_campus_id,
    p_academic_year_id,
    v_counts,
    v_status_counts,
    now()
  )
  on conflict (tenant_id, campus_id, academic_year_id) do update
  set counts = excluded.counts,
      status_counts = excluded.status_counts,
      updated_at = excluded.updated_at;
end;
$$;

revoke all on function private.rebuild_dashboard_summary(text, text, text)
  from public;

create or replace function private.refresh_dashboard_summary_after_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old jsonb := case when tg_op = 'INSERT' then null else to_jsonb(old) end;
  v_new jsonb := case when tg_op = 'DELETE' then null else to_jsonb(new) end;
begin
  if v_old is not null then
    perform private.rebuild_dashboard_summary(
      v_old->>'tenant_id',
      coalesce(v_old->>'campus_id', 'all'),
      coalesce(v_old->>'academic_year_id', 'all')
    );
  end if;

  if v_new is not null and (
    v_old is null
    or v_old->>'tenant_id' is distinct from v_new->>'tenant_id'
    or v_old->>'campus_id' is distinct from v_new->>'campus_id'
    or v_old->>'academic_year_id' is distinct from v_new->>'academic_year_id'
  ) then
    perform private.rebuild_dashboard_summary(
      v_new->>'tenant_id',
      coalesce(v_new->>'campus_id', 'all'),
      coalesce(v_new->>'academic_year_id', 'all')
    );
  elsif v_new is not null then
    perform private.rebuild_dashboard_summary(
      v_new->>'tenant_id',
      coalesce(v_new->>'campus_id', 'all'),
      coalesce(v_new->>'academic_year_id', 'all')
    );
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke all on function private.refresh_dashboard_summary_after_change()
  from public;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'students',
    'fee_invoices',
    'payments',
    'attendance_sessions',
    'exams',
    'expenses'
  ] loop
    execute format(
      'drop trigger if exists refresh_dashboard_summary on public.%I',
      table_name
    );
    execute format(
      'create trigger refresh_dashboard_summary after insert or update or delete on public.%I for each row execute function private.refresh_dashboard_summary_after_change()',
      table_name
    );
  end loop;
end;
$$;

-- Backfill every active campus/year combination without granting a client RPC.
do $$
declare
  scope record;
begin
  for scope in
    select c.tenant_id, c.id campus_id, y.id academic_year_id
    from public.campuses c
    join public.academic_years y on y.tenant_id = c.tenant_id
    where not c.is_archived and not y.is_archived
  loop
    perform private.rebuild_dashboard_summary(
      scope.tenant_id,
      scope.campus_id,
      scope.academic_year_id
    );
  end loop;
end;
$$;

commit;
