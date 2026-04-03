-- Allow all logged-in app users to read emergency alerts so alerts can sync across devices.
-- Run this migration in Supabase SQL editor.

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
