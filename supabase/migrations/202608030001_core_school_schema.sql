begin;

create extension if not exists pgcrypto;
create schema if not exists private;

create table public.tenants (
  id text primary key default (gen_random_uuid()::text),
  name text not null check (char_length(trim(name)) between 2 and 160),
  code text unique,
  timezone text not null default 'Asia/Karachi',
  currency text not null default 'PKR',
  is_active boolean not null default true,
  subscription jsonb not null default '{}'::jsonb,
  active_academic_year_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  phone text,
  locale text not null default 'en' check (locale in ('en', 'ur')),
  theme_mode text not null default 'light' check (theme_mode in ('light', 'dark', 'system')),
  active_tenant_id text references public.tenants(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.tenant_members (
  tenant_id text not null references public.tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  email text not null,
  display_name text not null default '',
  roles text[] not null default '{}',
  permissions text[] not null default '{}',
  denied_permissions text[] not null default '{}',
  campus_ids text[] not null default '{}',
  linked_record_type text,
  linked_record_id text,
  status text not null default 'active' check (status in ('active', 'invited', 'suspended')),
  is_active boolean not null default true,
  must_change_password boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, user_id)
);

create table public.campuses (
  tenant_id text not null references public.tenants(id) on delete cascade,
  id text not null default (gen_random_uuid()::text),
  code text not null,
  name text not null,
  address text,
  is_archived boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, id),
  unique (tenant_id, code)
);

create table public.academic_years (
  tenant_id text not null references public.tenants(id) on delete cascade,
  id text not null default (gen_random_uuid()::text),
  name text not null,
  starts_on date not null,
  ends_on date not null check (ends_on > starts_on),
  status text not null default 'draft' check (status in ('draft', 'active', 'closed')),
  is_archived boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, id),
  unique (tenant_id, name)
);

create table public.classes (
  tenant_id text not null,
  id text not null default (gen_random_uuid()::text),
  campus_id text not null,
  academic_year_id text not null,
  name text not null,
  sort_order integer not null default 0,
  is_archived boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, id),
  unique (tenant_id, campus_id, academic_year_id, name),
  foreign key (tenant_id, campus_id) references public.campuses(tenant_id, id),
  foreign key (tenant_id, academic_year_id) references public.academic_years(tenant_id, id)
);

create table public.sections (
  tenant_id text not null,
  id text not null default (gen_random_uuid()::text),
  campus_id text not null,
  academic_year_id text not null,
  class_id text not null,
  name text not null,
  capacity integer check (capacity is null or capacity > 0),
  is_archived boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, id),
  unique (tenant_id, class_id, name),
  foreign key (tenant_id, campus_id) references public.campuses(tenant_id, id),
  foreign key (tenant_id, academic_year_id) references public.academic_years(tenant_id, id),
  foreign key (tenant_id, class_id) references public.classes(tenant_id, id)
);

create table public.subjects (
  tenant_id text not null,
  id text not null default (gen_random_uuid()::text),
  campus_id text not null,
  academic_year_id text not null,
  code text not null,
  name text not null,
  is_archived boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, id),
  unique (tenant_id, code),
  foreign key (tenant_id, campus_id) references public.campuses(tenant_id, id),
  foreign key (tenant_id, academic_year_id) references public.academic_years(tenant_id, id)
);

create table public.students (
  tenant_id text not null,
  id text not null default (gen_random_uuid()::text),
  campus_id text not null,
  academic_year_id text not null,
  class_id text,
  section_id text,
  admission_no text not null,
  full_name text not null,
  date_of_birth date,
  gender text,
  auth_user_id uuid references auth.users(id),
  status text not null default 'active' check (status in ('active', 'inactive', 'graduated', 'withdrawn')),
  is_archived boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, id),
  unique (tenant_id, admission_no),
  foreign key (tenant_id, campus_id) references public.campuses(tenant_id, id),
  foreign key (tenant_id, academic_year_id) references public.academic_years(tenant_id, id),
  foreign key (tenant_id, class_id) references public.classes(tenant_id, id),
  foreign key (tenant_id, section_id) references public.sections(tenant_id, id)
);

