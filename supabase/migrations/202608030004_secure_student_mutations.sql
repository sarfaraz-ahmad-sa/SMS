begin;

-- Use a statement-time value instead of transaction-start time so optimistic
-- concurrency versions always advance, including batch operations.
create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = pg_catalog.clock_timestamp();
  if to_jsonb(new) ? 'updated_by' then
    new.updated_by = (select auth.uid());
  end if;
  return new;
end;
$$;

-- Admission numbers are identifiers, so case and surrounding whitespace must
-- not allow a second student to be created for the same school.
create unique index if not exists students_tenant_admission_no_ci_unique
  on public.students (tenant_id, lower(trim(admission_no)));

-- Student records contain personal data and affect dashboard totals. Keep
-- SELECT behind RLS, but require all mutations to pass through the validated
-- transactional functions below.
revoke insert, update, delete on public.students from authenticated;
drop policy if exists students_insert_manage on public.students;
drop policy if exists students_update_manage on public.students;

create or replace function public.create_student(
  p_tenant_id text,
  p_payload jsonb
)
returns public.students
security definer
language plpgsql
set search_path = ''
as $$
declare
  v_student public.students;
  v_campus_id text := nullif(trim(p_payload->>'campus_id'), '');
  v_academic_year_id text := nullif(trim(p_payload->>'academic_year_id'), '');
  v_class_id text := nullif(trim(p_payload->>'class_id'), '');
  v_section_id text := nullif(trim(p_payload->>'section_id'), '');
  v_admission_no text := nullif(trim(p_payload->>'admission_no'), '');
  v_full_name text := nullif(trim(p_payload->>'full_name'), '');
  v_gender text := nullif(lower(trim(p_payload->>'gender')), '');
  v_status text := coalesce(nullif(lower(trim(p_payload->>'status')), ''), 'active');
  v_date_of_birth date;
begin
  if (select auth.uid()) is null
     or not private.has_permission(p_tenant_id, 'students.manage') then
    raise exception 'permission denied' using errcode = '42501';
  end if;
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'student payload must be an object' using errcode = '22023';
  end if;
  if (p_payload - array[
    'campus_id', 'academic_year_id', 'class_id', 'section_id',
    'admission_no', 'full_name', 'date_of_birth', 'gender', 'status'
  ]) <> '{}'::jsonb then
    raise exception 'student payload contains unsupported fields'
      using errcode = '22023';
  end if;
  if v_campus_id is null or v_academic_year_id is null then
    raise exception 'campus and academic year are required'
      using errcode = '22023';
  end if;
  if not private.can_access_campus(p_tenant_id, v_campus_id) then
    raise exception 'campus access denied' using errcode = '42501';
  end if;
  if v_admission_no is null or char_length(v_admission_no) > 50 then
    raise exception 'admission number must contain 1 to 50 characters'
      using errcode = '22023';
  end if;
  if v_full_name is null or char_length(v_full_name) not between 2 and 160 then
    raise exception 'student name must contain 2 to 160 characters'
      using errcode = '22023';
  end if;
  if v_status not in ('active', 'inactive', 'graduated', 'withdrawn') then
    raise exception 'unsupported student status' using errcode = '22023';
  end if;
  if v_gender is not null and v_gender not in ('male', 'female', 'other') then
    raise exception 'unsupported gender' using errcode = '22023';
  end if;
  if nullif(trim(p_payload->>'date_of_birth'), '') is not null then
    begin
      v_date_of_birth := (p_payload->>'date_of_birth')::date;
    exception when others then
      raise exception 'invalid date of birth' using errcode = '22023';
    end;
    if v_date_of_birth > current_date then
      raise exception 'date of birth cannot be in the future'
        using errcode = '22023';
    end if;
  end if;
  if not exists (
    select 1 from public.campuses c
    where c.tenant_id = p_tenant_id and c.id = v_campus_id
      and not c.is_archived
  ) then
    raise exception 'active campus not found' using errcode = '23503';
  end if;
  if not exists (
    select 1 from public.academic_years y
    where y.tenant_id = p_tenant_id and y.id = v_academic_year_id
      and not y.is_archived
  ) then
    raise exception 'active academic year not found' using errcode = '23503';
  end if;
  if v_class_id is not null and not exists (
    select 1 from public.classes c
    where c.tenant_id = p_tenant_id and c.id = v_class_id
      and c.campus_id = v_campus_id
      and c.academic_year_id = v_academic_year_id
      and not c.is_archived
  ) then
    raise exception 'class is outside the selected campus or academic year'
      using errcode = '23503';
  end if;
  if v_section_id is not null and (
    v_class_id is null or not exists (
      select 1 from public.sections s
      where s.tenant_id = p_tenant_id and s.id = v_section_id
        and s.campus_id = v_campus_id
        and s.academic_year_id = v_academic_year_id
        and s.class_id = v_class_id
        and not s.is_archived
    )
  ) then
    raise exception 'section is outside the selected class scope'
      using errcode = '23503';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      p_tenant_id || ':student:' || lower(v_admission_no), 0
    )
  );
  if exists (
    select 1 from public.students s
    where s.tenant_id = p_tenant_id
      and lower(trim(s.admission_no)) = lower(v_admission_no)
  ) then
    raise exception 'admission number already exists'
      using errcode = '23505';
  end if;

  insert into public.students (
    tenant_id, campus_id, academic_year_id, class_id, section_id,
    admission_no, full_name, date_of_birth, gender, status,
    created_by, updated_by
  ) values (
    p_tenant_id, v_campus_id, v_academic_year_id, v_class_id, v_section_id,
    v_admission_no, v_full_name, v_date_of_birth, v_gender, v_status,
    (select auth.uid()), (select auth.uid())
  ) returning * into v_student;

  return v_student;
