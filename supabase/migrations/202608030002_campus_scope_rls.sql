begin;

create or replace function private.can_access_campus(
  target_tenant_id text,
  target_campus_id text
)
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
      and (
        cardinality(member.campus_ids) = 0
        or (
          target_campus_id <> 'all'
          and target_campus_id = any(member.campus_ids)
        )
      )
  );
$$;

grant execute on function private.can_access_campus(text, text) to authenticated;

create or replace function private.can_access_student_campus(
  target_tenant_id text,
  target_student_id text
)
returns boolean
security definer
language sql
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.students student
    where student.tenant_id = target_tenant_id
      and student.id = target_student_id
      and private.can_access_campus(target_tenant_id, student.campus_id)
  );
$$;

grant execute on function private.can_access_student_campus(text, text) to authenticated;

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
    exists (
      select 1
      from public.students student
      where student.tenant_id = target_tenant_id
        and student.id = target_student_id
        and private.has_permission(target_tenant_id, 'students.view')
        and private.can_access_student_campus(target_tenant_id, target_student_id)
    )
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

drop policy if exists students_insert_manage on public.students;
create policy students_insert_manage on public.students for insert to authenticated
with check (
  private.has_permission(tenant_id, 'students.manage')
  and private.can_access_campus(tenant_id, campus_id)
);
drop policy if exists students_update_manage on public.students;
create policy students_update_manage on public.students for update to authenticated
using (
  private.has_permission(tenant_id, 'students.manage')
  and private.can_access_campus(tenant_id, campus_id)
)
with check (
  private.has_permission(tenant_id, 'students.manage')
  and private.can_access_campus(tenant_id, campus_id)
);

drop policy if exists student_guardians_insert_manage on public.student_guardians;
create policy student_guardians_insert_manage on public.student_guardians for insert to authenticated
with check (
  private.has_permission(tenant_id, 'parents.manage')
  and private.can_access_student_campus(tenant_id, student_id)
);
drop policy if exists student_guardians_update_manage on public.student_guardians;
create policy student_guardians_update_manage on public.student_guardians for update to authenticated
using (
  private.has_permission(tenant_id, 'parents.manage')
  and private.can_access_student_campus(tenant_id, student_id)
)
with check (
  private.has_permission(tenant_id, 'parents.manage')
  and private.can_access_student_campus(tenant_id, student_id)
);

drop policy if exists invoices_read_scoped on public.fee_invoices;
create policy invoices_read_scoped on public.fee_invoices for select to authenticated
using (
  (
    private.has_permission(tenant_id, 'fees.view')
    and private.can_access_student_campus(tenant_id, student_id)
  )
  or private.can_access_student(tenant_id, student_id)
);
drop policy if exists invoices_insert_manage on public.fee_invoices;
create policy invoices_insert_manage on public.fee_invoices for insert to authenticated
with check (
  private.has_permission(tenant_id, 'fees.manage')
  and private.can_access_student_campus(tenant_id, student_id)
);
drop policy if exists invoices_update_manage on public.fee_invoices;
create policy invoices_update_manage on public.fee_invoices for update to authenticated
using (
  private.has_permission(tenant_id, 'fees.manage')
  and private.can_access_student_campus(tenant_id, student_id)
)
with check (
  private.has_permission(tenant_id, 'fees.manage')
  and private.can_access_student_campus(tenant_id, student_id)
);

drop policy if exists payments_read_scoped on public.payments;
create policy payments_read_scoped on public.payments for select to authenticated
using (
  (
    private.has_permission(tenant_id, 'fees.view')
    and private.can_access_student_campus(tenant_id, student_id)
  )
  or private.can_access_student(tenant_id, student_id)
);

drop policy if exists attendance_read_scoped on public.student_attendance;
create policy attendance_read_scoped on public.student_attendance for select to authenticated
using (
  (
    private.has_permission(tenant_id, 'attendance.view')
    and private.can_access_student_campus(tenant_id, student_id)
  )
  or private.can_access_student(tenant_id, student_id)
);
drop policy if exists attendance_insert_manage on public.student_attendance;
create policy attendance_insert_manage on public.student_attendance for insert to authenticated
with check (
  private.has_permission(tenant_id, 'attendance.manage')
  and private.can_access_student_campus(tenant_id, student_id)
);
drop policy if exists attendance_update_manage on public.student_attendance;
create policy attendance_update_manage on public.student_attendance for update to authenticated
using (
  private.has_permission(tenant_id, 'attendance.manage')
  and private.can_access_student_campus(tenant_id, student_id)
)
with check (
  private.has_permission(tenant_id, 'attendance.manage')
  and private.can_access_student_campus(tenant_id, student_id)
);

