begin;

revoke update on public.access_requests from authenticated;

create or replace function public.review_access_request(
  p_tenant_id text,
  p_request_id uuid,
  p_decision text,
  p_note text default ''
)
returns public.access_requests
security definer
language plpgsql
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_decision text := lower(trim(p_decision));
  v_record public.access_requests;
begin
  if v_uid is null or not private.has_permission(p_tenant_id, 'users.manage') then
    raise exception 'permission denied' using errcode = '42501';
  end if;
  if v_decision not in ('approved','rejected','cancelled') then
    raise exception 'invalid review decision' using errcode = '22023';
  end if;
  update public.access_requests
  set status = v_decision,
      reviewed_by = v_uid,
      reviewed_at = now(),
      review_note = nullif(trim(p_note), '')
  where tenant_id = p_tenant_id and id = p_request_id and status = 'pending'
  returning * into v_record;
  if not found then
    raise exception 'pending access request not found' using errcode = 'P0002';
  end if;
  return v_record;
end;
$$;

revoke all on function public.review_access_request(text,uuid,text,text)
  from public, anon;
grant execute on function public.review_access_request(text,uuid,text,text)
  to authenticated;

commit;
