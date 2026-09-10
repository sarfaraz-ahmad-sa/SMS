begin;

-- Suspension must revoke linked portal access as well as staff permissions.
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
  select private.is_active_member(target_tenant_id) and (
    (
      private.has_staff_permission(target_tenant_id, 'students.view')
      and private.can_access_student_campus(target_tenant_id, target_student_id)
    )
    or exists (
      select 1 from public.students s
      where s.tenant_id = target_tenant_id and s.id = target_student_id
        and s.auth_user_id = (select auth.uid())
    )
    or exists (
      select 1 from public.student_guardians link
      join public.guardians guardian
        on guardian.tenant_id = link.tenant_id
       and guardian.id = link.guardian_id
      where link.tenant_id = target_tenant_id
        and link.student_id = target_student_id
        and guardian.auth_user_id = (select auth.uid())
    ));
$$;

grant execute on function private.can_access_student(text,text)
  to authenticated;

drop policy if exists guardians_read_scoped on public.guardians;
create policy guardians_read_scoped on public.guardians
for select to authenticated
using (
  private.is_active_member(tenant_id) and (
    private.has_staff_permission(tenant_id, 'parents.view')
    or auth_user_id = (select auth.uid())
  )
);


commit;
