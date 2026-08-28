begin;

update public.erp_collection_permissions
set high_risk = true
where collection in ('export_jobs', 'backup_jobs');

create or replace function public.request_export_job(
  p_tenant_id text,
  p_campus_id text,
  p_academic_year_id text,
  p_source_collection text,
  p_format text
)
returns public.erp_records
security definer
language plpgsql
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_permission public.erp_collection_permissions;
  v_record public.erp_records;
  v_format text := upper(trim(p_format));
  v_job_no text := 'EXP-' || to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS');
  v_values jsonb;
begin
  if v_uid is null or not private.has_permission(p_tenant_id, 'reports.view') then
    raise exception 'reports permission denied' using errcode = '42501';
  end if;
  if not private.can_access_campus(p_tenant_id, p_campus_id) then
    raise exception 'campus access denied' using errcode = '42501';
  end if;
  select * into v_permission from public.erp_collection_permissions p
  where p.collection = nullif(trim(p_source_collection), '');
  if not found or not private.has_permission(p_tenant_id, v_permission.view_permission) then
    raise exception 'source collection access denied' using errcode = '42501';
  end if;
  if v_format not in ('CSV','XLSX','PDF') then
    raise exception 'unsupported export format' using errcode = '22023';
  end if;
  v_values := jsonb_build_object(
    'jobNo', v_job_no,
    'reportName', replace(trim(p_source_collection), '_', ' '),
    'sourceCollection', trim(p_source_collection),
    'requestedBy', v_uid::text,
    'requestedAt', now(),
    'format', v_format,
    'rowCount', 0,
    'status', 'Queued'
  );
  insert into public.erp_records (
    tenant_id, collection, campus_id, academic_year_id, status, data,
    idempotency_key, created_by, updated_by
  ) values (
    p_tenant_id, 'export_jobs', p_campus_id, p_academic_year_id,
    'Queued', v_values, v_uid::text || ':' || v_job_no, v_uid, v_uid
  ) returning * into v_record;
  return v_record;
end;
$$;

create or replace function public.request_backup_job(
  p_tenant_id text,
  p_campus_id text,
  p_academic_year_id text
)
returns public.erp_records
security definer
language plpgsql
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_record public.erp_records;
  v_job_no text := 'BKP-' || to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS');
  v_values jsonb;
begin
  if v_uid is null or not private.has_permission(p_tenant_id, 'saas_admin.manage') then
    raise exception 'backup permission denied' using errcode = '42501';
  end if;
  if not private.can_access_campus(p_tenant_id, p_campus_id) then
    raise exception 'campus access denied' using errcode = '42501';
  end if;
  v_values := jsonb_build_object(
    'jobNo', v_job_no,
    'backupType', 'Manual',
    'startedAt', now(),
    'restoreTested', false,
    'status', 'Queued',
    'requestedBy', v_uid::text
  );
  insert into public.erp_records (
    tenant_id, collection, campus_id, academic_year_id, status, data,
    idempotency_key, created_by, updated_by
  ) values (
    p_tenant_id, 'backup_jobs', p_campus_id, p_academic_year_id,
    'Queued', v_values, v_uid::text || ':' || v_job_no, v_uid, v_uid
  ) returning * into v_record;
  return v_record;
end;
$$;

revoke all on function public.request_export_job(text,text,text,text,text)
  from public, anon;
grant execute on function public.request_export_job(text,text,text,text,text)
  to authenticated;
revoke all on function public.request_backup_job(text,text,text)
  from public, anon;
grant execute on function public.request_backup_job(text,text,text)
  to authenticated;

commit;
