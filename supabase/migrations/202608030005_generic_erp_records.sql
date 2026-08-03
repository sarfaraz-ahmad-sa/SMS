begin;

create table if not exists public.erp_collection_permissions (
  collection text primary key,
  view_permission text not null,
  manage_permission text not null,
  high_risk boolean not null default false
);

alter table public.erp_collection_permissions enable row level security;
alter table public.erp_collection_permissions force row level security;

insert into public.erp_collection_permissions
  (collection, view_permission, manage_permission, high_risk)
values
  ('academic_years','school_setup.view','school_setup.manage',false),
  ('admission_applications','admissions.view','admissions.manage',false),
  ('admission_inquiries','admissions.view','admissions.manage',false),
  ('admission_offers','admissions.view','admissions.manage',false),
  ('ai_insights','ai.view','ai.manage',false),
  ('alumni','students.view','students.manage',false),
  ('announcements','communication.view','communication.manage',false),
  ('appointments','helpdesk.view','helpdesk.manage',false),
  ('assets','inventory.view','inventory.manage',false),
  ('assignments','academics.view','academics.manage',false),
  ('attendance_devices','attendance.view','attendance.manage',false),
  ('attendance_sessions','attendance.view','attendance.manage',false),
  ('audit_reviews','audit.view','compliance.manage',false),
  ('automation_rules','ai.view','ai.manage',false),
  ('backup_jobs','saas_admin.view','saas_admin.manage',false),
  ('bank_accounts','accounting.view','accounting.manage',true),
  ('book_loans','library.view','library.manage',false),
  ('books','library.view','library.manage',false),
  ('budgets','accounting.view','accounting.manage',true),
  ('campuses','school_setup.view','school_setup.manage',false),
  ('certificate_requests','documents.view','documents.manage',false),
  ('chart_of_accounts','accounting.view','accounting.manage',true),
  ('chatbot_knowledge','ai.view','ai.manage',false),
  ('circulars','communication.view','communication.manage',false),
  ('classes','school_setup.view','school_setup.manage',false),
  ('clinic_visits','welfare.view','welfare.manage',false),
  ('competitions','events.view','events.manage',false),
  ('complaints','helpdesk.view','helpdesk.manage',false),
  ('consents','compliance.view','compliance.manage',false),
  ('counseling_cases','welfare.view','welfare.manage',false),
  ('daily_diary','academics.view','academics.manage',false),
  ('data_import_jobs','saas_admin.view','settings.manage',false),
  ('departments','school_setup.view','school_setup.manage',false),
  ('discipline_records','students.view','students.manage',false),
  ('document_templates','documents.view','documents.manage',false),
  ('drivers','transport.view','transport.manage',false),
  ('employee_contracts','hr.view','hr.manage',false),
  ('employees','employees.view','employees.manage',false),
  ('event_registrations','events.view','events.manage',false),
  ('events','events.view','events.manage',false),
  ('exam_results','exams.view','exams.manage',true),
  ('exam_schedules','exams.view','exams.manage',false),
  ('exams','exams.view','exams.manage',true),
  ('expenses','accounting.view','accounting.manage',true),
  ('export_jobs','reports.view','reports.manage',false),
  ('feature_flags','saas_admin.view','saas_admin.manage',false),
  ('fee_invoices','fees.view','fees.manage',true),
  ('fee_refunds','fees.view','fees.refund',true),
  ('fee_structures','fees.view','fees.manage',true),
  ('generated_reports','ai.view','ai.manage',false),
  ('grading_schemes','school_setup.view','school_setup.manage',false),
  ('guardians','parents.view','parents.manage',false),
  ('holidays','school_setup.view','school_setup.manage',false),
  ('hostel_allocations','hostel.view','hostel.manage',false),
  ('hostel_rooms','hostel.view','hostel.manage',false),
  ('hostel_visitors','hostel.view','hostel.manage',false),
  ('integration_connections','integrations.view','integrations.manage',false),
  ('inventory_items','inventory.view','inventory.manage',false),
  ('issued_certificates','documents.view','documents.manage',false),
  ('journal_entries','accounting.view','accounting.manage',true),
  ('learning_accommodations','welfare.view','welfare.manage',false),
  ('leave_requests','leave.view','leave.manage',false),
  ('lesson_plans','academics.view','academics.manage',false),
  ('library_reservations','library.view','library.manage',false),
  ('mark_entries','exams.view','exams.marks.enter',true),
  ('message_campaigns','communication.view','communication.manage',false),
  ('parent_meetings','parents.view','communication.manage',false),
  ('payments','fees.view','fees.collect',true),
  ('payroll_runs','hr.view','payroll.manage',true),
  ('payslips','hr.view','payroll.manage',true),
  ('purchase_orders','inventory.view','inventory.manage',false),
  ('report_definitions','reports.view','reports.manage',false),
  ('retention_policies','compliance.view','compliance.manage',false),
  ('role_templates','saas_admin.view','users.manage',false),
  ('safeguarding_cases','compliance.view','compliance.manage',false),
  ('scheduled_reports','reports.view','reports.manage',false),
  ('scholarships','fees.view','fees.manage',true),
  ('sections','school_setup.view','school_setup.manage',false),
  ('staff_attendance','attendance.view','attendance.manage',false),
  ('stock_movements','inventory.view','inventory.manage',false),
  ('student_achievements','students.view','students.manage',false),
  ('student_attendance','attendance.view','attendance.mark',false),
  ('student_enrollments','students.view','students.manage',false),
  ('student_guardians','parents.view','parents.manage',false),
  ('student_leave_requests','leave.view','leave.manage',false),
  ('student_medical_profiles','welfare.view','welfare.manage',false),
  ('student_promotions','students.view','students.promote',false),
  ('student_transfers','students.view','students.manage',false),
  ('students','students.view','students.manage',true),
  ('study_materials','academics.view','academics.manage',false),
  ('subjects','school_setup.view','school_setup.manage',false),
  ('subscription_billing','saas_admin.view','subscription.manage',true),
  ('support_tickets','helpdesk.view','helpdesk.manage',false),
  ('syllabus_units','academics.view','academics.manage',false),
  ('teacher_assignments','teachers.view','teachers.manage',false),
  ('teacher_evaluations','teachers.view','teachers.manage',false),
  ('teacher_substitutions','timetable.view','timetable.manage',false),
  ('teachers','teachers.view','teachers.manage',false),
  ('timetable_conflicts','timetable.view','timetable.manage',false),
  ('timetable_entries','timetable.view','timetable.manage',false),
  ('transcripts','exams.view','exams.manage',true),
  ('transport_assignments','transport.view','transport.manage',false),
  ('transport_routes','transport.view','transport.manage',false),
  ('user_access','saas_admin.view','users.manage',false),
  ('vehicles','transport.view','transport.manage',false),
  ('visitor_log','helpdesk.view','helpdesk.manage',false)
