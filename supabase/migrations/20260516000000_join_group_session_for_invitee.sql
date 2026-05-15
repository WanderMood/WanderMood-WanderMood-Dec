-- Plan met vriend: invitees must join group_session_members without client INSERT
-- (many environments have no INSERT policy on group_session_members → 42501).

begin;

-- True when auth.uid() is the invitee for this session (table or plan_data mirror).
create or replace function public.is_invitee_for_group_session(p_session_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null or p_session_id is null then
    return false;
  end if;

  if to_regclass('public.wishlist_place_invites') is not null then
    if exists (
      select 1
      from public.wishlist_place_invites i
      where i.group_session_id = p_session_id
        and i.invitee_user_id = v_uid
        and coalesce(i.status, 'pending') in ('pending', 'accepted')
    ) then
      return true;
    end if;
  end if;

  return exists (
    select 1
    from public.group_plans gp
    where gp.session_id = p_session_id
      and gp.plan_data is not null
      and gp.plan_data->'planMetVriendInvite'->>'invitee_user_id' = v_uid::text
  );
end;
$$;

revoke all on function public.is_invitee_for_group_session(uuid) from public;
grant execute on function public.is_invitee_for_group_session(uuid) to authenticated;

-- SECURITY DEFINER join (same pattern as join_group_session by code).
create or replace function public.join_group_session_for_invitee(
  p_session_id uuid,
  p_invite_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  v_uid uuid := auth.uid();
  v_allowed boolean := false;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  if p_session_id is null then
    raise exception 'session_id required';
  end if;

  if exists (
    select 1
    from public.group_session_members m
    where m.session_id = p_session_id
      and m.user_id = v_uid
  ) then
    return p_session_id;
  end if;

  if exists (
    select 1
    from public.group_sessions s
    where s.id = p_session_id
      and s.created_by = v_uid
  ) then
    v_allowed := true;
  elsif public.is_invitee_for_group_session(p_session_id) then
    if p_invite_id is not null
       and to_regclass('public.wishlist_place_invites') is not null then
      select exists (
        select 1
        from public.wishlist_place_invites i
        where i.id = p_invite_id
          and i.group_session_id = p_session_id
          and i.invitee_user_id = v_uid
      )
      into v_allowed;
      if not v_allowed then
        v_allowed := public.is_invitee_for_group_session(p_session_id);
      end if;
    else
      v_allowed := true;
    end if;
  end if;

  if not coalesce(v_allowed, false) then
    raise exception 'Not authorized to join this session';
  end if;

  insert into public.group_session_members (session_id, user_id)
  values (p_session_id, v_uid)
  on conflict (session_id, user_id) do nothing;

  return p_session_id;
end;
$$;

revoke all on function public.join_group_session_for_invitee(uuid, uuid) from public;
grant execute on function public.join_group_session_for_invitee(uuid, uuid) to authenticated;

-- Belt-and-suspenders: ensure invitees can self-insert when RPC is not used yet.
drop policy if exists group_session_members_insert_self on public.group_session_members;

create policy group_session_members_insert_self
on public.group_session_members
for insert
to authenticated
with check (user_id = auth.uid());

-- Allow invitee to read session before membership row exists (day picker load).
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
      or public.is_invitee_for_group_session(p_session_id)
    )
  limit 1;

  return rec;
end;
$$;

revoke all on function public.fetch_group_session_for_client(uuid) from public;
grant execute on function public.fetch_group_session_for_client(uuid) to authenticated;

commit;