end;
$$;

create or replace function public.update_student(
  p_tenant_id text,
  p_student_id text,
  p_expected_updated_at timestamptz,
  p_payload jsonb
)
returns public.students
security definer
language plpgsql
set search_path = ''
as $$
declare
  v_existing public.students;
  v_student public.students;
  v_campus_id text := nullif(trim(p_payload->>'campus_id'), '');
  v_academic_year_id text := nullif(trim(p_payload->>'academic_year_id'), '');
  v_class_id text := nullif(trim(p_payload->>'class_id'), '');
  v_section_id text := nullif(trim(p_payload->>'section_id'), '');
  v_admission_no text := nullif(trim(p_payload->>'admission_no'), '');
  v_full_name text := nullif(trim(p_payload->>'full_name'), '');
  v_gender text := nullif(lower(trim(p_payload->>'gender')), '');
  v_status text := nullif(lower(trim(p_payload->>'status')), '');
  v_date_of_birth date;
begin
  if (select auth.uid()) is null
     or not private.has_permission(p_tenant_id, 'students.manage') then
    raise exception 'permission denied' using errcode = '42501';
  end if;
  if nullif(trim(p_student_id), '') is null or p_expected_updated_at is null then
    raise exception 'student id and expected update timestamp are required'
      using errcode = '22023';
  end if;
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'student payload must be an object' using errcode = '22023';
  end if;
  if (p_payload - array[
    'campus_id', 'academic_year_id', 'class_id', 'section_id',
    'admission_no', 'full_name', 'date_of_birth', 'gender', 'status'
  ]) <> '{}'::jsonb then
    raise exception 'student payload contains unsupported fields'
      using errcode = '22023';
  end if;

  select * into v_existing
  from public.students s
  where s.tenant_id = p_tenant_id and s.id = trim(p_student_id)
  for update;
  if not found or v_existing.is_archived then
    raise exception 'active student not found' using errcode = 'P0002';
  end if;
  if v_existing.updated_at is distinct from p_expected_updated_at then
    raise exception 'student was changed by another user; reload and retry'
      using errcode = '40001';
  end if;
  if not private.can_access_campus(p_tenant_id, v_existing.campus_id)
     or not private.can_access_campus(p_tenant_id, v_campus_id) then
    raise exception 'campus access denied' using errcode = '42501';
  end if;
  if v_campus_id is null or v_academic_year_id is null then
    raise exception 'campus and academic year are required'
      using errcode = '22023';
  end if;
  if v_admission_no is null or char_length(v_admission_no) > 50 then
    raise exception 'admission number must contain 1 to 50 characters'
      using errcode = '22023';
  end if;
  if v_full_name is null or char_length(v_full_name) not between 2 and 160 then
    raise exception 'student name must contain 2 to 160 characters'
      using errcode = '22023';
  end if;
  if v_status is null
     or v_status not in ('active', 'inactive', 'graduated', 'withdrawn') then
    raise exception 'unsupported student status' using errcode = '22023';
  end if;
  if v_gender is not null and v_gender not in ('male', 'female', 'other') then
    raise exception 'unsupported gender' using errcode = '22023';
  end if;
  if nullif(trim(p_payload->>'date_of_birth'), '') is not null then
    begin
      v_date_of_birth := (p_payload->>'date_of_birth')::date;
    exception when others then
      raise exception 'invalid date of birth' using errcode = '22023';
    end;
    if v_date_of_birth > current_date then
      raise exception 'date of birth cannot be in the future'
        using errcode = '22023';
    end if;
  end if;
  if not exists (
    select 1 from public.campuses c
    where c.tenant_id = p_tenant_id and c.id = v_campus_id
      and not c.is_archived
  ) then
    raise exception 'active campus not found' using errcode = '23503';
  end if;
  if not exists (
    select 1 from public.academic_years y
    where y.tenant_id = p_tenant_id and y.id = v_academic_year_id
      and not y.is_archived
  ) then
    raise exception 'active academic year not found' using errcode = '23503';
  end if;
  if v_class_id is not null and not exists (
    select 1 from public.classes c
    where c.tenant_id = p_tenant_id and c.id = v_class_id
      and c.campus_id = v_campus_id
      and c.academic_year_id = v_academic_year_id
      and not c.is_archived
  ) then
    raise exception 'class is outside the selected campus or academic year'
      using errcode = '23503';
  end if;
  if v_section_id is not null and (
    v_class_id is null or not exists (
      select 1 from public.sections s
      where s.tenant_id = p_tenant_id and s.id = v_section_id
        and s.campus_id = v_campus_id
        and s.academic_year_id = v_academic_year_id
        and s.class_id = v_class_id
        and not s.is_archived
    )
  ) then
    raise exception 'section is outside the selected class scope'
      using errcode = '23503';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      p_tenant_id || ':student:' || lower(v_admission_no), 0
    )
  );
  if exists (
    select 1 from public.students s
    where s.tenant_id = p_tenant_id
      and s.id <> v_existing.id
      and lower(trim(s.admission_no)) = lower(v_admission_no)
  ) then
    raise exception 'admission number already exists'
      using errcode = '23505';
  end if;

  update public.students
  set campus_id = v_campus_id,
      academic_year_id = v_academic_year_id,
      class_id = v_class_id,
      section_id = v_section_id,
      admission_no = v_admission_no,
      full_name = v_full_name,
      date_of_birth = v_date_of_birth,
      gender = v_gender,
      status = v_status,
      updated_by = (select auth.uid())
  where tenant_id = p_tenant_id and id = v_existing.id
  returning * into v_student;

  return v_student;
