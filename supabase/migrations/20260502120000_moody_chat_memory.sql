-- Long-term chat "memory" for Moody (relational tone, nicknames, emoji habits).
-- Merged server-side from conversation excerpts; user can view/clear in app.

alter table public.user_preference_patterns
  add column if not exists moody_chat_memory jsonb not null default '{}'::jsonb;

comment on column public.user_preference_patterns.moody_chat_memory is
  'Moody v1: compact JSON (nickname, tone_notes, emoji_hints, sticky_facts) injected into chat system prompt.';