create table public.guardians (
  tenant_id text not null,
  id text not null default (gen_random_uuid()::text),
  full_name text not null,
  phone text,
  email text,
  auth_user_id uuid references auth.users(id),
  is_archived boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, id)
);

create table public.student_guardians (
  tenant_id text not null,
  student_id text not null,
  guardian_id text not null,
  relationship text not null,
  is_primary boolean not null default false,
  can_pick_up boolean not null default true,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, student_id, guardian_id),
  foreign key (tenant_id, student_id) references public.students(tenant_id, id) on delete cascade,
  foreign key (tenant_id, guardian_id) references public.guardians(tenant_id, id) on delete cascade
);

create table public.fee_structures (
  tenant_id text not null,
  id text not null default (gen_random_uuid()::text),
  campus_id text not null,
  academic_year_id text not null,
  class_id text,
  name text not null,
  amount numeric(14,2) not null check (amount >= 0),
  frequency text not null default 'monthly' check (frequency in ('monthly', 'quarterly', 'annual', 'one_time')),
  is_archived boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, id),
  foreign key (tenant_id, campus_id) references public.campuses(tenant_id, id),
  foreign key (tenant_id, academic_year_id) references public.academic_years(tenant_id, id),
  foreign key (tenant_id, class_id) references public.classes(tenant_id, id)
);

create table public.fee_invoices (
  tenant_id text not null,
  id text not null default (gen_random_uuid()::text),
  campus_id text not null,
  academic_year_id text not null,
  student_id text not null,
  invoice_no text not null,
  billing_month date not null,
  due_date date not null,
  gross_amount numeric(14,2) not null check (gross_amount >= 0),
  discount_amount numeric(14,2) not null default 0 check (discount_amount >= 0),
  fine_amount numeric(14,2) not null default 0 check (fine_amount >= 0),
  paid_amount numeric(14,2) not null default 0 check (paid_amount >= 0),
  status text not null default 'unpaid' check (status in ('draft', 'unpaid', 'partial', 'paid', 'void')),
  is_archived boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, id),
  unique (tenant_id, invoice_no),
  unique (tenant_id, student_id, billing_month),
  foreign key (tenant_id, campus_id) references public.campuses(tenant_id, id),
  foreign key (tenant_id, academic_year_id) references public.academic_years(tenant_id, id),
  foreign key (tenant_id, student_id) references public.students(tenant_id, id)
);

create sequence if not exists public.fee_receipt_number_seq;

create table public.payments (
  tenant_id text not null,
  id text not null default (gen_random_uuid()::text),
  campus_id text not null,
  academic_year_id text not null,
  invoice_id text not null,
  student_id text not null,
  receipt_no text not null,
  amount numeric(14,2) not null check (amount > 0),
  method text not null check (method in ('cash', 'bank', 'card', 'jazzcash', 'easypaisa', 'other')),
  reference text,
  idempotency_key text not null,
  paid_at timestamptz not null default now(),
  status text not null default 'posted' check (status in ('posted', 'refunded', 'void')),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, id),
  unique (tenant_id, receipt_no),
  unique (tenant_id, idempotency_key),
  foreign key (tenant_id, campus_id) references public.campuses(tenant_id, id),
  foreign key (tenant_id, academic_year_id) references public.academic_years(tenant_id, id),
  foreign key (tenant_id, invoice_id) references public.fee_invoices(tenant_id, id),
  foreign key (tenant_id, student_id) references public.students(tenant_id, id)
);

