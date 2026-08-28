begin;

create or replace function private.has_staff_permission(
  p_tenant_id text,
  p_permission text
)
returns boolean
security definer
language sql
stable
set search_path = ''
as $$
  select exists (
    select 1 from public.tenant_members m
    where m.tenant_id = p_tenant_id
      and m.user_id = (select auth.uid())
      and m.is_active and m.status = 'active'
      and not (m.roles && array['student','parent']::text[])
      and not (p_permission = any(m.denied_permissions))
      and (
        '*' = any(m.permissions)
        or p_permission = any(m.permissions)
        or m.roles && array['superAdmin','schoolOwner']::text[]
      )
  );
$$;

revoke all on function private.has_staff_permission(text,text)
  from public, anon;
grant execute on function private.has_staff_permission(text,text)
  to authenticated;

create or replace function private.can_access_student(
  target_tenant_id text,
  target_student_id text
)
returns boolean
security definer
language sql
stable
set search_path = ''
as $$
  select
    (
      private.has_staff_permission(target_tenant_id, 'students.view')
      and private.can_access_student_campus(target_tenant_id, target_student_id)
    )
    or exists (
      select 1 from public.students s
      where s.tenant_id = target_tenant_id and s.id = target_student_id
        and s.auth_user_id = (select auth.uid())
    )
    or exists (
      select 1 from public.student_guardians link
      join public.guardians guardian
        on guardian.tenant_id = link.tenant_id
       and guardian.id = link.guardian_id
      where link.tenant_id = target_tenant_id
        and link.student_id = target_student_id
        and guardian.auth_user_id = (select auth.uid())
    );
$$;

grant execute on function private.can_access_student(text,text)
  to authenticated;

drop policy if exists guardians_read_scoped on public.guardians;
create policy guardians_read_scoped on public.guardians
for select to authenticated
using (
  private.has_staff_permission(tenant_id, 'parents.view')
  or auth_user_id = (select auth.uid())
);

drop policy if exists invoices_read_scoped on public.fee_invoices;
create policy invoices_read_scoped on public.fee_invoices
for select to authenticated
using (
  (
    private.has_staff_permission(tenant_id, 'fees.view')
    and private.can_access_student_campus(tenant_id, student_id)
  )
  or private.can_access_student(tenant_id, student_id)
);

drop policy if exists payments_read_scoped on public.payments;
create policy payments_read_scoped on public.payments
for select to authenticated
using (
  (
    private.has_staff_permission(tenant_id, 'fees.view')
    and private.can_access_student_campus(tenant_id, student_id)
  )
  or private.can_access_student(tenant_id, student_id)
);

drop policy if exists attendance_read_scoped on public.student_attendance;
create policy attendance_read_scoped on public.student_attendance
for select to authenticated
using (
  (
    private.has_staff_permission(tenant_id, 'attendance.view')
    and private.can_access_student_campus(tenant_id, student_id)
  )
  or private.can_access_student(tenant_id, student_id)
);

drop policy if exists results_read_scoped on public.exam_results;
create policy results_read_scoped on public.exam_results
for select to authenticated
using (
  (
    private.has_staff_permission(tenant_id, 'exams.view')
    and private.can_access_student_campus(tenant_id, student_id)
  )
  or (status = 'published' and private.can_access_student(tenant_id, student_id))
);

create or replace function private.can_read_erp_record(
  p_tenant_id text,
  p_collection text,
  p_data jsonb,
  p_created_by uuid
)
returns boolean
security definer
language plpgsql
stable
set search_path = ''
as $$
declare
  v_member public.tenant_members;
  v_uid uuid := (select auth.uid());
  v_student_id text := nullif(trim(p_data->>'studentRecordId'), '');
begin
  select * into v_member from public.tenant_members m
  where m.tenant_id = p_tenant_id and m.user_id = v_uid
    and m.is_active and m.status = 'active';
  if not found then return false; end if;

  if not (v_member.roles && array['student','parent']::text[]) then
    return true;
  end if;

  if p_collection = any(array[
    'library_reservations','event_registrations','certificate_requests',
    'student_leave_requests','leave_requests','parent_meetings',
    'support_tickets','complaints'
  ]::text[]) then
    return p_created_by = v_uid or p_data->>'requesterUid' = v_uid::text;
  end if;

  if p_collection = any(array[
    'students','student_attendance','daily_diary','exam_results','transcripts',
    'fee_invoices','payments','book_loans','transport_assignments',
    'hostel_allocations','issued_certificates','student_medical_profiles',
    'learning_accommodations'
  ]::text[]) then
    if p_data->>'authUid' = v_uid::text
       or p_data->>'studentAuthUid' = v_uid::text
       or coalesce(p_data->'guardianUids', '[]'::jsonb) ? v_uid::text then
      return true;
    end if;
    if v_member.linked_record_type = 'student'
       and v_member.linked_record_id = v_student_id then
      return true;
    end if;
    if v_member.linked_record_type in ('guardian','parent') and exists (
      select 1 from public.student_guardians link
      where link.tenant_id = p_tenant_id
        and link.guardian_id = v_member.linked_record_id
        and link.student_id = v_student_id
    ) then
      return true;
    end if;
    return false;
  end if;

  return true;
