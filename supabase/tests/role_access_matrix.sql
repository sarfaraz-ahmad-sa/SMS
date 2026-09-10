-- Student, parent, teacher and administrator integration matrix for generic ERP
-- records. Run as postgres after all migrations; the transaction rolls back.

begin;

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('00000000-0000-0000-0000-000000000000','51000000-0000-0000-0000-000000000001','authenticated','authenticated','role-student@example.invalid','',now(),'{}','{}',now(),now()),
  ('00000000-0000-0000-0000-000000000000','52000000-0000-0000-0000-000000000002','authenticated','authenticated','role-parent@example.invalid','',now(),'{}','{}',now(),now()),
  ('00000000-0000-0000-0000-000000000000','53000000-0000-0000-0000-000000000003','authenticated','authenticated','role-teacher@example.invalid','',now(),'{}','{}',now(),now()),
  ('00000000-0000-0000-0000-000000000000','54000000-0000-0000-0000-000000000004','authenticated','authenticated','role-admin@example.invalid','',now(),'{}','{}',now(),now());

insert into public.tenants (id, name, code)
values ('role-matrix-tenant', 'Role Matrix School', 'ROLE-MATRIX');
insert into public.campuses (tenant_id, id, code, name)
values ('role-matrix-tenant', 'role-campus', 'MAIN', 'Main Campus');
insert into public.academic_years (
  tenant_id, id, name, starts_on, ends_on, status
) values (
  'role-matrix-tenant', 'role-year', '2026-2027',
  '2026-04-01', '2027-03-31', 'active'
);

insert into public.tenant_members (
  tenant_id, user_id, email, roles, permissions, campus_ids,
  linked_record_type, linked_record_id
) values
  ('role-matrix-tenant','51000000-0000-0000-0000-000000000001','role-student@example.invalid',array['student'],array['academics.view','helpdesk.view','leave.apply'],array['role-campus'],'student','role-student-1'),
  ('role-matrix-tenant','52000000-0000-0000-0000-000000000002','role-parent@example.invalid',array['parent'],array['academics.view','helpdesk.view','parents.view','leave.apply'],array['role-campus'],'guardian','role-guardian-1'),
  ('role-matrix-tenant','53000000-0000-0000-0000-000000000003','role-teacher@example.invalid',array['teacher'],array['academics.view','helpdesk.view','students.view','leave.apply'],array['role-campus'],null,null),
  ('role-matrix-tenant','54000000-0000-0000-0000-000000000004','role-admin@example.invalid',array['adminStaff'],array['students.view','academics.view','helpdesk.view'],array['role-campus'],null,null);

insert into public.students (
  tenant_id, id, campus_id, academic_year_id, admission_no, full_name,
  auth_user_id
) values
  ('role-matrix-tenant','role-student-1','role-campus','role-year','ROLE-001','Linked Student','51000000-0000-0000-0000-000000000001'),
  ('role-matrix-tenant','role-student-2','role-campus','role-year','ROLE-002','Other Student',null);
insert into public.guardians (tenant_id, id, full_name, auth_user_id)
values ('role-matrix-tenant','role-guardian-1','Linked Parent','52000000-0000-0000-0000-000000000002');
insert into public.student_guardians (
  tenant_id, student_id, guardian_id, relationship
) values ('role-matrix-tenant','role-student-1','role-guardian-1','Parent');

insert into public.erp_records (
  tenant_id, collection, id, campus_id, academic_year_id, status, data,
  created_by
) values
  ('role-matrix-tenant','daily_diary','diary-linked','role-campus','role-year','Published','{"title":"Linked diary","studentRecordId":"role-student-1"}','54000000-0000-0000-0000-000000000004'),
  ('role-matrix-tenant','daily_diary','diary-other','role-campus','role-year','Published','{"title":"Other diary","studentRecordId":"role-student-2"}','54000000-0000-0000-0000-000000000004'),
  ('role-matrix-tenant','assignments','assignment-one','role-campus','role-year','Published','{"title":"Assignment one"}','54000000-0000-0000-0000-000000000004'),
  ('role-matrix-tenant','assignments','assignment-two','role-campus','role-year','Published','{"title":"Assignment two"}','54000000-0000-0000-0000-000000000004'),
  ('role-matrix-tenant','support_tickets','ticket-student','role-campus','role-year','Open','{"requesterUid":"51000000-0000-0000-0000-000000000001"}','51000000-0000-0000-0000-000000000001'),
  ('role-matrix-tenant','support_tickets','ticket-parent','role-campus','role-year','Open','{"requesterUid":"52000000-0000-0000-0000-000000000002"}','52000000-0000-0000-0000-000000000002');

