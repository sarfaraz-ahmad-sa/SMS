begin;

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000000',
  '40000000-0000-0000-0000-000000000004',
  'authenticated', 'authenticated', 'erp-rpc@example.invalid', '', now(),
  '{}'::jsonb, '{}'::jsonb, now(), now()
);

insert into public.tenants (id, name)
values ('erp-rpc-tenant', 'ERP RPC Test School');
insert into public.tenant_members (
  tenant_id, user_id, email, roles, permissions, campus_ids
) values (
  'erp-rpc-tenant', '40000000-0000-0000-0000-000000000004',
  'erp-rpc@example.invalid', array['schoolOwner'], array['*'],
  array['erp-rpc-campus']
);
insert into public.campuses (tenant_id, id, code, name) values
  ('erp-rpc-tenant', 'erp-rpc-campus', 'ERP', 'Allowed Campus'),
  ('erp-rpc-tenant', 'erp-rpc-blocked', 'BLOCK', 'Blocked Campus');
insert into public.academic_years (
  tenant_id, id, name, starts_on, ends_on, status
) values (
  'erp-rpc-tenant', 'erp-rpc-year', '2026-2027',
  '2026-04-01', '2027-03-31', 'active'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '40000000-0000-0000-0000-000000000004',
  true
);

do $$
declare
  v_created public.erp_records;
  v_updated public.erp_records;
  v_archived public.erp_records;
  v_denied boolean;
begin
  v_denied := false;
  begin
    insert into public.erp_records (
      tenant_id, collection, campus_id, academic_year_id, data
    ) values (
      'erp-rpc-tenant', 'daily_diary', 'erp-rpc-campus', 'erp-rpc-year',
      '{"title":"Direct"}'::jsonb
    );
  exception when insufficient_privilege then
    v_denied := true;
  end;
  if not v_denied then
    raise exception 'direct ERP insert was not denied';
  end if;

  v_created := public.create_erp_record(
    'erp-rpc-tenant', 'daily_diary', 'erp-rpc-campus', 'erp-rpc-year',
    '{"title":"Diary One","status":"Draft"}'::jsonb, 'erp-test-1'
  );
  if v_created.data->>'title' <> 'Diary One' then
    raise exception 'generic ERP create failed';
  end if;

  v_updated := public.update_erp_record(
    'erp-rpc-tenant', 'daily_diary', v_created.id, v_created.updated_at,
    '{"title":"Diary Updated","status":"Published"}'::jsonb
  );
  if v_updated.data->>'title' <> 'Diary Updated'
     or v_updated.updated_at <= v_created.updated_at then
    raise exception 'generic ERP update/version failed';
  end if;

  v_archived := public.archive_erp_record(
    'erp-rpc-tenant', 'daily_diary', v_updated.id, v_updated.updated_at
  );
  if not v_archived.is_archived then
    raise exception 'generic ERP archive failed';
  end if;

  v_denied := false;
  begin
    perform public.create_erp_record(
      'erp-rpc-tenant', 'daily_diary', 'erp-rpc-blocked', 'erp-rpc-year',
      '{"title":"Blocked"}'::jsonb, 'erp-test-blocked'
    );
  exception when insufficient_privilege then
    v_denied := true;
  end;
  if not v_denied then
    raise exception 'cross-campus ERP write was not denied';
  end if;

  v_denied := false;
  begin
    perform public.create_erp_record(
      'erp-rpc-tenant', 'payments', 'erp-rpc-campus', 'erp-rpc-year',
      '{"amount":100}'::jsonb, 'erp-test-payment'
    );
  exception when feature_not_supported then
    v_denied := true;
  end;
  if not v_denied then
    raise exception 'high-risk generic ERP write was not denied';
  end if;
end;
$$;

reset role;

do $$
begin
  if (
    select count(*) from public.audit_logs
    where tenant_id = 'erp-rpc-tenant' and table_name = 'erp_records'
      and actor_user_id = '40000000-0000-0000-0000-000000000004'
  ) <> 3 then
    raise exception 'generic ERP audit test failed';
  end if;
end;
$$;

rollback;
select 'Generic ERP integration tests passed' as result;
