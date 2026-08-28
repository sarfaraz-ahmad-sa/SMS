begin;

create extension if not exists pg_trgm;

alter table public.erp_records
  add column if not exists search_text text
  generated always as (lower(data::text)) stored;

create index if not exists erp_records_search_trgm_idx
  on public.erp_records using gin (search_text gin_trgm_ops)
  where not is_archived;

alter table public.students
  add column if not exists search_text text
  generated always as (lower(full_name || ' ' || admission_no)) stored;

create index if not exists students_search_trgm_idx
  on public.students using gin (search_text gin_trgm_ops)
  where not is_archived;

commit;
