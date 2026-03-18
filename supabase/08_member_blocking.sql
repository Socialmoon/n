-- Migration: add member block state for admin moderation.

alter table public.members
  add column if not exists is_blocked boolean not null default false;

-- Optional verification query:
-- select id, name, is_admin, is_blocked from public.members order by name;