on conflict (collection) do update set
  view_permission = excluded.view_permission,
  manage_permission = excluded.manage_permission,
  high_risk = excluded.high_risk;

create table if not exists public.erp_records (
  tenant_id text not null references public.tenants(id) on delete cascade,
  collection text not null references public.erp_collection_permissions(collection),
  id text not null default (gen_random_uuid()::text),
  campus_id text not null,
  academic_year_id text not null,
  status text,
  data jsonb not null default '{}'::jsonb,
  idempotency_key text,
  is_archived boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, collection, id),
  foreign key (tenant_id, campus_id) references public.campuses(tenant_id, id),
  foreign key (tenant_id, academic_year_id)
    references public.academic_years(tenant_id, id),
  unique (tenant_id, collection, idempotency_key),
  check (jsonb_typeof(data) = 'object'),
  check (octet_length(data::text) <= 65536)
);

create index if not exists erp_records_scope_page_idx
  on public.erp_records
  (tenant_id, collection, campus_id, academic_year_id, is_archived, id);
create index if not exists erp_records_scope_status_idx
  on public.erp_records
  (tenant_id, collection, campus_id, academic_year_id, status)
  where not is_archived;

alter table public.erp_records enable row level security;
alter table public.erp_records force row level security;

drop policy if exists erp_records_read_scoped on public.erp_records;
create policy erp_records_read_scoped on public.erp_records
for select to authenticated
using (
  private.can_access_campus(tenant_id, campus_id)
  and exists (
    select 1 from public.erp_collection_permissions permission
    where permission.collection = erp_records.collection
      and private.has_permission(tenant_id, permission.view_permission)
  )
);

