begin;

create or replace function private.trusted_record_key(
  p_collection text,
  p_data jsonb
)
returns text
language sql
immutable
set search_path = ''
as $$
  select nullif(trim(case p_collection
    when 'fee_refunds' then p_data ->> 'refundNo'
    when 'payroll_runs' then p_data ->> 'period'
    when 'payslips' then p_data ->> 'payslipNo'
    when 'chart_of_accounts' then p_data ->> 'accountCode'
    when 'journal_entries' then p_data ->> 'voucherNo'
    when 'bank_accounts' then p_data ->> 'accountNumber'
    when 'expenses' then p_data ->> 'expenseNo'
    when 'budgets' then concat_ws(':', p_data ->> 'name', p_data ->> 'period')
    when 'exam_results' then concat_ws(':', p_data ->> 'examName', p_data ->> 'studentId')
    else null
  end), '');
$$;

create or replace function private.normalize_trusted_record(
  p_collection text,
  p_data jsonb,
  p_existing_status text default null
)
returns jsonb
security definer
language plpgsql
stable
set search_path = ''
as $$
declare
  normalized jsonb := coalesce(p_data, '{}'::jsonb);
  amount numeric;
  gross numeric;
  deductions numeric;
  obtained numeric;
  total numeric;
  debit numeric;
  credit numeric;
  initial_status text;
begin
  if p_collection not in (
    'fee_refunds', 'payroll_runs', 'payslips', 'chart_of_accounts',
    'journal_entries', 'bank_accounts', 'expenses', 'budgets', 'exam_results'
  ) then
    raise exception 'unsupported trusted collection' using errcode = '22023';
  end if;
  if jsonb_typeof(normalized) <> 'object' or octet_length(normalized::text) > 65536 then
    raise exception 'invalid trusted record payload' using errcode = '22023';
  end if;

  initial_status := case p_collection
    when 'fee_refunds' then 'Requested'
    when 'exam_results' then 'Calculated'
    when 'chart_of_accounts' then 'Active'
    when 'bank_accounts' then 'Active'
    else 'Draft'
  end;
  normalized := normalized || jsonb_build_object(
    'status', coalesce(p_existing_status, initial_status)
  );

  if p_collection = 'fee_refunds' then
    amount := nullif(normalized ->> 'amount', '')::numeric;
    if amount is null or amount <= 0 or nullif(trim(normalized ->> 'reason'), '') is null then
      raise exception 'refund amount and reason are required' using errcode = '22023';
    end if;
    if not exists (
      select 1 from public.payments payment
      where payment.tenant_id = normalized ->> '_tenantId'
        and payment.receipt_no = normalized ->> 'receiptNo'
        and payment.status = 'posted'
        and amount <= payment.amount
    ) then
      raise exception 'original posted receipt was not found or refund exceeds payment' using errcode = '22023';
    end if;
  elsif p_collection = 'payroll_runs' then
    gross := coalesce(nullif(normalized ->> 'grossAmount', '')::numeric, 0);
    deductions := coalesce(nullif(normalized ->> 'deductions', '')::numeric, 0);
    if gross < 0 or deductions < 0 or deductions > gross then
      raise exception 'invalid payroll totals' using errcode = '22023';
    end if;
    normalized := normalized || jsonb_build_object('netAmount', gross - deductions);
  elsif p_collection = 'journal_entries' then
    debit := coalesce(nullif(normalized ->> 'debitAmount', '')::numeric, 0);
    credit := coalesce(nullif(normalized ->> 'creditAmount', '')::numeric, 0);
    if debit <= 0 or debit <> credit then
      raise exception 'journal entry must have equal positive debit and credit totals' using errcode = '22023';
    end if;
  elsif p_collection = 'exam_results' then
    obtained := coalesce(nullif(normalized ->> 'obtainedMarks', '')::numeric, 0);
    total := coalesce(nullif(normalized ->> 'totalMarks', '')::numeric, 0);
    if total <= 0 or obtained < 0 or obtained > total then
      raise exception 'invalid result marks' using errcode = '22023';
    end if;
    normalized := normalized || jsonb_build_object(
      'percentage', round((obtained * 100.0 / total)::numeric, 2)
    );
  end if;
  return normalized - '_tenantId';
exception when invalid_text_representation then
  raise exception 'numeric fields contain an invalid value' using errcode = '22023';
end;
$$;

