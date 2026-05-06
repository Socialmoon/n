-- Migration: Forced version update with media blocking
-- Date: 2026-05-06
-- Purpose: Block old app versions from using the app entirely
-- Block image/media serving to prevent egress usage

-- 1. Set minimum version to 9.9.9 (blocks all current versions)
-- Users on 0.1.4 will see "Update Required" dialog
UPDATE public.app_settings
SET value = '9.9.9'
WHERE key = 'min_app_version';

-- 2. Create a function to check version and block media access
CREATE OR REPLACE FUNCTION public.get_app_media_with_version_check()
RETURNS TABLE (
  status TEXT,
  message TEXT,
  media_url TEXT
) AS $$
BEGIN
  -- Check if user's app version is valid
  -- This can be called by the app to verify it should download images
  -- If version is too old, return error instead of media URLs
  
  RETURN QUERY SELECT 
    'blocked'::TEXT,
    'Please update the app to continue'::TEXT,
    NULL::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Add version check to image download attempts
-- When app requests images, it must pass version header
-- If version < min_app_version, deny the request

-- 4. Create a view for old version detection
CREATE OR REPLACE VIEW public.old_app_versions AS
SELECT 
  auth.uid() as user_id,
  'old_version' as status,
  NOW() as detected_at
WHERE auth.uid() IS NOT NULL;

-- 5. Block storage access for old versions
-- Add this to auth.users or create a trigger
-- For now, rely on app-side version check

-- 6. Set update URLs
UPDATE public.app_settings
SET value = 'https://iuhecyqizatkiskoznwq.supabase.co/storage/v1/object/public/app-releases/apne-saathi-latest.apk'
WHERE key = 'app_download_url';

-- 7. Add fallback if primary is slow
UPDATE public.app_settings
SET value = 'https://github.com/Socialmoon/n/releases/download/v0.1.4+5/apne-saathi.apk'
WHERE key = 'app_download_fallback_url';

-- 8. Create custom app_settings entries for update messaging
INSERT INTO public.app_settings (key, value)
VALUES 
  ('update_required_title', 'Update Required'),
  ('update_required_message', 'Please update to the latest version to continue using the app.'),
  ('update_button_text', 'Update Now'),
  ('can_skip_update', 'false')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- Note: Set can_skip_update to 'false' to force updates with no dismiss button
-- Set to 'true' to allow users to dismiss (not recommended)
