begin;

-- ERP record RLS needs the collection-to-permission mapping, but browser roles
-- must not receive direct access to the internal permission registry.
create or replace function private.has_erp_collection_view_permission(
  p_tenant_id text,
  p_collection text
)
returns boolean
security definer
language sql
stable
set search_path = ''
as $$
  select exists (
    select 1
    from public.erp_collection_permissions permission
    where permission.collection = nullif(trim(p_collection), '')
      and private.has_permission(
        p_tenant_id,
        permission.view_permission
      )
  );
$$;

revoke all on function private.has_erp_collection_view_permission(text,text)
  from public, anon;
grant execute on function private.has_erp_collection_view_permission(text,text)
  to authenticated;

drop policy if exists erp_records_read_scoped on public.erp_records;
create policy erp_records_read_scoped on public.erp_records
for select to authenticated
using (
  private.can_access_campus(tenant_id, campus_id)
  and private.can_read_erp_record(tenant_id, collection, data, created_by)
  and private.has_erp_collection_view_permission(tenant_id, collection)
);

-- Keep the registry private. The helper above is the only browser-facing path.
revoke all on public.erp_collection_permissions from anon, authenticated;

commit;
