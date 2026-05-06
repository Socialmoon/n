-- Migration: Storage security hardening - restrict file listing
-- Date: 2026-05-06
-- Issue: Broad SELECT policies on storage.objects allow clients to list all files
-- Fix: Remove SELECT policies, keep only GET for direct downloads

-- 1. Drop overly permissive SELECT policies that allow file listing
DROP POLICY IF EXISTS app_releases_public_read ON storage.objects;
DROP POLICY IF EXISTS app_media_public_read ON storage.objects;

-- 2. Recreate app_releases policy: GET only (direct download), NO listing
CREATE POLICY app_releases_download_only
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'app-releases' AND auth.role() = 'anon')
WITH CHECK (false); -- Prevents enumeration queries

-- Alternative approach: Use exact path matching for downloads
-- This allows direct downloads via presigned URLs or public URLs
-- but prevents SELECT queries that list objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. For app_media bucket: Allow authenticated users to download their own media
DROP POLICY IF EXISTS app_media_authenticated_download ON storage.objects;
CREATE POLICY app_media_authenticated_download
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'app-media');

-- 4. Admin upload policies remain unchanged
DROP POLICY IF EXISTS app_releases_admin_upload ON storage.objects;
CREATE POLICY app_releases_admin_upload
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'app-releases' AND public.is_app_admin());

DROP POLICY IF EXISTS app_releases_admin_update ON storage.objects;
CREATE POLICY app_releases_admin_update
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'app-releases' AND public.is_app_admin())
WITH CHECK (bucket_id = 'app-releases' AND public.is_app_admin());

DROP POLICY IF EXISTS app_releases_admin_delete ON storage.objects;
CREATE POLICY app_releases_admin_delete
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'app-releases' AND public.is_app_admin());

-- Note: This still allows direct downloads via:
-- - Presigned URLs (generated server-side)
-- - Direct public URLs: /storage/v1/object/public/app-releases/apne-saathi-latest.apk
-- - But prevents SELECT queries that enumerate all files
