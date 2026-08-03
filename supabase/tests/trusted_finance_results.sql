begin;

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000000',
  '50000000-0000-0000-0000-000000000005',
  'authenticated', 'authenticated', 'trusted-rpc@example.invalid', '', now(),
  '{}'::jsonb, '{}'::jsonb, now(), now()
);

insert into public.tenants (id, name) values ('trusted-rpc-tenant', 'Trusted RPC School');
insert into public.tenant_members (
  tenant_id, user_id, email, roles, permissions, campus_ids
) values (
  'trusted-rpc-tenant', '50000000-0000-0000-0000-000000000005',
  'trusted-rpc@example.invalid', array['schoolOwner'], array['*'],
  array['trusted-rpc-campus']
);
insert into public.campuses (tenant_id, id, code, name)
values ('trusted-rpc-tenant', 'trusted-rpc-campus', 'TRUST', 'Trusted Campus');
insert into public.academic_years (
  tenant_id, id, name, starts_on, ends_on, status
) values (
  'trusted-rpc-tenant', 'trusted-rpc-year', '2026-2027',
  '2026-04-01', '2027-03-31', 'active'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '50000000-0000-0000-0000-000000000005', true);

do $$
declare
  payroll public.erp_records;
  payroll_again public.erp_records;
  journal public.erp_records;
  result_record public.erp_records;
  denied boolean;
begin
  payroll := public.create_trusted_erp_record(
    'trusted-rpc-tenant', 'payroll_runs', 'trusted-rpc-campus', 'trusted-rpc-year',
    '{"period":"August 2026","grossAmount":1000,"deductions":100}'::jsonb,
    'payroll-idempotency'
  );
  payroll_again := public.create_trusted_erp_record(
    'trusted-rpc-tenant', 'payroll_runs', 'trusted-rpc-campus', 'trusted-rpc-year',
    '{"period":"August 2026","grossAmount":1000,"deductions":100}'::jsonb,
    'payroll-idempotency'
  );
  if payroll.id <> payroll_again.id or payroll.status <> 'Draft'
     or (payroll.data->>'netAmount')::numeric <> 900 then
    raise exception 'payroll validation or idempotency failed';
  end if;

  denied := false;
  begin
    perform public.create_trusted_erp_record(
      'trusted-rpc-tenant', 'journal_entries', 'trusted-rpc-campus', 'trusted-rpc-year',
      '{"voucherNo":"JV-BAD","debitAmount":100,"creditAmount":90}'::jsonb,
      'bad-journal'
    );
  exception when invalid_parameter_value then denied := true;
  end;
  if not denied then raise exception 'unbalanced journal was accepted'; end if;

  journal := public.create_trusted_erp_record(
    'trusted-rpc-tenant', 'journal_entries', 'trusted-rpc-campus', 'trusted-rpc-year',
    '{"voucherNo":"JV-TEST-1","debitAmount":100,"creditAmount":100}'::jsonb,
    'good-journal'
  );
  journal := public.transition_trusted_erp_record(
    'trusted-rpc-tenant', 'journal_entries', journal.id, 'Draft', 'Submitted'
  );
  journal := public.transition_trusted_erp_record(
    'trusted-rpc-tenant', 'journal_entries', journal.id, 'Submitted', 'Approved'
  );
  journal := public.transition_trusted_erp_record(
    'trusted-rpc-tenant', 'journal_entries', journal.id, 'Approved', 'Posted'
  );
  if journal.status <> 'Posted' then raise exception 'journal workflow failed'; end if;

  result_record := public.create_trusted_erp_record(
    'trusted-rpc-tenant', 'exam_results', 'trusted-rpc-campus', 'trusted-rpc-year',
    '{"examName":"Annual 2026","studentId":"STU-1","obtainedMarks":450,"totalMarks":900}'::jsonb,
    'result-1'
  );
  if (result_record.data->>'percentage')::numeric <> 50 then
    raise exception 'result percentage was not calculated server-side';
  end if;
  result_record := public.transition_trusted_erp_record(
    'trusted-rpc-tenant', 'exam_results', result_record.id, 'Calculated', 'Under Review'
  );
  result_record := public.transition_trusted_erp_record(
    'trusted-rpc-tenant', 'exam_results', result_record.id, 'Under Review', 'Approved'
  );
  result_record := public.transition_trusted_erp_record(
    'trusted-rpc-tenant', 'exam_results', result_record.id, 'Approved', 'Published'
  );
  if result_record.status <> 'Published' then raise exception 'result publishing failed'; end if;

  denied := false;
  begin
    perform public.archive_trusted_erp_record(
      'trusted-rpc-tenant', 'exam_results', result_record.id, result_record.updated_at
    );
  exception when insufficient_privilege then denied := true;
  end;
  if not denied then raise exception 'published result could be archived'; end if;
end;
$$;

rollback;
select 'Trusted finance/results integration tests passed' as result;
