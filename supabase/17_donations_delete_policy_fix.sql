-- Ensure donation delete from app admin screens works in anon-session projects.

alter table public.donations enable row level security;

drop policy if exists donations_delete_policy on public.donations;
create policy donations_delete_policy
on public.donations
for delete
to anon, authenticated
using (true);
