-- Group activity notes: one short note per user per shared activity slot.
-- note_key = place_id (with google_ prefix) when available, else a truncated
-- activity title slug — so both users reading the same slot see the same notes.
create table if not exists public.group_activity_notes (
  id           uuid primary key default gen_random_uuid(),
  session_id   uuid not null references public.group_sessions(id) on delete cascade,
  note_key     text not null,               -- place_id or slug
  user_id      uuid not null references auth.users(id) on delete cascade,
  note_text    text not null default '',
  updated_at   timestamptz not null default now(),
  constraint group_activity_notes_unique unique (session_id, note_key, user_id)
);

alter table public.group_activity_notes enable row level security;

-- Members of the session can read all notes for that session.
create policy "session members can read notes"
  on public.group_activity_notes for select
  using (
    exists (
      select 1 from public.group_session_members m
      where m.session_id = group_activity_notes.session_id
        and m.user_id    = auth.uid()
    )
  );

-- Users can insert / update their own note.
create policy "own notes insert"
  on public.group_activity_notes for insert
  with check (user_id = auth.uid());

create policy "own notes update"
  on public.group_activity_notes for update
  using  (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "own notes delete"
  on public.group_activity_notes for delete
  using (user_id = auth.uid());

create index if not exists group_activity_notes_session_key_idx
  on public.group_activity_notes (session_id, note_key);
