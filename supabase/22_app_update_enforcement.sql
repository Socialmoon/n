-- Migration: app update enforcement with Supabase Storage APK hosting
-- Run this in Supabase SQL editor.
-- Safe to run multiple times.

-- 1. Create a dedicated public bucket for APK releases.
--    Kept separate from app-media (user photos) for clarity and access control.
insert into storage.buckets (id, name, public)
values ('app-releases', 'app-releases', true)
on conflict (id) do update set public = excluded.public;

-- 2. Allow anyone (anon) to download APKs — no apikey header needed.
drop policy if exists app_releases_public_read on storage.objects;
create policy app_releases_public_read
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'app-releases');

-- 3. Only admins can upload new APK releases.
drop policy if exists app_releases_admin_upload on storage.objects;
create policy app_releases_admin_upload
on storage.objects
for insert
to authenticated
with check (bucket_id = 'app-releases' and public.is_app_admin());

drop policy if exists app_releases_admin_update on storage.objects;
create policy app_releases_admin_update
on storage.objects
for update
to authenticated
using  (bucket_id = 'app-releases' and public.is_app_admin())
with check (bucket_id = 'app-releases' and public.is_app_admin());

drop policy if exists app_releases_admin_delete on storage.objects;
create policy app_releases_admin_delete
on storage.objects
for delete
to authenticated
using (bucket_id = 'app-releases' and public.is_app_admin());

-- 4. Seed the app_settings rows.
--    After uploading your APK to Supabase Storage, Cloudflare R2, or any
--    other public HTTPS host, update app_download_url to:
--    https://<project-ref>.supabase.co/storage/v1/object/public/app-releases/apne-saathi-latest.apk
insert into public.app_settings (key, value)
values
  ('min_app_version', '0.0.0'),
  ('app_download_url', ''),
  ('app_download_fallback_url', '')
on conflict (key) do nothing;

-- 5. HOW TO RELEASE A NEW VERSION:
--
--    Step 1 — Upload APK to Supabase Storage:
--      Option A (Supabase Dashboard):
--        Storage → app-releases → Upload file → upload apne-saathi-latest.apk
--        Always use the same filename so the URL never changes.
--
--      Option B (CLI):
--        npx supabase@latest storage cp ./build/app/outputs/flutter-apk/app-release.apk \
--          ss://app-releases/apne-saathi-latest.apk \
--          --project-ref YOUR_PROJECT_REF
--
--    Step 2 — Set the download URL (run once, URL stays the same after that):
--      update public.app_settings
--      set value = 'https://YOUR_PROJECT_REF.supabase.co/storage/v1/object/public/app-releases/apne-saathi-latest.apk'
--      where key = 'app_download_url';
--
--      Optional fallback (recommended): set Cloudflare/R2 URL for automatic
--      failover if primary URL is restricted or unavailable.
--      update public.app_settings
--      set value = 'https://YOUR_R2_OR_CLOUDFLARE_PUBLIC_URL/apne-saathi-latest.apk'
--      where key = 'app_download_fallback_url';
--
--    Step 3 — Bump the minimum version to force old users to update:
--      update public.app_settings set value = '0.1.5' where key = 'min_app_version';
--
--    Users on versions below 0.1.5 will see the update dialog on next app open.
--    They tap "Download Update" → APK downloads directly from Supabase Storage.
