-- WARNING: This makes runtime access highly permissive for anon/authenticated.
-- Use only when your priority is preventing all RLS blocks in the app flow.
-- Safe to run multiple times.

-- Members
alter table public.members enable row level security;
drop policy if exists members_select_policy on public.members;
drop policy if exists members_insert_policy on public.members;
drop policy if exists members_update_policy on public.members;
drop policy if exists members_delete_policy on public.members;
create policy members_select_policy on public.members for select to anon, authenticated using (true);
create policy members_insert_policy on public.members for insert to anon, authenticated with check (true);
create policy members_update_policy on public.members for update to anon, authenticated using (true) with check (true);
create policy members_delete_policy on public.members for delete to anon, authenticated using (true);

-- Emergency alerts
alter table public.emergency_alerts enable row level security;
drop policy if exists alerts_select_policy on public.emergency_alerts;
drop policy if exists alerts_insert_policy on public.emergency_alerts;
drop policy if exists alerts_update_policy on public.emergency_alerts;
drop policy if exists alerts_delete_policy on public.emergency_alerts;
create policy alerts_select_policy on public.emergency_alerts for select to anon, authenticated using (true);
create policy alerts_insert_policy on public.emergency_alerts for insert to anon, authenticated with check (true);
create policy alerts_update_policy on public.emergency_alerts for update to anon, authenticated using (true) with check (true);
create policy alerts_delete_policy on public.emergency_alerts for delete to anon, authenticated using (true);

-- Help posts
alter table public.help_posts enable row level security;
drop policy if exists help_posts_select_policy on public.help_posts;
drop policy if exists help_posts_insert_policy on public.help_posts;
drop policy if exists help_posts_update_policy on public.help_posts;
drop policy if exists help_posts_delete_policy on public.help_posts;
create policy help_posts_select_policy on public.help_posts for select to anon, authenticated using (true);
create policy help_posts_insert_policy on public.help_posts for insert to anon, authenticated with check (true);
create policy help_posts_update_policy on public.help_posts for update to anon, authenticated using (true) with check (true);
create policy help_posts_delete_policy on public.help_posts for delete to anon, authenticated using (true);

-- Help comments
alter table public.help_post_comments enable row level security;
drop policy if exists help_post_comments_select_policy on public.help_post_comments;
drop policy if exists help_post_comments_insert_policy on public.help_post_comments;
drop policy if exists help_post_comments_update_policy on public.help_post_comments;
drop policy if exists help_post_comments_delete_policy on public.help_post_comments;
create policy help_post_comments_select_policy on public.help_post_comments for select to anon, authenticated using (true);
create policy help_post_comments_insert_policy on public.help_post_comments for insert to anon, authenticated with check (true);
create policy help_post_comments_update_policy on public.help_post_comments for update to anon, authenticated using (true) with check (true);
create policy help_post_comments_delete_policy on public.help_post_comments for delete to anon, authenticated using (true);

-- Donations
alter table public.donations enable row level security;
drop policy if exists donations_select_policy on public.donations;
drop policy if exists donations_insert_policy on public.donations;
drop policy if exists donations_update_policy on public.donations;
drop policy if exists donations_delete_policy on public.donations;
create policy donations_select_policy on public.donations for select to anon, authenticated using (true);
create policy donations_insert_policy on public.donations for insert to anon, authenticated with check (true);
create policy donations_update_policy on public.donations for update to anon, authenticated using (true) with check (true);
create policy donations_delete_policy on public.donations for delete to anon, authenticated using (true);

-- App settings
alter table public.app_settings enable row level security;
drop policy if exists app_settings_select_policy on public.app_settings;
drop policy if exists app_settings_insert_policy on public.app_settings;
drop policy if exists app_settings_update_policy on public.app_settings;
drop policy if exists app_settings_delete_policy on public.app_settings;
create policy app_settings_select_policy on public.app_settings for select to anon, authenticated using (true);
create policy app_settings_insert_policy on public.app_settings for insert to anon, authenticated with check (true);
create policy app_settings_update_policy on public.app_settings for update to anon, authenticated using (true) with check (true);
create policy app_settings_delete_policy on public.app_settings for delete to anon, authenticated using (true);

-- App admins (also permissive to avoid any auth.uid-related checks causing blocks)
alter table public.app_admins enable row level security;
drop policy if exists app_admins_select_policy on public.app_admins;
drop policy if exists app_admins_insert_policy on public.app_admins;
drop policy if exists app_admins_delete_policy on public.app_admins;
create policy app_admins_select_policy on public.app_admins for select to anon, authenticated using (true);
create policy app_admins_insert_policy on public.app_admins for insert to anon, authenticated with check (true);
create policy app_admins_delete_policy on public.app_admins for delete to anon, authenticated using (true);

-- Storage policies for app-media bucket
insert into storage.buckets (id, name, public)
values ('app-media', 'app-media', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists app_media_public_read on storage.objects;
drop policy if exists app_media_upload_policy on storage.objects;
drop policy if exists app_media_update_policy on storage.objects;
drop policy if exists app_media_delete_policy on storage.objects;

create policy app_media_public_read
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'app-media');

create policy app_media_upload_policy
on storage.objects
for insert
to anon, authenticated
with check (bucket_id = 'app-media');

create policy app_media_update_policy
on storage.objects
for update
to anon, authenticated
using (bucket_id = 'app-media')
with check (bucket_id = 'app-media');

create policy app_media_delete_policy
on storage.objects
for delete
to anon, authenticated
using (bucket_id = 'app-media');
