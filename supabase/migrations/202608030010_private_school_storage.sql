begin;

insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values
  (
    'school-documents',
    'school-documents',
    false,
    10485760,
    array[
      'application/pdf',
      'image/jpeg',
      'image/png',
      'image/webp',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ]::text[]
  ),
  (
    'school-exports',
    'school-exports',
    false,
    26214400,
    array[
      'application/pdf',
      'text/csv',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    ]::text[]
  ),
  (
    'school-backups',
    'school-backups',
    false,
    1073741824,
    array[
      'application/octet-stream',
      'application/gzip',
      'application/x-tar'
    ]::text[]
  )
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create or replace function private.can_access_storage_object(
  p_object_name text,
  p_permission text
)
returns boolean
language plpgsql
security definer
stable
set search_path = ''
as $$
declare
  folders text[] := storage.foldername(p_object_name);
  tenant_id text;
  campus_id text;
  academic_year_id text;
begin
  if cardinality(folders) < 3 then return false; end if;
  tenant_id := folders[1];
  campus_id := folders[2];
  academic_year_id := folders[3];

  return private.can_access_campus(tenant_id, campus_id)
    and private.has_permission(tenant_id, p_permission)
    and exists (
      select 1
      from public.academic_years academic_year
      where academic_year.tenant_id = tenant_id
        and academic_year.id = academic_year_id
        and not academic_year.is_archived
    );
end;
$$;

revoke all on function private.can_access_storage_object(text, text)
  from public;

drop policy if exists school_documents_read_scoped on storage.objects;
create policy school_documents_read_scoped on storage.objects
for select to authenticated
using (
  bucket_id = 'school-documents'
  and private.can_access_storage_object(name, 'documents.view')
);

drop policy if exists school_documents_insert_scoped on storage.objects;
create policy school_documents_insert_scoped on storage.objects
for insert to authenticated
with check (
  bucket_id = 'school-documents'
  and private.can_access_storage_object(name, 'documents.manage')
);

drop policy if exists school_documents_update_scoped on storage.objects;
create policy school_documents_update_scoped on storage.objects
for update to authenticated
using (
  bucket_id = 'school-documents'
  and private.can_access_storage_object(name, 'documents.manage')
)
with check (
  bucket_id = 'school-documents'
  and private.can_access_storage_object(name, 'documents.manage')
);

drop policy if exists school_documents_delete_scoped on storage.objects;
create policy school_documents_delete_scoped on storage.objects
for delete to authenticated
using (
  bucket_id = 'school-documents'
  and private.can_access_storage_object(name, 'documents.manage')
);

drop policy if exists school_exports_read_scoped on storage.objects;
create policy school_exports_read_scoped on storage.objects
for select to authenticated
using (
  bucket_id = 'school-exports'
  and private.can_access_storage_object(name, 'reports.view')
);

-- school-exports is backend-write-only and school-backups is service-role-only.
-- No authenticated INSERT/UPDATE/DELETE policies are intentionally created.

commit;