create table public.attendance_sessions (
  tenant_id text not null,
  id text not null default (gen_random_uuid()::text),
  campus_id text not null,
  academic_year_id text not null,
  class_id text not null,
  section_id text not null,
  attendance_date date not null,
  status text not null default 'open' check (status in ('open', 'submitted', 'locked')),
  is_archived boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, id),
  unique (tenant_id, section_id, attendance_date),
  foreign key (tenant_id, campus_id) references public.campuses(tenant_id, id),
  foreign key (tenant_id, academic_year_id) references public.academic_years(tenant_id, id),
  foreign key (tenant_id, class_id) references public.classes(tenant_id, id),
  foreign key (tenant_id, section_id) references public.sections(tenant_id, id)
);

create table public.student_attendance (
  tenant_id text not null,
  session_id text not null,
  student_id text not null,
  status text not null check (status in ('present', 'absent', 'late', 'leave')),
  note text,
  marked_by uuid references auth.users(id),
  marked_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, session_id, student_id),
  foreign key (tenant_id, session_id) references public.attendance_sessions(tenant_id, id) on delete cascade,
  foreign key (tenant_id, student_id) references public.students(tenant_id, id)
);

create table public.exams (
  tenant_id text not null,
  id text not null default (gen_random_uuid()::text),
  campus_id text not null,
  academic_year_id text not null,
  name text not null,
  starts_on date,
  ends_on date,
  status text not null default 'draft' check (status in ('draft', 'marks_entry', 'review', 'published', 'closed')),
  is_archived boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, id),
  unique (tenant_id, academic_year_id, name),
  foreign key (tenant_id, campus_id) references public.campuses(tenant_id, id),
  foreign key (tenant_id, academic_year_id) references public.academic_years(tenant_id, id)
);

create table public.exam_results (
  tenant_id text not null,
  exam_id text not null,
  student_id text not null,
  subject_id text not null,
  marks_obtained numeric(8,2) not null check (marks_obtained >= 0),
  maximum_marks numeric(8,2) not null check (maximum_marks > 0),
  grade text,
  status text not null default 'draft' check (status in ('draft', 'review', 'published')),
  published_at timestamptz,
  published_by uuid references auth.users(id),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, exam_id, student_id, subject_id),
  check (marks_obtained <= maximum_marks),
  foreign key (tenant_id, exam_id) references public.exams(tenant_id, id) on delete cascade,
  foreign key (tenant_id, student_id) references public.students(tenant_id, id),
  foreign key (tenant_id, subject_id) references public.subjects(tenant_id, id)
);

create table public.announcements (
  tenant_id text not null,
  id text not null default (gen_random_uuid()::text),
  campus_id text,
  academic_year_id text,
  title text not null,
  body text not null,
  audience_roles text[] not null default '{}',
  published_at timestamptz,
  expires_at timestamptz,
  is_archived boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, id),
  foreign key (tenant_id, campus_id) references public.campuses(tenant_id, id),
  foreign key (tenant_id, academic_year_id) references public.academic_years(tenant_id, id)
);

create table public.expenses (
  tenant_id text not null,
  id text not null default (gen_random_uuid()::text),
  campus_id text not null,
  academic_year_id text not null,
  expense_no text not null,
  expense_date date not null,
  category text not null,
  description text not null,
  amount numeric(14,2) not null check (amount > 0),
  payment_method text not null,
  status text not null default 'draft' check (status in ('draft', 'approved', 'paid', 'void')),
  is_archived boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, id),
  unique (tenant_id, expense_no),
  foreign key (tenant_id, campus_id) references public.campuses(tenant_id, id),
  foreign key (tenant_id, academic_year_id) references public.academic_years(tenant_id, id)
);

create table public.dashboard_summaries (
  tenant_id text not null,
  campus_id text not null default 'all',
  academic_year_id text not null default 'all',
  counts jsonb not null default '{}'::jsonb,
  status_counts jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (tenant_id, campus_id, academic_year_id),
  foreign key (tenant_id) references public.tenants(id) on delete cascade
);

create table public.audit_logs (
  id bigint generated always as identity primary key,
  tenant_id text not null references public.tenants(id) on delete cascade,
  actor_user_id uuid references auth.users(id),
  action text not null,
  table_name text not null,
  record_id text,
  old_data jsonb,
  new_data jsonb,
  request_id text,
  created_at timestamptz not null default now()
);