drop policy if exists results_read_scoped on public.exam_results;
create policy results_read_scoped on public.exam_results for select to authenticated
using (
  (
    private.has_permission(tenant_id, 'exams.view')
    and private.can_access_student_campus(tenant_id, student_id)
  )
  or (
    status = 'published'
    and private.can_access_student(tenant_id, student_id)
  )
);

drop policy if exists campuses_read_member on public.campuses;
create policy campuses_read_scoped on public.campuses for select to authenticated
using (private.can_access_campus(tenant_id, id));
drop policy if exists campuses_insert_manage on public.campuses;
create policy campuses_insert_manage on public.campuses for insert to authenticated
with check (
  private.has_permission(tenant_id, 'school_setup.manage')
  and private.can_access_campus(tenant_id, id)
);
drop policy if exists campuses_update_manage on public.campuses;
create policy campuses_update_manage on public.campuses for update to authenticated
using (
  private.has_permission(tenant_id, 'school_setup.manage')
  and private.can_access_campus(tenant_id, id)
)
with check (
  private.has_permission(tenant_id, 'school_setup.manage')
  and private.can_access_campus(tenant_id, id)
);

drop policy if exists classes_read_member on public.classes;
create policy classes_read_scoped on public.classes for select to authenticated
using (private.can_access_campus(tenant_id, campus_id));
drop policy if exists classes_insert_manage on public.classes;
create policy classes_insert_manage on public.classes for insert to authenticated
with check (
  private.has_permission(tenant_id, 'school_setup.manage')
  and private.can_access_campus(tenant_id, campus_id)
);
drop policy if exists classes_update_manage on public.classes;
create policy classes_update_manage on public.classes for update to authenticated
using (
  private.has_permission(tenant_id, 'school_setup.manage')
  and private.can_access_campus(tenant_id, campus_id)
)
with check (
  private.has_permission(tenant_id, 'school_setup.manage')
  and private.can_access_campus(tenant_id, campus_id)
);

drop policy if exists sections_read_member on public.sections;
create policy sections_read_scoped on public.sections for select to authenticated
using (private.can_access_campus(tenant_id, campus_id));
drop policy if exists sections_insert_manage on public.sections;
create policy sections_insert_manage on public.sections for insert to authenticated
with check (
  private.has_permission(tenant_id, 'school_setup.manage')
  and private.can_access_campus(tenant_id, campus_id)
);
drop policy if exists sections_update_manage on public.sections;
create policy sections_update_manage on public.sections for update to authenticated
using (
  private.has_permission(tenant_id, 'school_setup.manage')
  and private.can_access_campus(tenant_id, campus_id)
)
with check (
  private.has_permission(tenant_id, 'school_setup.manage')
  and private.can_access_campus(tenant_id, campus_id)
);

drop policy if exists subjects_read_member on public.subjects;
create policy subjects_read_scoped on public.subjects for select to authenticated
using (private.can_access_campus(tenant_id, campus_id));
drop policy if exists subjects_insert_manage on public.subjects;
create policy subjects_insert_manage on public.subjects for insert to authenticated
with check (
  private.has_permission(tenant_id, 'school_setup.manage')
  and private.can_access_campus(tenant_id, campus_id)
);
drop policy if exists subjects_update_manage on public.subjects;
create policy subjects_update_manage on public.subjects for update to authenticated
using (
  private.has_permission(tenant_id, 'school_setup.manage')
  and private.can_access_campus(tenant_id, campus_id)
)
with check (
  private.has_permission(tenant_id, 'school_setup.manage')
  and private.can_access_campus(tenant_id, campus_id)
);

drop policy if exists fee_structures_read_member on public.fee_structures;
create policy fee_structures_read_scoped on public.fee_structures for select to authenticated
using (private.can_access_campus(tenant_id, campus_id));
drop policy if exists fee_structures_insert_manage on public.fee_structures;
create policy fee_structures_insert_manage on public.fee_structures for insert to authenticated
with check (
  private.has_permission(tenant_id, 'fees.manage')
  and private.can_access_campus(tenant_id, campus_id)
);
drop policy if exists fee_structures_update_manage on public.fee_structures;
create policy fee_structures_update_manage on public.fee_structures for update to authenticated
using (
  private.has_permission(tenant_id, 'fees.manage')
  and private.can_access_campus(tenant_id, campus_id)
)
with check (
  private.has_permission(tenant_id, 'fees.manage')
  and private.can_access_campus(tenant_id, campus_id)
);

