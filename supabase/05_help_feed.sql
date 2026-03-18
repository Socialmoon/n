-- Help Feed migration for existing projects.
-- Run this if your database was already created before help feed was added.

create table if not exists public.help_posts (
  id text primary key,
  owner_id uuid default auth.uid(),
  member_id text not null,
  member_name text not null,
  member_mobile text not null,
  category text not null,
  message text not null,
  location text not null,
  requested_amount numeric,
  created_at timestamptz not null default now()
);

create index if not exists idx_help_posts_created_at on public.help_posts(created_at desc);

alter table public.help_posts enable row level security;

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