create index tenant_members_user_idx on public.tenant_members(user_id, is_active);
create index students_scope_idx on public.students(tenant_id, campus_id, academic_year_id, is_archived, id);
create index students_class_idx on public.students(tenant_id, class_id, section_id, status);
create index guardians_auth_idx on public.guardians(tenant_id, auth_user_id) where auth_user_id is not null;
create index student_guardians_guardian_idx on public.student_guardians(tenant_id, guardian_id, student_id);
create index invoices_scope_idx on public.fee_invoices(tenant_id, campus_id, academic_year_id, status, due_date);
create index invoices_student_idx on public.fee_invoices(tenant_id, student_id, billing_month desc);
create index payments_student_idx on public.payments(tenant_id, student_id, paid_at desc);
create index attendance_session_scope_idx on public.attendance_sessions(tenant_id, campus_id, academic_year_id, attendance_date desc);
create index attendance_student_idx on public.student_attendance(tenant_id, student_id, session_id);
create index results_student_idx on public.exam_results(tenant_id, student_id, status, exam_id);
create index announcements_scope_idx on public.announcements(tenant_id, published_at desc) where is_archived = false;
create index expenses_scope_idx on public.expenses(tenant_id, campus_id, academic_year_id, expense_date desc);
create index audit_tenant_created_idx on public.audit_logs(tenant_id, created_at desc);

create or replace function private.is_active_member(target_tenant_id text)
returns boolean
security definer
language sql
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.tenant_members member
    join public.tenants tenant on tenant.id = member.tenant_id
    where member.tenant_id = target_tenant_id
      and member.user_id = (select auth.uid())
      and member.is_active
      and member.status = 'active'
      and tenant.is_active
  );
$$;

create or replace function private.has_permission(target_tenant_id text, required_permission text)
returns boolean
security definer
language sql
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.tenant_members member
    where member.tenant_id = target_tenant_id
      and member.user_id = (select auth.uid())
      and member.is_active
      and member.status = 'active'
      and not (required_permission = any(member.denied_permissions))
      and (
        '*' = any(member.permissions)
        or required_permission = any(member.permissions)
        or member.roles && array['superAdmin', 'schoolOwner']::text[]
      )
  );
$$;

create or replace function private.can_access_student(target_tenant_id text, target_student_id text)
returns boolean
security definer
language sql
stable
set search_path = ''
as $$
  select
    private.has_permission(target_tenant_id, 'students.view')
    or exists (
      select 1 from public.students student
      where student.tenant_id = target_tenant_id
        and student.id = target_student_id
        and student.auth_user_id = (select auth.uid())
    )
    or exists (
      select 1
      from public.student_guardians link
      join public.guardians guardian
        on guardian.tenant_id = link.tenant_id
       and guardian.id = link.guardian_id
      where link.tenant_id = target_tenant_id
        and link.student_id = target_student_id
        and guardian.auth_user_id = (select auth.uid())
    );
$$;

create or replace function private.matches_member_audience(
  target_tenant_id text,
  audience text[]
)
returns boolean
security definer
language sql
stable
set search_path = ''
as $$
  select exists (
    select 1 from public.tenant_members member
    where member.tenant_id = target_tenant_id
      and member.user_id = (select auth.uid())
      and member.is_active
      and member.status = 'active'
      and (cardinality(audience) = 0 or member.roles && audience)
  );
$$;

revoke all on schema private from public;
grant usage on schema private to authenticated;
grant execute on function private.is_active_member(text) to authenticated;
grant execute on function private.has_permission(text, text) to authenticated;
grant execute on function private.can_access_student(text, text) to authenticated;
grant execute on function private.matches_member_audience(text, text[]) to authenticated;

create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  if to_jsonb(new) ? 'updated_by' then
    new.updated_by = (select auth.uid());
  end if;
  return new;
end;
$$;

