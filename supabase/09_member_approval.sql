-- Adds approval flag for member onboarding workflow.
-- Existing members remain approved to avoid locking current users.

alter table public.members
  add column if not exists is_approved boolean not null default true;