end;
$$;

create or replace function public.archive_student(
  p_tenant_id text,
  p_student_id text,
  p_expected_updated_at timestamptz
)
returns public.students
security definer
language plpgsql
set search_path = ''
as $$
declare
  v_existing public.students;
  v_student public.students;
begin
  if (select auth.uid()) is null
     or not private.has_permission(p_tenant_id, 'students.manage') then
    raise exception 'permission denied' using errcode = '42501';
  end if;
  if nullif(trim(p_student_id), '') is null or p_expected_updated_at is null then
    raise exception 'student id and expected update timestamp are required'
      using errcode = '22023';
  end if;

  select * into v_existing
  from public.students s
  where s.tenant_id = p_tenant_id and s.id = trim(p_student_id)
  for update;
  if not found or v_existing.is_archived then
    raise exception 'active student not found' using errcode = 'P0002';
  end if;
  if not private.can_access_campus(p_tenant_id, v_existing.campus_id) then
    raise exception 'campus access denied' using errcode = '42501';
  end if;
  if v_existing.updated_at is distinct from p_expected_updated_at then
    raise exception 'student was changed by another user; reload and retry'
      using errcode = '40001';
  end if;

  update public.students
  set is_archived = true,
      status = case when status = 'active' then 'inactive' else status end,
      updated_by = (select auth.uid())
  where tenant_id = p_tenant_id and id = v_existing.id
  returning * into v_student;

  return v_student;
end;
$$;

revoke all on function public.create_student(text, jsonb) from public;
revoke all on function public.update_student(text, text, timestamptz, jsonb)
  from public;
revoke all on function public.archive_student(text, text, timestamptz)
  from public;

grant execute on function public.create_student(text, jsonb) to authenticated;
grant execute on function public.update_student(text, text, timestamptz, jsonb)
  to authenticated;
grant execute on function public.archive_student(text, text, timestamptz)
  to authenticated;

commit;