set local role authenticated;

select set_config('request.jwt.claim.sub','51000000-0000-0000-0000-000000000001',true);
do $$
declare created public.erp_records;
begin
  if (select count(*) from public.students) <> 1 then
    raise exception 'student native-record isolation failed';
  end if;
  if (select count(*) from public.erp_records where collection = 'daily_diary') <> 1 then
    raise exception 'student personal-record isolation failed';
  end if;
  if (select count(*) from public.erp_records where collection = 'assignments') <> 2 then
    raise exception 'student shared-content access failed';
  end if;
  if (select count(*) from public.erp_records where collection = 'support_tickets') <> 1 then
    raise exception 'student self-service isolation failed';
  end if;
  created := public.create_self_service_erp_record(
    'role-matrix-tenant','support_tickets','role-campus','role-year',
    '{"subject":"Need help","status":"Closed","assignedTo":"attacker"}',
    'role-student-ticket'
  );
  if created.data->>'status' <> 'Open'
     or created.data->>'requesterUid' <> '51000000-0000-0000-0000-000000000001'
     or created.data->>'assignedTo' <> '' then
    raise exception 'student self-service server defaults failed';
  end if;
end $$;

select set_config('request.jwt.claim.sub','52000000-0000-0000-0000-000000000002',true);
do $$
declare denied boolean := false;
begin
  if (select count(*) from public.students) <> 1 then
    raise exception 'parent native linked-student isolation failed';
  end if;
  if (select count(*) from public.erp_records where collection = 'daily_diary') <> 1 then
    raise exception 'parent linked-student isolation failed';
  end if;
  if (select count(*) from public.erp_records where collection = 'support_tickets') <> 1 then
    raise exception 'parent self-service isolation failed';
  end if;
  begin
    perform public.create_self_service_erp_record(
      'role-matrix-tenant','student_leave_requests','role-campus','role-year',
      '{"studentRecordId":"role-student-2","reason":"Unauthorized"}',
      'role-parent-denied'
    );
  exception when insufficient_privilege then denied := true;
  end;
  if not denied then raise exception 'parent could submit for an unrelated student'; end if;
end $$;

select set_config('request.jwt.claim.sub','53000000-0000-0000-0000-000000000003',true);
do $$
begin
  if (select count(*) from public.students) <> 2
     or (select count(*) from public.erp_records where collection = 'daily_diary') <> 2
     or (select count(*) from public.erp_records where collection = 'support_tickets') <> 3 then
    raise exception 'teacher permission-scoped access failed';
  end if;
end $$;

select set_config('request.jwt.claim.sub','54000000-0000-0000-0000-000000000004',true);
do $$
begin
  if (select count(*) from public.students) <> 2
     or (select count(*) from public.erp_records) <> 7 then
    raise exception 'administrator access failed';
  end if;
end $$;

reset role;
update public.tenant_members set is_active = false, status = 'suspended'
where tenant_id = 'role-matrix-tenant'
  and user_id in ('51000000-0000-0000-0000-000000000001',
                  '52000000-0000-0000-0000-000000000002');
set local role authenticated;
select set_config('request.jwt.claim.sub','51000000-0000-0000-0000-000000000001',true);
do $$ begin
  if exists (select 1 from public.students) then
    raise exception 'suspended student retained linked student access';
  end if;
end $$;
select set_config('request.jwt.claim.sub','52000000-0000-0000-0000-000000000002',true);
do $$ begin
  if exists (select 1 from public.students) or exists (select 1 from public.guardians) then
    raise exception 'suspended parent retained linked portal access';
  end if;
end $$;
reset role;
rollback;
select 'Student/parent/teacher/admin role integration tests passed' as result;