drop policy if exists attendance_sessions_read_member on public.attendance_sessions;
create policy attendance_sessions_read_scoped on public.attendance_sessions for select to authenticated
using (private.can_access_campus(tenant_id, campus_id));
drop policy if exists attendance_sessions_insert_manage on public.attendance_sessions;
create policy attendance_sessions_insert_manage on public.attendance_sessions for insert to authenticated
with check (
  private.has_permission(tenant_id, 'attendance.manage')
  and private.can_access_campus(tenant_id, campus_id)
);
drop policy if exists attendance_sessions_update_manage on public.attendance_sessions;
create policy attendance_sessions_update_manage on public.attendance_sessions for update to authenticated
using (
  private.has_permission(tenant_id, 'attendance.manage')
  and private.can_access_campus(tenant_id, campus_id)
)
with check (
  private.has_permission(tenant_id, 'attendance.manage')
  and private.can_access_campus(tenant_id, campus_id)
);

drop policy if exists exams_read_member on public.exams;
create policy exams_read_scoped on public.exams for select to authenticated
using (private.can_access_campus(tenant_id, campus_id));
drop policy if exists exams_insert_manage on public.exams;
create policy exams_insert_manage on public.exams for insert to authenticated
with check (
  private.has_permission(tenant_id, 'exams.manage')
  and private.can_access_campus(tenant_id, campus_id)
);
drop policy if exists exams_update_manage on public.exams;
create policy exams_update_manage on public.exams for update to authenticated
using (
  private.has_permission(tenant_id, 'exams.manage')
  and private.can_access_campus(tenant_id, campus_id)
)
with check (
  private.has_permission(tenant_id, 'exams.manage')
  and private.can_access_campus(tenant_id, campus_id)
);

drop policy if exists guardians_read_scoped on public.guardians;
create policy guardians_read_scoped on public.guardians for select to authenticated
using (
  auth_user_id = (select auth.uid())
  or exists (
    select 1
    from public.student_guardians link
    where link.tenant_id = guardians.tenant_id
      and link.guardian_id = guardians.id
      and private.can_access_student(link.tenant_id, link.student_id)
  )
);

drop policy if exists announcements_read_scoped on public.announcements;
create policy announcements_read_scoped on public.announcements for select to authenticated
using (
  private.has_permission(tenant_id, 'communication.manage')
  and (campus_id is null or private.can_access_campus(tenant_id, campus_id))
  or (
    published_at is not null
    and published_at <= now()
    and (expires_at is null or expires_at > now())
    and (campus_id is null or private.can_access_campus(tenant_id, campus_id))
    and private.matches_member_audience(tenant_id, audience_roles)
  )
);
drop policy if exists announcements_insert_manage on public.announcements;
create policy announcements_insert_manage on public.announcements for insert to authenticated
with check (
  private.has_permission(tenant_id, 'communication.manage')
  and (campus_id is null or private.can_access_campus(tenant_id, campus_id))
);
drop policy if exists announcements_update_manage on public.announcements;
create policy announcements_update_manage on public.announcements for update to authenticated
using (
  private.has_permission(tenant_id, 'communication.manage')
  and (campus_id is null or private.can_access_campus(tenant_id, campus_id))
)
with check (
  private.has_permission(tenant_id, 'communication.manage')
  and (campus_id is null or private.can_access_campus(tenant_id, campus_id))
);

drop policy if exists expenses_read_authorized on public.expenses;
create policy expenses_read_authorized on public.expenses for select to authenticated
using (
  private.has_permission(tenant_id, 'accounting.view')
  and private.can_access_campus(tenant_id, campus_id)
);

drop policy if exists summaries_read_member on public.dashboard_summaries;
create policy summaries_read_scoped on public.dashboard_summaries for select to authenticated
using (private.can_access_campus(tenant_id, campus_id));

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
    if not private.can_access_campus(p_tenant_id, payment.campus_id) then
      raise exception 'campus access denied' using errcode = '42501';
    end if;
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
  if not private.can_access_campus(p_tenant_id, invoice.campus_id) then
    raise exception 'campus access denied' using errcode = '42501';
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

commit;
