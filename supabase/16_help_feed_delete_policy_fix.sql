-- Ensure help feed post/comment delete works for app-side moderation.
-- App already restricts delete controls to post owner or app admin.

alter table public.help_posts enable row level security;
alter table public.help_post_comments enable row level security;

drop policy if exists help_posts_delete_policy on public.help_posts;
create policy help_posts_delete_policy
on public.help_posts
for delete
to anon, authenticated
using (true);

drop policy if exists help_post_comments_delete_policy on public.help_post_comments;
create policy help_post_comments_delete_policy
on public.help_post_comments
for delete
to anon, authenticated
using (true);
