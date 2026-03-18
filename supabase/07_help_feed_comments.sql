-- Help feed comments migration for existing projects.
-- Run this for databases created before comments feature was added.

create table if not exists public.help_post_comments (
  id text primary key,
  owner_id uuid default auth.uid(),
  post_id text not null references public.help_posts(id) on delete cascade,
  member_id text not null,
  member_name text not null,
  message text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_help_post_comments_post_id on public.help_post_comments(post_id);

alter table public.help_post_comments enable row level security;

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
