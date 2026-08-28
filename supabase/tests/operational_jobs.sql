begin;

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('00000000-0000-0000-0000-000000000000','61000000-0000-0000-0000-000000000001','authenticated','authenticated','jobs-admin@example.invalid','',now(),'{}','{}',now(),now()),
  ('00000000-0000-0000-0000-000000000000','62000000-0000-0000-0000-000000000002','authenticated','authenticated','jobs-student@example.invalid','',now(),'{}','{}',now(),now());

insert into public.tenants (id, name, code)
values ('jobs-tenant', 'Operational Jobs School', 'JOBS');
insert into public.campuses (tenant_id, id, code, name)
values ('jobs-tenant', 'jobs-campus', 'MAIN', 'Main Campus');
insert into public.academic_years (
  tenant_id, id, name, starts_on, ends_on, status
) values (
  'jobs-tenant', 'jobs-year', '2026-2027',
  '2026-04-01', '2027-03-31', 'active'
);
insert into public.tenant_members (
  tenant_id, user_id, email, roles, permissions, campus_ids
) values
  ('jobs-tenant','61000000-0000-0000-0000-000000000001','jobs-admin@example.invalid',array['schoolOwner'],array['*'],array['jobs-campus']),
  ('jobs-tenant','62000000-0000-0000-0000-000000000002','jobs-student@example.invalid',array['student'],array['students.view'],array['jobs-campus']);

set local role authenticated;
select set_config('request.jwt.claim.sub','61000000-0000-0000-0000-000000000001',true);

do $$
declare export_job public.erp_records;
declare backup_job public.erp_records;
begin
  export_job := public.request_export_job(
    'jobs-tenant','jobs-campus','jobs-year','students','CSV'
  );
  backup_job := public.request_backup_job(
    'jobs-tenant','jobs-campus','jobs-year'
  );
  if export_job.collection <> 'export_jobs' or export_job.status <> 'Queued' then
    raise exception 'trusted export queue failed';
  end if;
  if backup_job.collection <> 'backup_jobs' or backup_job.status <> 'Queued' then
    raise exception 'trusted backup queue failed';
  end if;
end $$;

select set_config('request.jwt.claim.sub','62000000-0000-0000-0000-000000000002',true);
do $$
declare denied boolean := false;
begin
  begin
    perform public.request_export_job(
      'jobs-tenant','jobs-campus','jobs-year','students','CSV'
    );
  exception when insufficient_privilege then denied := true;
  end;
  if not denied then raise exception 'student export escalation was allowed'; end if;
  denied := false;
  begin
    perform public.request_backup_job('jobs-tenant','jobs-campus','jobs-year');
  exception when insufficient_privilege then denied := true;
  end;
  if not denied then raise exception 'student backup escalation was allowed'; end if;
end $$;

reset role;
rollback;
select 'Operational export and backup job tests passed' as result;
