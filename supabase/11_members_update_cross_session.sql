-- Allow member profile updates across new/incognito app sessions.
-- Rationale: app auth uses anonymous sessions whose auth.uid() can differ by browser/session.
-- The previous owner_id = auth.uid() rule prevented legitimate profile edits from persisting.

drop policy if exists members_update_policy on public.members;
create policy members_update_policy
on public.members
for update
to authenticated
using (true)
with check (true);

-- Optional verification:
-- select policyname, cmd, roles, qual, with_check
-- from pg_policies
-- where schemaname = 'public' and tablename = 'members';