grant select on public.erp_records to authenticated;
revoke insert, update, delete on public.erp_records from authenticated;
revoke all on public.erp_collection_permissions from anon, authenticated;

drop trigger if exists erp_records_set_updated_at on public.erp_records;
create trigger erp_records_set_updated_at
before update on public.erp_records
for each row execute function private.set_updated_at();

drop trigger if exists erp_records_audit on public.erp_records;
create trigger erp_records_audit
after insert or update or delete on public.erp_records
for each row execute function private.audit_row_change();

create or replace function private.require_generic_erp_access(
  p_tenant_id text,
  p_collection text,
  p_campus_id text,
  p_for_write boolean
)
returns public.erp_collection_permissions
security definer
language plpgsql
set search_path = ''
as $$
declare
  v_permission public.erp_collection_permissions;
begin
  select * into v_permission
  from public.erp_collection_permissions p
  where p.collection = nullif(trim(p_collection), '');
  if not found then
    raise exception 'unsupported ERP collection' using errcode = '22023';
  end if;
  if p_for_write and v_permission.high_risk then
    raise exception 'high-risk collection requires a dedicated transaction RPC'
      using errcode = '0A000';
  end if;
  if not private.can_access_campus(p_tenant_id, p_campus_id) then
    raise exception 'campus access denied' using errcode = '42501';
  end if;
  if p_for_write and not private.has_permission(
    p_tenant_id, v_permission.manage_permission
  ) then
    raise exception 'permission denied' using errcode = '42501';
  end if;
  return v_permission;
end;
$$;

revoke all on function private.require_generic_erp_access(text,text,text,boolean)
  from public;

create or replace function public.create_erp_record(
  p_tenant_id text,
  p_collection text,
  p_campus_id text,
  p_academic_year_id text,
  p_values jsonb,
  p_idempotency_key text
)
returns public.erp_records
security definer
language plpgsql
set search_path = ''
as $$
declare
  v_record public.erp_records;
  v_values jsonb;
begin
  if (select auth.uid()) is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  perform private.require_generic_erp_access(
    p_tenant_id, p_collection, p_campus_id, true
  );
  if p_values is null or jsonb_typeof(p_values) <> 'object' then
    raise exception 'record values must be an object' using errcode = '22023';
  end if;
  if nullif(trim(p_idempotency_key), '') is null then
    raise exception 'idempotency key is required' using errcode = '22023';
  end if;
  if not exists (
    select 1 from public.academic_years y
    where y.tenant_id = p_tenant_id and y.id = p_academic_year_id
      and not y.is_archived
  ) then
    raise exception 'active academic year not found' using errcode = '23503';
  end if;
  v_values := p_values - array[
    'tenantId','campusId','academicYearId','createdAt','updatedAt',
    'createdBy','updatedBy','isArchived','id'
  ];
  if octet_length(v_values::text) > 65536 then
    raise exception 'record payload is too large' using errcode = '22023';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(
    p_tenant_id || ':' || p_collection || ':' || trim(p_idempotency_key), 0
  ));
  select * into v_record from public.erp_records r
  where r.tenant_id = p_tenant_id and r.collection = p_collection
    and r.idempotency_key = trim(p_idempotency_key);
  if found then return v_record; end if;

  insert into public.erp_records (
    tenant_id, collection, campus_id, academic_year_id, status, data,
    idempotency_key, created_by, updated_by
  ) values (
    p_tenant_id, p_collection, p_campus_id, p_academic_year_id,
    nullif(trim(v_values->>'status'), ''), v_values,
    trim(p_idempotency_key), (select auth.uid()), (select auth.uid())
  ) returning * into v_record;
  return v_record;
