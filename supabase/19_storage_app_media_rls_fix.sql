-- Ensure app-media storage bucket and upload policies are present for anon/authenticated clients.
-- Safe to run multiple times.

insert into storage.buckets (id, name, public)
values ('app-media', 'app-media', true)
on conflict (id) do update
set public = excluded.public;

drop policy if exists app_media_public_read on storage.objects;
create policy app_media_public_read
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'app-media');

drop policy if exists app_media_upload_policy on storage.objects;
create policy app_media_upload_policy
on storage.objects
for insert
to anon, authenticated
with check (bucket_id = 'app-media');

-- Keep update/delete restricted to object owner or app admin.
drop policy if exists app_media_update_policy on storage.objects;
create policy app_media_update_policy
on storage.objects
for update
to authenticated
using (bucket_id = 'app-media' and (public.is_app_admin() or owner = auth.uid()))
with check (bucket_id = 'app-media' and (public.is_app_admin() or owner = auth.uid()));

drop policy if exists app_media_delete_policy on storage.objects;
create policy app_media_delete_policy
on storage.objects
for delete
to authenticated
using (bucket_id = 'app-media' and (public.is_app_admin() or owner = auth.uid()));
