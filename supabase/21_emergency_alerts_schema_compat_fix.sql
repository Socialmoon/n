-- Emergency alerts schema compatibility fix for app runtime.
-- Run in Supabase SQL Editor after manual schema changes.

alter table if exists public.emergency_alerts
  add column if not exists id text,
  add column if not exists owner_id uuid default auth.uid(),
  add column if not exists member_id text,
  add column if not exists member_name text,
  add column if not exists message text,
  add column if not exists location text,
  add column if not exists timestamp timestamptz,
  add column if not exists created_at timestamptz default now();

update public.emergency_alerts
set id = coalesce(id, gen_random_uuid()::text)
where id is null;

alter table public.emergency_alerts
  alter column id set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'emergency_alerts_pkey'
      and conrelid = 'public.emergency_alerts'::regclass
  ) then
    alter table public.emergency_alerts
      add constraint emergency_alerts_pkey primary key (id);
  end if;
end $$;

update public.emergency_alerts
set timestamp = coalesce(timestamp, created_at, now())
where timestamp is null;

update public.emergency_alerts
set created_at = coalesce(created_at, timestamp, now())
where created_at is null;

alter table public.emergency_alerts
  alter column owner_id set default auth.uid();

create index if not exists idx_alerts_timestamp on public.emergency_alerts(timestamp desc);
create index if not exists idx_alerts_created_at on public.emergency_alerts(created_at desc);
create index if not exists idx_alerts_owner_id on public.emergency_alerts(owner_id);

alter table public.emergency_alerts enable row level security;

drop policy if exists alerts_select_policy on public.emergency_alerts;
create policy alerts_select_policy
on public.emergency_alerts
for select
to anon, authenticated
using (true);

drop policy if exists alerts_insert_policy on public.emergency_alerts;
create policy alerts_insert_policy
on public.emergency_alerts
for insert
to anon, authenticated
with check (true);

drop policy if exists alerts_update_policy on public.emergency_alerts;
create policy alerts_update_policy
on public.emergency_alerts
for update
to anon, authenticated
using (true)
with check (true);

drop policy if exists alerts_delete_policy on public.emergency_alerts;
create policy alerts_delete_policy
on public.emergency_alerts
for delete
to anon, authenticated
using (true);
