-- Group planning RLS: drop all policies and recreate without recursion.
-- Some earlier migrations may have left additional policies behind; those can still
-- trigger Postgrest recursion errors even if a "fixed" policy exists.

begin;

-- Drop ALL policies on the group planning tables (public schema).
do $$
declare
  r record;
begin
  for r in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename in ('group_sessions', 'group_session_members', 'group_plans')
  loop
    execute format(
      'drop policy if exists %I on %I.%I;',
      r.policyname,
      r.schemaname,
      r.tablename
    );
  end loop;
end $$;

-- Ensure RLS is enabled (dropping policies doesn't change this).
alter table if exists public.group_sessions enable row level security;
alter table if exists public.group_session_members enable row level security;
alter table if exists public.group_plans enable row level security;

-- Helper used by policies to avoid recursion through RLS.
create or replace function public.is_group_session_member(p_session_id uuid)
returns boolean
language sql
security definer
set search_path = public
set row_security = off
as $$
  select exists (
    select 1
    from public.group_session_members m
    where m.session_id = p_session_id
      and m.user_id = auth.uid()
  );
$$;

revoke all on function public.is_group_session_member(uuid) from public;
grant execute on function public.is_group_session_member(uuid) to authenticated;

-- group_sessions
create policy group_sessions_select_member
on public.group_sessions
for select
to authenticated
using (
  public.is_group_session_member(id)
);

create policy group_sessions_insert_creator
on public.group_sessions
for insert
to authenticated
with check (
  created_by = auth.uid()
);

create policy group_sessions_update_member
on public.group_sessions
for update
to authenticated
using (
  public.is_group_session_member(id)
)
with check (
  public.is_group_session_member(id)
);

create policy group_sessions_delete_creator
on public.group_sessions
for delete
to authenticated
using (
  created_by = auth.uid()
);

-- group_session_members
create policy group_session_members_select_member
on public.group_session_members
for select
to authenticated
using (
  public.is_group_session_member(session_id)
);

create policy group_session_members_insert_self
on public.group_session_members
for insert
to authenticated
with check (
  user_id = auth.uid()
);

create policy group_session_members_update_self
on public.group_session_members
for update
to authenticated
using (
  user_id = auth.uid()
)
with check (
  user_id = auth.uid()
);

create policy group_session_members_delete_own
on public.group_session_members
for delete
to authenticated
using (
  user_id = auth.uid()
);

-- group_plans
create policy group_plans_select_member
on public.group_plans
for select
to authenticated
using (
  public.is_group_session_member(session_id)
);

create policy group_plans_insert_member
on public.group_plans
for insert
to authenticated
with check (
  public.is_group_session_member(session_id)
);

create policy group_plans_update_member
on public.group_plans
for update
to authenticated
using (
  public.is_group_session_member(session_id)
)
with check (
  public.is_group_session_member(session_id)
);

create policy group_plans_delete_member
on public.group_plans
for delete
to authenticated
using (
  public.is_group_session_member(session_id)
);

commit;