create or replace function public.create_trusted_erp_record(
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
  normalized jsonb;
  permission_name text;
  unique_key text;
  existing public.erp_records;
  created public.erp_records;
begin
  select manage_permission into permission_name
  from public.erp_collection_permissions where collection = p_collection and high_risk;
  if permission_name is null or not private.has_permission(p_tenant_id, permission_name) then
    raise exception 'permission denied' using errcode = '42501';
  end if;
  if not private.can_access_campus(p_tenant_id, p_campus_id) then
    raise exception 'campus access denied' using errcode = '42501';
  end if;
  if nullif(trim(p_idempotency_key), '') is null then
    raise exception 'idempotency key is required' using errcode = '22023';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_tenant_id || ':' || p_collection || ':' || trim(p_idempotency_key), 0)
  );
  select * into existing from public.erp_records
  where tenant_id = p_tenant_id and collection = p_collection
    and idempotency_key = trim(p_idempotency_key);
  if found then return existing; end if;

  normalized := private.normalize_trusted_record(
    p_collection, coalesce(p_values, '{}'::jsonb) || jsonb_build_object('_tenantId', p_tenant_id)
  );
  unique_key := private.trusted_record_key(p_collection, normalized);
  if unique_key is null then
    raise exception 'unique business identifier is required' using errcode = '22023';
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_tenant_id || ':' || p_collection || ':' || lower(unique_key), 0)
  );
  if exists (
    select 1 from public.erp_records record
    where record.tenant_id = p_tenant_id and record.collection = p_collection
      and not record.is_archived
      and lower(private.trusted_record_key(p_collection, record.data)) = lower(unique_key)
  ) then
    raise exception 'business identifier already exists' using errcode = '23505';
  end if;

  insert into public.erp_records (
    tenant_id, collection, campus_id, academic_year_id, status, data,
    idempotency_key, created_by, updated_by
  ) values (
    p_tenant_id, p_collection, p_campus_id, p_academic_year_id,
    normalized ->> 'status', normalized, trim(p_idempotency_key),
    (select auth.uid()), (select auth.uid())
  ) returning * into created;
  return created;
end;
$$;

