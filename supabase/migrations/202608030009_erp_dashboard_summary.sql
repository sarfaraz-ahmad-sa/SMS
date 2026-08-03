begin;

-- Keep one exact summary row for the active school/campus/year scope. Students
-- and payments use dedicated relational tables; the remaining ERP catalog is
-- stored in erp_records during the PostgreSQL migration.
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
  v_erp_counts jsonb;
  v_erp_status_counts jsonb;
begin
  if nullif(trim(p_tenant_id), '') is null
     or nullif(trim(p_campus_id), '') is null
     or nullif(trim(p_academic_year_id), '') is null then
    raise exception 'Dashboard summary scope cannot be empty';
  end if;

  select coalesce(jsonb_object_agg(grouped.collection, grouped.total), '{}'::jsonb)
  into v_erp_counts
  from (
    select record.collection, count(*) total
    from public.erp_records record
    where record.tenant_id = p_tenant_id
      and record.campus_id = p_campus_id
      and record.academic_year_id = p_academic_year_id
      and not record.is_archived
      and record.collection not in ('students', 'payments')
    group by record.collection
  ) grouped;

  select coalesce(jsonb_object_agg(grouped.collection, grouped.statuses), '{}'::jsonb)
  into v_erp_status_counts
  from (
    select status_totals.collection,
           jsonb_object_agg(status_totals.status_key, status_totals.total) statuses
    from (
      select record.collection,
             coalesce(nullif(lower(trim(record.status)), ''), 'unknown') status_key,
             count(*) total
      from public.erp_records record
      where record.tenant_id = p_tenant_id
        and record.campus_id = p_campus_id
        and record.academic_year_id = p_academic_year_id
        and not record.is_archived
        and record.collection not in ('students', 'payments')
      group by record.collection,
               coalesce(nullif(lower(trim(record.status)), ''), 'unknown')
    ) status_totals
    group by status_totals.collection
  ) grouped;

  v_counts := jsonb_build_object(
    'students', (
      select count(*) from public.students student
      where student.tenant_id = p_tenant_id
        and student.campus_id = p_campus_id
        and student.academic_year_id = p_academic_year_id
        and not student.is_archived
    ),
    'payments', (
      select count(*) from public.payments payment
      where payment.tenant_id = p_tenant_id
        and payment.campus_id = p_campus_id
        and payment.academic_year_id = p_academic_year_id
    )
  ) || v_erp_counts;

  v_status_counts := jsonb_build_object(
    'students', coalesce((
      select jsonb_object_agg(grouped.status, grouped.total)
      from (
        select lower(student.status) status, count(*) total
        from public.students student
        where student.tenant_id = p_tenant_id
          and student.campus_id = p_campus_id
          and student.academic_year_id = p_academic_year_id
          and not student.is_archived
        group by lower(student.status)
      ) grouped
    ), '{}'::jsonb),
    'payments', coalesce((
      select jsonb_object_agg(grouped.status, grouped.total)
      from (
        select lower(payment.status) status, count(*) total
        from public.payments payment
        where payment.tenant_id = p_tenant_id
          and payment.campus_id = p_campus_id
          and payment.academic_year_id = p_academic_year_id
        group by lower(payment.status)
      ) grouped
    ), '{}'::jsonb)
  ) || v_erp_status_counts;

  insert into public.dashboard_summaries (
    tenant_id, campus_id, academic_year_id, counts, status_counts, updated_at
  ) values (
    p_tenant_id, p_campus_id, p_academic_year_id,
    v_counts, v_status_counts, now()
  )
  on conflict (tenant_id, campus_id, academic_year_id) do update
  set counts = excluded.counts,
      status_counts = excluded.status_counts,
      updated_at = excluded.updated_at;
end;
$$;

revoke all on function private.rebuild_dashboard_summary(text, text, text)
  from public;

drop trigger if exists refresh_dashboard_summary on public.erp_records;
create trigger refresh_dashboard_summary
after insert or update or delete on public.erp_records
for each row execute function private.refresh_dashboard_summary_after_change();

do $$
declare
  scope record;
begin
  for scope in
    select campus.tenant_id,
           campus.id campus_id,
           academic_year.id academic_year_id
    from public.campuses campus
    join public.academic_years academic_year
      on academic_year.tenant_id = campus.tenant_id
    where not campus.is_archived and not academic_year.is_archived
  loop
    perform private.rebuild_dashboard_summary(
      scope.tenant_id, scope.campus_id, scope.academic_year_id
    );
  end loop;
end;
$$;

commit;
