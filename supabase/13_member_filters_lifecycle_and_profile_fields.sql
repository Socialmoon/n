-- Adds richer member profile fields and lifecycle/status tracking for filtering and admin controls.

alter table public.members
  add column if not exists home_state text;

alter table public.members
  add column if not exists posting_state text;

alter table public.members
  add column if not exists gender text;

alter table public.members
  add column if not exists marital_status text;

alter table public.members
  add column if not exists posting_category text;

alter table public.members
  add column if not exists posting_work_as text;

alter table public.members
  add column if not exists last_login_at timestamptz;

alter table public.members
  add column if not exists is_retired boolean not null default false;

alter table public.members
  add column if not exists retired_at timestamptz;

alter table public.members
  add column if not exists is_deleted boolean not null default false;

alter table public.members
  add column if not exists deleted_at timestamptz;

alter table public.members
  add column if not exists pending_update_payload text;

alter table public.members
  add column if not exists previous_public_profile_snapshot text;

create index if not exists idx_members_posting_district on public.members(posting_district);
create index if not exists idx_members_posting_location on public.members(posting_location);
create index if not exists idx_members_is_deleted on public.members(is_deleted);
create index if not exists idx_members_last_login_at on public.members(last_login_at desc);
