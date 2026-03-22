-- Donations migration for existing projects.
-- Run this for databases created before donations feature was added.

create table if not exists public.donations (
  id text primary key,
  owner_id uuid default auth.uid(),
  member_id text not null,
  member_name text not null,
  member_mobile text not null,
  amount numeric not null,
  upi_id text not null,
  status text not null default 'Pending Verification',
  transaction_ref text,
  note text,
  screenshot_path text,
  created_at timestamptz not null default now()
);

alter table public.donations
  add column if not exists reviewed_at timestamptz;

alter table public.donations
  add column if not exists reviewed_by text;

alter table public.donations
  add column if not exists rejection_reason text;

create index if not exists idx_donations_created_at on public.donations(created_at desc);

alter table public.donations enable row level security;

drop policy if exists donations_select_policy on public.donations;
create policy donations_select_policy
on public.donations
for select
to anon, authenticated
using (true);

drop policy if exists donations_insert_policy on public.donations;
create policy donations_insert_policy
on public.donations
for insert
to anon, authenticated
with check (true);

drop policy if exists donations_update_policy on public.donations;
create policy donations_update_policy
on public.donations
for update
to authenticated
using (public.is_app_admin() or owner_id = auth.uid())
with check (public.is_app_admin() or owner_id = auth.uid());

drop policy if exists donations_delete_policy on public.donations;
create policy donations_delete_policy
on public.donations
for delete
to authenticated
using (public.is_app_admin() or owner_id = auth.uid());