end;
$$;

create or replace function public.update_erp_record(
  p_tenant_id text,
  p_collection text,
  p_record_id text,
  p_expected_updated_at timestamptz,
  p_values jsonb
)
returns public.erp_records
security definer
language plpgsql
set search_path = ''
as $$
declare
  v_existing public.erp_records;
  v_record public.erp_records;
  v_values jsonb;
begin
  if (select auth.uid()) is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  select * into v_existing from public.erp_records r
  where r.tenant_id = p_tenant_id and r.collection = p_collection
    and r.id = p_record_id and not r.is_archived
  for update;
  if not found then
    raise exception 'active ERP record not found' using errcode = 'P0002';
  end if;
  perform private.require_generic_erp_access(
    p_tenant_id, p_collection, v_existing.campus_id, true
  );
  if p_expected_updated_at is null
     or v_existing.updated_at is distinct from p_expected_updated_at then
    raise exception 'record was changed by another user; reload and retry'
      using errcode = '40001';
  end if;
  if p_values is null or jsonb_typeof(p_values) <> 'object' then
    raise exception 'record values must be an object' using errcode = '22023';
  end if;
  v_values := p_values - array[
    'tenantId','campusId','academicYearId','createdAt','updatedAt',
    'createdBy','updatedBy','isArchived','id'
  ];
  if octet_length(v_values::text) > 65536 then
    raise exception 'record payload is too large' using errcode = '22023';
  end if;
  update public.erp_records set
    data = v_values,
    status = nullif(trim(v_values->>'status'), ''),
    updated_by = (select auth.uid())
  where tenant_id = p_tenant_id and collection = p_collection
    and id = p_record_id
  returning * into v_record;
  return v_record;
end;
$$;

create or replace function public.archive_erp_record(
  p_tenant_id text,
  p_collection text,
  p_record_id text,
  p_expected_updated_at timestamptz
)
returns public.erp_records
security definer
language plpgsql
set search_path = ''
as $$
declare
  v_existing public.erp_records;
  v_record public.erp_records;
begin
  if (select auth.uid()) is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  select * into v_existing from public.erp_records r
  where r.tenant_id = p_tenant_id and r.collection = p_collection
    and r.id = p_record_id and not r.is_archived
  for update;
  if not found then
    raise exception 'active ERP record not found' using errcode = 'P0002';
  end if;
  perform private.require_generic_erp_access(
    p_tenant_id, p_collection, v_existing.campus_id, true
  );
  if p_expected_updated_at is null
     or v_existing.updated_at is distinct from p_expected_updated_at then
    raise exception 'record was changed by another user; reload and retry'
      using errcode = '40001';
  end if;
  update public.erp_records set
    is_archived = true,
    updated_by = (select auth.uid())
  where tenant_id = p_tenant_id and collection = p_collection
    and id = p_record_id
  returning * into v_record;
  return v_record;
end;
$$;

revoke all on function public.create_erp_record(text,text,text,text,jsonb,text)
  from public;
revoke all on function public.update_erp_record(text,text,text,timestamptz,jsonb)
  from public;
revoke all on function public.archive_erp_record(text,text,text,timestamptz)
  from public;
grant execute on function public.create_erp_record(text,text,text,text,jsonb,text)
  to authenticated;
grant execute on function public.update_erp_record(text,text,text,timestamptz,jsonb)
  to authenticated;
grant execute on function public.archive_erp_record(text,text,text,timestamptz)
  to authenticated;

commit;