create or replace function public.update_trusted_erp_record(
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
  current_record public.erp_records;
  normalized jsonb;
  permission_name text;
  unique_key text;
begin
  select manage_permission into permission_name
  from public.erp_collection_permissions where collection = p_collection and high_risk;
  if permission_name is null or not private.has_permission(p_tenant_id, permission_name) then
    raise exception 'permission denied' using errcode = '42501';
  end if;
  select * into current_record from public.erp_records
  where tenant_id = p_tenant_id and collection = p_collection and id = p_record_id
    and not is_archived for update;
  if not found then raise exception 'record not found' using errcode = 'P0002'; end if;
  if current_record.updated_at <> p_expected_updated_at then
    raise exception 'record was changed by another user' using errcode = '40001';
  end if;
  if current_record.status in ('Approved', 'Posted', 'Paid', 'Published', 'Reversed') then
    raise exception 'approved or posted records are immutable' using errcode = '42501';
  end if;
  if coalesce(p_values ->> 'status', current_record.status) <> current_record.status then
    raise exception 'use the approval workflow to change status' using errcode = '42501';
  end if;
  normalized := private.normalize_trusted_record(
    p_collection,
    (current_record.data || coalesce(p_values, '{}'::jsonb)) || jsonb_build_object('_tenantId', p_tenant_id),
    current_record.status
  );
  unique_key := private.trusted_record_key(p_collection, normalized);
  if exists (
    select 1 from public.erp_records record
    where record.tenant_id = p_tenant_id and record.collection = p_collection
      and record.id <> p_record_id and not record.is_archived
      and lower(private.trusted_record_key(p_collection, record.data)) = lower(unique_key)
  ) then raise exception 'business identifier already exists' using errcode = '23505'; end if;
  update public.erp_records set data = normalized, updated_by = (select auth.uid())
  where tenant_id = p_tenant_id and collection = p_collection and id = p_record_id
  returning * into current_record;
  return current_record;
end;
$$;

create or replace function public.archive_trusted_erp_record(
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
  current_record public.erp_records;
  permission_name text;
begin
  select manage_permission into permission_name
  from public.erp_collection_permissions where collection = p_collection and high_risk;
  if permission_name is null or not private.has_permission(p_tenant_id, permission_name) then
    raise exception 'permission denied' using errcode = '42501';
  end if;
  select * into current_record from public.erp_records
  where tenant_id = p_tenant_id and collection = p_collection and id = p_record_id
    and not is_archived for update;
  if not found then raise exception 'record not found' using errcode = 'P0002'; end if;
  if current_record.updated_at <> p_expected_updated_at then
    raise exception 'record was changed by another user' using errcode = '40001';
  end if;
  if current_record.status in ('Approved', 'Posted', 'Paid', 'Published', 'Reversed') then
    raise exception 'approved or posted records cannot be archived' using errcode = '42501';
  end if;
  update public.erp_records set is_archived = true, updated_by = (select auth.uid())
  where tenant_id = p_tenant_id and collection = p_collection and id = p_record_id
  returning * into current_record;
  return current_record;
end;
$$;

create or replace function public.transition_trusted_erp_record(
  p_tenant_id text,
  p_collection text,
  p_record_id text,
  p_expected_status text,
  p_new_status text
)
returns public.erp_records
security definer
language plpgsql
set search_path = ''
as $$
declare
  current_record public.erp_records;
  required_permission text;
begin
  required_permission := case
    when p_collection = 'fee_refunds' and p_new_status = 'Approved' then 'fees.refund.approve'
    when p_collection = 'payroll_runs' and p_new_status = 'Approved' then 'payroll.approve'
    when p_collection = 'exam_results' and p_new_status = 'Published' then 'exams.results.publish'
    when p_collection in ('journal_entries', 'expenses', 'budgets') then 'accounting.manage'
    else (select manage_permission from public.erp_collection_permissions where collection = p_collection)
  end;
  if required_permission is null or not private.has_permission(p_tenant_id, required_permission) then
    raise exception 'approval permission denied' using errcode = '42501';
  end if;
  select * into current_record from public.erp_records
  where tenant_id = p_tenant_id and collection = p_collection and id = p_record_id
    and not is_archived for update;
  if not found then raise exception 'record not found' using errcode = 'P0002'; end if;
  if current_record.status <> p_expected_status then
    raise exception 'record status changed; reload and retry' using errcode = '40001';
  end if;
  if not (
    (p_collection = 'fee_refunds' and
      (p_expected_status, p_new_status) in (('Requested','Under Review'),('Requested','Rejected'),('Under Review','Approved'),('Under Review','Rejected'),('Approved','Paid'))) or
    (p_collection = 'payroll_runs' and
      (p_expected_status, p_new_status) in (('Draft','Submitted'),('Submitted','Approved'),('Submitted','Rejected'),('Approved','Paid'))) or
    (p_collection = 'journal_entries' and
      (p_expected_status, p_new_status) in (('Draft','Submitted'),('Submitted','Approved'),('Submitted','Rejected'),('Approved','Posted'))) or
    (p_collection = 'exam_results' and
      (p_expected_status, p_new_status) in (('Calculated','Under Review'),('Under Review','Approved'),('Under Review','Rejected'),('Approved','Published'))) or
    (p_collection in ('expenses','budgets','payslips') and
      (p_expected_status, p_new_status) in (('Draft','Submitted'),('Submitted','Approved'),('Submitted','Rejected'),('Approved','Paid')))
  ) then
    raise exception 'invalid approval transition' using errcode = '22023';
  end if;
  update public.erp_records set
    status = p_new_status,
    data = data || jsonb_build_object(
      'status', p_new_status,
      'statusChangedBy', (select auth.uid())::text,
      'statusChangedAt', now()
    ),
    updated_by = (select auth.uid())
  where tenant_id = p_tenant_id and collection = p_collection and id = p_record_id
  returning * into current_record;
  return current_record;
end;
$$;

create or replace function public.record_fee_payment_by_number(
  p_tenant_id text,
  p_invoice_no text,
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
  invoice_id text;
begin
  select id into invoice_id from public.fee_invoices
  where tenant_id = p_tenant_id and lower(invoice_no) = lower(trim(p_invoice_no))
    and not is_archived;
  if not found then raise exception 'invoice was not found' using errcode = 'P0002'; end if;
  return public.record_fee_payment(
    p_tenant_id, invoice_id, p_amount,
    case lower(trim(p_method))
      when 'cash' then 'cash' when 'bank transfer' then 'bank'
      when 'card' then 'card' when 'jazzcash' then 'jazzcash'
      when 'easypaisa' then 'easypaisa' else 'other' end,
    p_reference, p_idempotency_key
  );
end;
$$;

revoke all on function private.trusted_record_key(text,jsonb) from public;
revoke all on function private.normalize_trusted_record(text,jsonb,text) from public;
revoke all on function public.create_trusted_erp_record(text,text,text,text,jsonb,text) from public;
revoke all on function public.update_trusted_erp_record(text,text,text,timestamptz,jsonb) from public;
revoke all on function public.archive_trusted_erp_record(text,text,text,timestamptz) from public;
revoke all on function public.transition_trusted_erp_record(text,text,text,text,text) from public;
revoke all on function public.record_fee_payment_by_number(text,text,numeric,text,text,text) from public;
grant execute on function public.create_trusted_erp_record(text,text,text,text,jsonb,text) to authenticated;
grant execute on function public.update_trusted_erp_record(text,text,text,timestamptz,jsonb) to authenticated;
grant execute on function public.archive_trusted_erp_record(text,text,text,timestamptz) to authenticated;
grant execute on function public.transition_trusted_erp_record(text,text,text,text,text) to authenticated;
grant execute on function public.record_fee_payment_by_number(text,text,numeric,text,text,text) to authenticated;

commit;
