-- Run as postgres after 202608030004_secure_student_mutations.sql. All test
-- identities and school records are rolled back at the end.

begin;

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000000',
  '30000000-0000-0000-0000-000000000003',
  'authenticated', 'authenticated', 'student-rpc@example.invalid', '', now(),
  '{}'::jsonb, '{}'::jsonb, now(), now()
);

insert into public.tenants (id, name)
values ('student-rpc-tenant', 'Student RPC Test School');

insert into public.tenant_members (
  tenant_id, user_id, email, roles, permissions, campus_ids
) values (
  'student-rpc-tenant', '30000000-0000-0000-0000-000000000003',
  'student-rpc@example.invalid', array['schoolOwner'], array['*'],
  array['student-rpc-campus']
);

insert into public.campuses (tenant_id, id, code, name) values
  ('student-rpc-tenant', 'student-rpc-campus', 'RPC', 'Allowed Campus'),
  ('student-rpc-tenant', 'student-rpc-blocked', 'BLOCK', 'Blocked Campus');

insert into public.academic_years (
  tenant_id, id, name, starts_on, ends_on, status
) values (
  'student-rpc-tenant', 'student-rpc-year', '2026-2027',
  '2026-04-01', '2027-03-31', 'active'
);

insert into public.classes (
  tenant_id, id, campus_id, academic_year_id, name
) values (
  'student-rpc-tenant', 'student-rpc-class', 'student-rpc-campus',
  'student-rpc-year', 'Class One'
);

insert into public.sections (
  tenant_id, id, campus_id, academic_year_id, class_id, name
) values (
  'student-rpc-tenant', 'student-rpc-section', 'student-rpc-campus',
  'student-rpc-year', 'student-rpc-class', 'A'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '30000000-0000-0000-0000-000000000003',
  true
);

do $$
declare
  v_created public.students;
  v_updated public.students;
  v_archived public.students;
  v_denied boolean;
begin
  v_denied := false;
  begin
    insert into public.students (
      tenant_id, campus_id, academic_year_id, admission_no, full_name
    ) values (
      'student-rpc-tenant', 'student-rpc-campus', 'student-rpc-year',
      'DIRECT-001', 'Direct Write'
    );
  exception when insufficient_privilege then
    v_denied := true;
  end;
  if not v_denied then
    raise exception 'direct authenticated student INSERT was not denied';
  end if;

  v_created := public.create_student(
    'student-rpc-tenant',
    jsonb_build_object(
      'campus_id', 'student-rpc-campus',
      'academic_year_id', 'student-rpc-year',
      'class_id', 'student-rpc-class',
      'section_id', 'student-rpc-section',
      'admission_no', 'RPC-001',
      'full_name', 'RPC Student',
      'status', 'active'
    )
  );

  if v_created.created_by is distinct from (select auth.uid()) then
    raise exception 'student creator was not audited';
  end if;

  v_denied := false;
  begin
    perform public.create_student(
      'student-rpc-tenant',
      jsonb_build_object(
        'campus_id', 'student-rpc-campus',
        'academic_year_id', 'student-rpc-year',
        'admission_no', 'rpc-001',
        'full_name', 'Duplicate Student'
      )
    );
  exception when unique_violation then
    v_denied := true;
  end;
  if not v_denied then
    raise exception 'case-insensitive duplicate admission number was accepted';
  end if;

  v_denied := false;
  begin
    perform public.create_student(
      'student-rpc-tenant',
      jsonb_build_object(
        'campus_id', 'student-rpc-blocked',
        'academic_year_id', 'student-rpc-year',
        'admission_no', 'RPC-BLOCKED',
        'full_name', 'Blocked Campus Student'
      )
    );
  exception when insufficient_privilege then
    v_denied := true;
  end;
  if not v_denied then
    raise exception 'cross-campus RPC create was not denied';
  end if;

  v_updated := public.update_student(
    'student-rpc-tenant', v_created.id, v_created.updated_at,
    jsonb_build_object(
      'campus_id', 'student-rpc-campus',
      'academic_year_id', 'student-rpc-year',
      'class_id', 'student-rpc-class',
      'section_id', 'student-rpc-section',
      'admission_no', 'RPC-001',
      'full_name', 'RPC Student Updated',
      'status', 'active'
    )
  );

  if v_updated.full_name <> 'RPC Student Updated'
     or v_updated.updated_at <= v_created.updated_at then
    raise exception 'student update/version test failed';
  end if;

  v_denied := false;
  begin
    perform public.update_student(
      'student-rpc-tenant', v_created.id, v_created.updated_at,
      jsonb_build_object(
        'campus_id', 'student-rpc-campus',
        'academic_year_id', 'student-rpc-year',
        'admission_no', 'RPC-001',
        'full_name', 'Stale Update',
        'status', 'active'
      )
    );
  exception when serialization_failure then
    v_denied := true;
  end;
  if not v_denied then
    raise exception 'stale student update was not denied';
  end if;

  v_archived := public.archive_student(
    'student-rpc-tenant', v_updated.id, v_updated.updated_at
  );
  if not v_archived.is_archived then
    raise exception 'student archive test failed';
  end if;
end;
$$;

reset role;

do $$
declare
  v_student_id text;
begin
  select id into v_student_id from public.students
  where tenant_id = 'student-rpc-tenant' and admission_no = 'RPC-001';

  if (
    select count(*) from public.audit_logs
    where tenant_id = 'student-rpc-tenant'
      and table_name = 'students'
      and record_id = v_student_id
      and actor_user_id = '30000000-0000-0000-0000-000000000003'
  ) <> 3 then
    raise exception 'student create/update/archive audit log test failed';
  end if;

  if coalesce((
    select (counts->>'students')::integer
    from public.dashboard_summaries
    where tenant_id = 'student-rpc-tenant'
      and campus_id = 'student-rpc-campus'
      and academic_year_id = 'student-rpc-year'
  ), -1) <> 0 then
    raise exception 'dashboard summary was not refreshed after archive';
  end if;
end;
$$;

rollback;

select 'Secure student mutation integration tests passed' as result;
