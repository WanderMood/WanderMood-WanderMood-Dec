-- Mood Match: allow the session creator to read/update their own row, not only
-- via is_group_session_member(id). Migration 20260415130000 included
-- `created_by = auth.uid()` for SELECT; 20260415140000 dropped it, which can
-- block the host right after create if membership visibility is delayed or
-- inconsistent in any environment.

begin;

drop policy if exists group_sessions_select_member on public.group_sessions;

create policy group_sessions_select_member
on public.group_sessions
for select
to authenticated
using (
  created_by = auth.uid()
  or public.is_group_session_member(id)
);

drop policy if exists group_sessions_update_member on public.group_sessions;

create policy group_sessions_update_member
on public.group_sessions
for update
to authenticated
using (
  created_by = auth.uid()
  or public.is_group_session_member(id)
)
with check (
  created_by = auth.uid()
  or public.is_group_session_member(id)
);

commit;
