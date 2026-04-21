-- Client helper: return one group_sessions row as JSON when the caller is the
-- creator or a member. Uses SECURITY DEFINER so it still works if table SELECT
-- RLS on group_sessions is misconfigured on a given environment.

begin;

create or replace function public.fetch_group_session_for_client(p_session_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  v_uid uuid := auth.uid();
  rec jsonb;
begin
  if v_uid is null then
    return null;
  end if;

  select to_jsonb(s.*) into rec
  from public.group_sessions s
  where s.id = p_session_id
    and (
      s.created_by = v_uid
      or exists (
        select 1
        from public.group_session_members m
        where m.session_id = s.id
          and m.user_id = v_uid
      )
    )
  limit 1;

  return rec;
end;
$$;

revoke all on function public.fetch_group_session_for_client(uuid) from public;
grant execute on function public.fetch_group_session_for_client(uuid) to authenticated;

commit;
