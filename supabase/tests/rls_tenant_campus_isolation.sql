-- This integration test creates temporary identities and business rows, then
-- rolls the entire transaction back. Run as postgres in a non-production test
-- window after applying all migrations.

begin;

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  (
    '00000000-0000-0000-0000-000000000000',
    '10000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated', 'rls-a@example.invalid', '', now(),
    '{}'::jsonb, '{}'::jsonb, now(), now()
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '20000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated', 'rls-b@example.invalid', '', now(),
    '{}'::jsonb, '{}'::jsonb, now(), now()
  );

insert into public.tenants (id, name) values
  ('rls-tenant-a', 'RLS Tenant A'),
  ('rls-tenant-b', 'RLS Tenant B');

insert into public.tenant_members (
  tenant_id, user_id, email, roles, permissions, campus_ids
) values
  (
    'rls-tenant-a', '10000000-0000-0000-0000-000000000001',
    'rls-a@example.invalid', array['schoolOwner'], array['*'], array['campus-a1']
  ),
  (
    'rls-tenant-b', '20000000-0000-0000-0000-000000000002',
    'rls-b@example.invalid', array['schoolOwner'], array['*'], array['campus-b1']
  );

insert into public.campuses (tenant_id, id, code, name) values
  ('rls-tenant-a', 'campus-a1', 'A1', 'Allowed Campus'),
  ('rls-tenant-a', 'campus-a2', 'A2', 'Blocked Campus'),
  ('rls-tenant-b', 'campus-b1', 'B1', 'Other Tenant Campus');

insert into public.academic_years (
  tenant_id, id, name, starts_on, ends_on, status
) values
  ('rls-tenant-a', 'year-a', '2026-2027', '2026-04-01', '2027-03-31', 'active'),
  ('rls-tenant-b', 'year-b', '2026-2027', '2026-04-01', '2027-03-31', 'active');

insert into public.students (
  tenant_id, id, campus_id, academic_year_id, admission_no, full_name
) values
  ('rls-tenant-a', 'student-a1', 'campus-a1', 'year-a', 'A-001', 'Allowed Student'),
  ('rls-tenant-a', 'student-a2', 'campus-a2', 'year-a', 'A-002', 'Blocked Student'),
  ('rls-tenant-b', 'student-b1', 'campus-b1', 'year-b', 'B-001', 'Other Student');

insert into public.fee_invoices (
  tenant_id, id, campus_id, academic_year_id, student_id, invoice_no,
  billing_month, due_date, gross_amount
) values
  (
    'rls-tenant-a', 'invoice-a1', 'campus-a1', 'year-a', 'student-a1',
    'INV-A1', '2026-08-01', '2026-08-10', 1000
  ),
  (
    'rls-tenant-a', 'invoice-a2', 'campus-a2', 'year-a', 'student-a2',
    'INV-A2', '2026-08-01', '2026-08-10', 1000
  );

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '10000000-0000-0000-0000-000000000001',
  true
);

do $$
declare
  denied boolean;
begin
  if (select count(*) from public.tenants) <> 1 then
    raise exception 'tenant isolation test failed';
  end if;
  if (select count(*) from public.campuses) <> 1 then
    raise exception 'campus isolation test failed';
  end if;
  if (select count(*) from public.students) <> 1 then
    raise exception 'student campus isolation test failed';
  end if;
  if (select count(*) from public.fee_invoices) <> 1 then
    raise exception 'invoice campus isolation test failed';
  end if;

  denied := false;
  begin
    insert into public.students (
      tenant_id, id, campus_id, academic_year_id, admission_no, full_name
    ) values (
      'rls-tenant-a', 'student-denied-campus', 'campus-a2', 'year-a',
      'A-DENIED', 'Denied Campus Student'
    );
  exception when insufficient_privilege then
    denied := true;
  end;
  if not denied then
    raise exception 'cross-campus student write was not denied';
  end if;

  denied := false;
  begin
    perform public.record_fee_payment(
      'rls-tenant-a', 'invoice-a2', 10, 'cash', null, 'blocked-campus-payment'
    );
  exception when insufficient_privilege then
    denied := true;
  end;
  if not denied then
    raise exception 'cross-campus payment was not denied';
  end if;

  perform public.record_fee_payment(
    'rls-tenant-a', 'invoice-a1', 10, 'cash', null, 'allowed-campus-payment'
  );
end;
$$;

reset role;
rollback;

select 'RLS tenant/campus/payment integration tests passed' as result;
