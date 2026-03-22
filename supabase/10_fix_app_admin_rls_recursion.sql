-- Fix recursive RLS evaluation on public.app_admins caused by
-- policies that call public.is_app_admin(), which itself queries app_admins.

-- Keep helper function explicit and predictable.
create or replace function public.is_app_admin()
returns boolean
language sql
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.app_admins a
    where a.user_id = auth.uid()
  );
$$;

-- Remove recursive policies and use non-recursive checks.
drop policy if exists app_admins_select_policy on public.app_admins;
create policy app_admins_select_policy
on public.app_admins
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists app_admins_insert_policy on public.app_admins;
create policy app_admins_insert_policy
on public.app_admins
for insert
to authenticated
with check (false);

drop policy if exists app_admins_delete_policy on public.app_admins;
create policy app_admins_delete_policy
on public.app_admins
for delete
to authenticated
using (false);

-- Optional verification:
-- select public.is_app_admin() as is_admin, auth.uid() as current_uid;
