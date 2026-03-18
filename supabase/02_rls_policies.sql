-- Enable and enforce row-level security.

alter table public.members enable row level security;
alter table public.emergency_alerts enable row level security;
alter table public.app_admins enable row level security;
alter table public.help_posts enable row level security;
alter table public.donations enable row level security;
alter table public.help_post_comments enable row level security;

-- MEMBERS policies
drop policy if exists members_select_policy on public.members;
create policy members_select_policy
on public.members
for select
to anon, authenticated
using (true);

drop policy if exists members_insert_policy on public.members;
create policy members_insert_policy
on public.members
for insert
to authenticated
with check (public.is_app_admin() or owner_id = auth.uid());

drop policy if exists members_update_policy on public.members;
create policy members_update_policy
on public.members
for update
to authenticated
using (public.is_app_admin() or owner_id = auth.uid())
with check (public.is_app_admin() or owner_id = auth.uid());

drop policy if exists members_delete_policy on public.members;
create policy members_delete_policy
on public.members
for delete
to authenticated
using (public.is_app_admin() or owner_id = auth.uid());

-- EMERGENCY ALERTS policies
drop policy if exists alerts_select_policy on public.emergency_alerts;
create policy alerts_select_policy
on public.emergency_alerts
for select
to authenticated
using (public.is_app_admin() or owner_id = auth.uid());

drop policy if exists alerts_insert_policy on public.emergency_alerts;
create policy alerts_insert_policy
on public.emergency_alerts
for insert
to authenticated
with check (public.is_app_admin() or owner_id = auth.uid());

drop policy if exists alerts_update_policy on public.emergency_alerts;
create policy alerts_update_policy
on public.emergency_alerts
for update
to authenticated
using (public.is_app_admin() or owner_id = auth.uid())
with check (public.is_app_admin() or owner_id = auth.uid());

drop policy if exists alerts_delete_policy on public.emergency_alerts;
create policy alerts_delete_policy
on public.emergency_alerts
for delete
to authenticated
using (public.is_app_admin() or owner_id = auth.uid());

-- HELP FEED policies
drop policy if exists help_posts_select_policy on public.help_posts;
create policy help_posts_select_policy
on public.help_posts
for select
to anon, authenticated
using (true);

drop policy if exists help_posts_insert_policy on public.help_posts;
create policy help_posts_insert_policy
on public.help_posts
for insert
to anon, authenticated
with check (true);

drop policy if exists help_posts_update_policy on public.help_posts;
create policy help_posts_update_policy
on public.help_posts
for update
to authenticated
using (public.is_app_admin() or owner_id = auth.uid())
with check (public.is_app_admin() or owner_id = auth.uid());

drop policy if exists help_posts_delete_policy on public.help_posts;
create policy help_posts_delete_policy
on public.help_posts
for delete
to authenticated
using (public.is_app_admin() or owner_id = auth.uid());

-- HELP FEED COMMENTS policies
drop policy if exists help_post_comments_select_policy on public.help_post_comments;
create policy help_post_comments_select_policy
on public.help_post_comments
for select
to anon, authenticated
using (true);

drop policy if exists help_post_comments_insert_policy on public.help_post_comments;
create policy help_post_comments_insert_policy
on public.help_post_comments
for insert
to anon, authenticated
with check (true);

drop policy if exists help_post_comments_update_policy on public.help_post_comments;
create policy help_post_comments_update_policy
on public.help_post_comments
for update
to authenticated
using (public.is_app_admin() or owner_id = auth.uid())
with check (public.is_app_admin() or owner_id = auth.uid());

drop policy if exists help_post_comments_delete_policy on public.help_post_comments;
create policy help_post_comments_delete_policy
on public.help_post_comments
for delete
to authenticated
using (public.is_app_admin() or owner_id = auth.uid());

-- DONATIONS policies
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

-- APP ADMINS policies (only admins can see/edit this list)
drop policy if exists app_admins_select_policy on public.app_admins;
create policy app_admins_select_policy
on public.app_admins
for select
to authenticated
using (public.is_app_admin());

drop policy if exists app_admins_insert_policy on public.app_admins;
create policy app_admins_insert_policy
on public.app_admins
for insert
to authenticated
with check (public.is_app_admin());

drop policy if exists app_admins_delete_policy on public.app_admins;
create policy app_admins_delete_policy
on public.app_admins
for delete
to authenticated
using (public.is_app_admin());
