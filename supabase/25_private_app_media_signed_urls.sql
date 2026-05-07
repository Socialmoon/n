-- Make app media private so stale clients cannot keep pulling public image URLs.
-- New app builds resolve image URLs through signed URLs after login.

insert into app_settings (key, value)
values ('app_media_is_private', 'true')
on conflict (key) do update
set value = excluded.value;

insert into storage.buckets (id, name, public)
values ('app-media', 'app-media', false)
on conflict (id) do update
set public = excluded.public;

drop policy if exists app_media_public_read on storage.objects;
drop policy if exists app_media_private_read on storage.objects;
create policy app_media_private_read
on storage.objects
for select
to authenticated
using (bucket_id = 'app-media');

drop policy if exists app_media_upload_policy on storage.objects;
create policy app_media_upload_policy
on storage.objects
for insert
to anon, authenticated
with check (bucket_id = 'app-media');

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