create or replace function private.audit_row_change()
returns trigger
security definer
language plpgsql
set search_path = ''
as $$
declare
  before_data jsonb;
  after_data jsonb;
  row_data jsonb;
begin
  before_data := case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) else null end;
  after_data := case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) else null end;
  row_data := coalesce(after_data, before_data);

  insert into public.audit_logs (
    tenant_id, actor_user_id, action, table_name, record_id, old_data, new_data
  ) values (
    row_data ->> 'tenant_id',
    (select auth.uid()),
    lower(tg_op),
    tg_table_name,
    coalesce(row_data ->> 'id', row_data ->> 'student_id', row_data ->> 'invoice_id'),
    before_data,
    after_data
  );

  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'tenants', 'profiles', 'tenant_members', 'campuses', 'academic_years',
    'classes', 'sections', 'subjects', 'students', 'guardians',
    'student_guardians', 'fee_structures', 'fee_invoices', 'payments',
    'attendance_sessions', 'student_attendance', 'exams', 'exam_results',
    'announcements', 'expenses', 'dashboard_summaries', 'audit_logs'
  ] loop
    execute format('alter table public.%I enable row level security', table_name);
    execute format('alter table public.%I force row level security', table_name);
  end loop;
end $$;

create policy tenants_read_member on public.tenants for select to authenticated
using (private.is_active_member(id));

create policy profiles_read_self on public.profiles for select to authenticated
using (user_id = (select auth.uid()));
create policy profiles_update_self on public.profiles for update to authenticated
using (user_id = (select auth.uid()))
with check (
  user_id = (select auth.uid())
  and (
    active_tenant_id is null
    or private.is_active_member(active_tenant_id)
  )
);

create policy members_read_authorized on public.tenant_members for select to authenticated
using (
  user_id = (select auth.uid())
  or private.has_permission(tenant_id, 'users.manage')
);

do $$
declare
  table_name text;
  permission_name text;
begin
  for table_name, permission_name in
    values
      ('campuses', 'school_setup.manage'),
      ('academic_years', 'school_setup.manage'),
      ('classes', 'school_setup.manage'),
      ('sections', 'school_setup.manage'),
      ('subjects', 'school_setup.manage'),
      ('fee_structures', 'fees.manage'),
      ('attendance_sessions', 'attendance.manage'),
      ('exams', 'exams.manage')
  loop
    execute format(
      'create policy %I on public.%I for select to authenticated using (private.is_active_member(tenant_id))',
      table_name || '_read_member', table_name
    );
    execute format(
      'create policy %I on public.%I for insert to authenticated with check (private.has_permission(tenant_id, %L))',
      table_name || '_insert_manage', table_name, permission_name
    );
    execute format(
      'create policy %I on public.%I for update to authenticated using (private.has_permission(tenant_id, %L)) with check (private.has_permission(tenant_id, %L))',
      table_name || '_update_manage', table_name, permission_name, permission_name
    );
  end loop;
end $$;

create policy students_read_scoped on public.students for select to authenticated
using (private.can_access_student(tenant_id, id));
create policy students_insert_manage on public.students for insert to authenticated
with check (private.has_permission(tenant_id, 'students.manage'));
create policy students_update_manage on public.students for update to authenticated
using (private.has_permission(tenant_id, 'students.manage'))
with check (private.has_permission(tenant_id, 'students.manage'));

create policy guardians_read_scoped on public.guardians for select to authenticated
using (
  private.has_permission(tenant_id, 'parents.view')
  or auth_user_id = (select auth.uid())
);
create policy guardians_insert_manage on public.guardians for insert to authenticated
with check (private.has_permission(tenant_id, 'parents.manage'));
create policy guardians_update_manage on public.guardians for update to authenticated
using (private.has_permission(tenant_id, 'parents.manage'))
with check (private.has_permission(tenant_id, 'parents.manage'));