end;
$$;

revoke all on function private.can_read_erp_record(text,text,jsonb,uuid)
  from public, anon;
grant execute on function private.can_read_erp_record(text,text,jsonb,uuid)
  to authenticated;

drop policy if exists erp_records_read_scoped on public.erp_records;
create policy erp_records_read_scoped on public.erp_records
for select to authenticated
using (
  private.can_access_campus(tenant_id, campus_id)
  and private.can_read_erp_record(tenant_id, collection, data, created_by)
  and exists (
    select 1 from public.erp_collection_permissions permission
    where permission.collection = erp_records.collection
      and private.has_permission(tenant_id, permission.view_permission)
  )
);

create or replace function public.create_self_service_erp_record(
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
  v_uid uuid := (select auth.uid());
  v_member public.tenant_members;
  v_record public.erp_records;
  v_values jsonb;
  v_defaults jsonb;
  v_student_id text;
  v_required_permission text;
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if not (p_collection = any(array[
    'library_reservations','event_registrations','certificate_requests',
    'student_leave_requests','leave_requests','parent_meetings',
    'support_tickets','complaints'
  ]::text[])) then
    raise exception 'collection does not support self-service creation'
      using errcode = '42501';
  end if;
  if p_values is null or jsonb_typeof(p_values) <> 'object' then
    raise exception 'record values must be an object' using errcode = '22023';
  end if;
  if nullif(trim(p_idempotency_key), '') is null then
    raise exception 'idempotency key is required' using errcode = '22023';
  end if;
  if not private.can_access_campus(p_tenant_id, p_campus_id) then
    raise exception 'campus access denied' using errcode = '42501';
  end if;
  select * into v_member from public.tenant_members m
  where m.tenant_id = p_tenant_id and m.user_id = v_uid
    and m.is_active and m.status = 'active';
  if not found then
    raise exception 'active membership required' using errcode = '42501';
  end if;
  v_required_permission := case p_collection
    when 'library_reservations' then 'library.view'
    when 'event_registrations' then 'events.view'
    when 'certificate_requests' then 'documents.view'
    when 'student_leave_requests' then 'leave.apply'
    when 'leave_requests' then 'leave.apply'
    when 'parent_meetings' then 'parents.view'
    when 'support_tickets' then 'helpdesk.view'
    when 'complaints' then 'helpdesk.view'
  end;
  if v_required_permission is null
     or not private.has_permission(p_tenant_id, v_required_permission) then
    raise exception 'self-service permission denied' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.academic_years y
    where y.tenant_id = p_tenant_id and y.id = p_academic_year_id
      and not y.is_archived
  ) then
    raise exception 'active academic year not found' using errcode = '23503';
  end if;

  v_student_id := nullif(trim(p_values->>'studentRecordId'), '');
  if v_member.roles && array['parent']::text[] and v_student_id is not null
     and not exists (
       select 1 from public.student_guardians link
       where link.tenant_id = p_tenant_id
         and link.student_id = v_student_id
         and link.guardian_id = v_member.linked_record_id
     ) then
    raise exception 'student relationship denied' using errcode = '42501';
  end if;

  v_defaults := case p_collection
    when 'library_reservations' then '{"status":"Waiting"}'::jsonb
    when 'event_registrations' then
      '{"status":"Registered","feePaid":false,"attendanceMarked":false}'::jsonb
    when 'certificate_requests' then '{"status":"Requested"}'::jsonb
    when 'student_leave_requests' then '{"status":"Pending"}'::jsonb
    when 'leave_requests' then '{"status":"Pending"}'::jsonb
    when 'parent_meetings' then '{"status":"Requested"}'::jsonb
    when 'support_tickets' then
      '{"status":"Open","assignedTo":"","resolution":""}'::jsonb
    when 'complaints' then '{"status":"Received"}'::jsonb
    else '{}'::jsonb
  end;
  v_values := (p_values - array[
    'tenantId','campusId','academicYearId','createdAt','updatedAt',
    'createdBy','updatedBy','isArchived','id','requesterUid','authUid',
    'guardianUids','status','assignedTo','resolution'
  ]) || v_defaults || jsonb_build_object('requesterUid', v_uid::text);
  if v_member.roles && array['student']::text[] then
    v_values := v_values || jsonb_build_object('authUid', v_uid::text);
    if v_member.linked_record_type = 'student' then
      v_values := v_values ||
        jsonb_build_object('studentRecordId', v_member.linked_record_id);
    end if;
  elsif v_member.roles && array['parent']::text[] then
    v_values := v_values || jsonb_build_object('guardianUids', jsonb_build_array(v_uid::text));
  end if;
  if octet_length(v_values::text) > 65536 then
    raise exception 'record payload is too large' using errcode = '22023';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(
    p_tenant_id || ':self:' || p_collection || ':' || trim(p_idempotency_key), 0
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
    v_values->>'status', v_values, trim(p_idempotency_key), v_uid, v_uid
  ) returning * into v_record;
  return v_record;
end;
$$;

revoke all on function public.create_self_service_erp_record(
  text,text,text,text,jsonb,text
) from public, anon;
grant execute on function public.create_self_service_erp_record(
  text,text,text,text,jsonb,text
) to authenticated;

commit;
