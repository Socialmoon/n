-- Fixes client-side Postgrest 42501 for app_settings upsert and
-- ensures request delete actions work for admins and request owners.

-- APP SETTINGS: allow authenticated clients to insert/update/delete.
drop policy if exists app_settings_insert_policy on public.app_settings;
create policy app_settings_insert_policy
on public.app_settings
for insert
to authenticated
with check (true);

drop policy if exists app_settings_update_policy on public.app_settings;
create policy app_settings_update_policy
on public.app_settings
for update
to authenticated
using (true)
with check (true);

drop policy if exists app_settings_delete_policy on public.app_settings;
create policy app_settings_delete_policy
on public.app_settings
for delete
to authenticated
using (true);

-- HELP POSTS: allow authenticated delete to support admin and post-owner delete.
drop policy if exists help_posts_delete_policy on public.help_posts;
create policy help_posts_delete_policy
on public.help_posts
for delete
to authenticated
using (true);

-- HELP COMMENTS: allow authenticated delete to support admin and commenter delete.
drop policy if exists help_post_comments_delete_policy on public.help_post_comments;
create policy help_post_comments_delete_policy
on public.help_post_comments
for delete
to authenticated
using (true);