create policy student_guardians_read_scoped on public.student_guardians for select to authenticated
using (private.can_access_student(tenant_id, student_id));
create policy student_guardians_insert_manage on public.student_guardians for insert to authenticated
with check (private.has_permission(tenant_id, 'parents.manage'));
create policy student_guardians_update_manage on public.student_guardians for update to authenticated
using (private.has_permission(tenant_id, 'parents.manage'))
with check (private.has_permission(tenant_id, 'parents.manage'));

create policy invoices_read_scoped on public.fee_invoices for select to authenticated
using (
  private.has_permission(tenant_id, 'fees.view')
  or private.can_access_student(tenant_id, student_id)
);
create policy invoices_insert_manage on public.fee_invoices for insert to authenticated
with check (private.has_permission(tenant_id, 'fees.manage'));
create policy invoices_update_manage on public.fee_invoices for update to authenticated
using (private.has_permission(tenant_id, 'fees.manage'))
with check (private.has_permission(tenant_id, 'fees.manage'));

create policy payments_read_scoped on public.payments for select to authenticated
using (
  private.has_permission(tenant_id, 'fees.view')
  or private.can_access_student(tenant_id, student_id)
);

create policy attendance_read_scoped on public.student_attendance for select to authenticated
using (
  private.has_permission(tenant_id, 'attendance.view')
  or private.can_access_student(tenant_id, student_id)
);
create policy attendance_insert_manage on public.student_attendance for insert to authenticated
with check (private.has_permission(tenant_id, 'attendance.manage'));
create policy attendance_update_manage on public.student_attendance for update to authenticated
using (private.has_permission(tenant_id, 'attendance.manage'))
with check (private.has_permission(tenant_id, 'attendance.manage'));

create policy results_read_scoped on public.exam_results for select to authenticated
using (
  private.has_permission(tenant_id, 'exams.view')
  or (status = 'published' and private.can_access_student(tenant_id, student_id))
);

create policy announcements_read_scoped on public.announcements for select to authenticated
using (
  private.has_permission(tenant_id, 'communication.manage')
  or (
    published_at is not null
    and published_at <= now()
    and (expires_at is null or expires_at > now())
    and private.matches_member_audience(tenant_id, audience_roles)
  )
);
create policy announcements_insert_manage on public.announcements for insert to authenticated
with check (private.has_permission(tenant_id, 'communication.manage'));
create policy announcements_update_manage on public.announcements for update to authenticated
using (private.has_permission(tenant_id, 'communication.manage'))
with check (private.has_permission(tenant_id, 'communication.manage'));

create policy expenses_read_authorized on public.expenses for select to authenticated
using (private.has_permission(tenant_id, 'accounting.view'));

create policy summaries_read_member on public.dashboard_summaries for select to authenticated
using (private.is_active_member(tenant_id));

create policy audit_read_authorized on public.audit_logs for select to authenticated
using (private.has_permission(tenant_id, 'audit.view'));

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'tenants', 'profiles', 'tenant_members', 'campuses', 'academic_years',
    'classes', 'sections', 'subjects', 'students', 'guardians',
    'student_guardians', 'fee_structures', 'fee_invoices', 'payments',
    'attendance_sessions', 'student_attendance', 'exams', 'exam_results',
    'announcements', 'expenses'
  ] loop
    execute format(
      'create trigger %I before update on public.%I for each row execute function private.set_updated_at()',
      table_name || '_set_updated_at', table_name
    );
  end loop;
end $$;

grant select on public.tenants, public.profiles, public.tenant_members,
  public.campuses, public.academic_years, public.classes, public.sections,
  public.subjects, public.students, public.guardians,
  public.student_guardians, public.fee_structures, public.fee_invoices,
  public.payments, public.attendance_sessions, public.student_attendance,
  public.exams, public.exam_results, public.announcements, public.expenses,
  public.dashboard_summaries, public.audit_logs to authenticated;
grant insert, update on public.profiles to authenticated;
grant insert, update on public.campuses, public.academic_years, public.classes,
  public.sections, public.subjects, public.students, public.guardians,
  public.student_guardians, public.fee_structures, public.fee_invoices,
  public.attendance_sessions, public.student_attendance, public.exams,
  public.announcements to authenticated;

create or replace function private.handle_new_auth_user()
returns trigger
security definer
language plpgsql
set search_path = ''
as $$
begin
  insert into public.profiles (user_id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', ''))
  on conflict (user_id) do nothing;
  return new;
end;
$$;

create trigger auth_user_profile_created
after insert on auth.users
for each row execute function private.handle_new_auth_user();

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'tenant_members', 'students', 'guardians', 'student_guardians',
    'fee_structures', 'fee_invoices', 'payments', 'attendance_sessions',
    'student_attendance', 'exams', 'exam_results', 'announcements', 'expenses'
  ] loop
    execute format(
      'create trigger %I after insert or update or delete on public.%I for each row execute function private.audit_row_change()',
      table_name || '_audit', table_name
    );
  end loop;
end $$;

create or replace function public.record_fee_payment(
  p_tenant_id text,
  p_invoice_id text,
  p_amount numeric,
  p_method text,
  p_reference text,
  p_idempotency_key text
)
returns public.payments
security definer
language plpgsql
set search_path = ''
as $$
declare
  invoice public.fee_invoices;
  payment public.payments;
  balance numeric(14,2);
  receipt text;
begin
  if not private.has_permission(p_tenant_id, 'fees.collect')
     and not private.has_permission(p_tenant_id, 'fees.manage') then
    raise exception 'permission denied' using errcode = '42501';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'payment amount must be positive' using errcode = '22023';
  end if;
  if p_method not in ('cash', 'bank', 'card', 'jazzcash', 'easypaisa', 'other') then
    raise exception 'unsupported payment method' using errcode = '22023';
  end if;
  if nullif(trim(p_idempotency_key), '') is null then
    raise exception 'idempotency key is required' using errcode = '22023';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_tenant_id || ':' || trim(p_idempotency_key), 0)
  );

  select * into payment
  from public.payments
  where tenant_id = p_tenant_id
    and idempotency_key = trim(p_idempotency_key);
  if found then
    if payment.invoice_id <> p_invoice_id or payment.amount <> p_amount then
      raise exception 'idempotency key was already used for another payment'
        using errcode = '22023';
    end if;
    return payment;
  end if;

  select * into invoice
  from public.fee_invoices
  where tenant_id = p_tenant_id and id = p_invoice_id and not is_archived
  for update;

  if not found or invoice.status in ('draft', 'void', 'paid') then
    raise exception 'invoice is not payable' using errcode = 'P0001';
  end if;

  balance := invoice.gross_amount - invoice.discount_amount
    + invoice.fine_amount - invoice.paid_amount;
  if p_amount > balance then
    raise exception 'payment exceeds outstanding balance' using errcode = '22023';
  end if;

  receipt := 'RCPT-' || to_char(current_date, 'YYYYMM') || '-'
    || lpad(nextval('public.fee_receipt_number_seq')::text, 8, '0');

  insert into public.payments (
    tenant_id, campus_id, academic_year_id, invoice_id, student_id,
    receipt_no, amount, method, reference, idempotency_key, created_by
  ) values (
    p_tenant_id, invoice.campus_id, invoice.academic_year_id, invoice.id,
    invoice.student_id, receipt, p_amount, p_method, nullif(trim(p_reference), ''),
    trim(p_idempotency_key), (select auth.uid())
  ) returning * into payment;

  update public.fee_invoices
  set paid_amount = paid_amount + p_amount,
      status = case when paid_amount + p_amount >=
        gross_amount - discount_amount + fine_amount then 'paid' else 'partial' end,
      updated_by = (select auth.uid())
  where tenant_id = p_tenant_id and id = invoice.id;

  return payment;
end;
$$;

revoke all on function public.record_fee_payment(text, text, numeric, text, text, text) from public;
grant execute on function public.record_fee_payment(text, text, numeric, text, text, text) to authenticated;

commit;
