-- Fix donation UPI/QR settings write failures under RLS.
--
-- Why:
-- App settings writes can come through authenticated session or REST fallback.
-- In some environments, only anon role is available during fallback and writes fail.
--
-- Scope:
-- Allow insert/update/delete only for donation-related app_settings keys,
-- for anon + authenticated roles.

alter table public.app_settings enable row level security;

drop policy if exists app_settings_insert_policy on public.app_settings;
create policy app_settings_insert_policy
on public.app_settings
for insert
to anon, authenticated
with check (
  key in (
    'donation_upi_id',
    'donation_upi_name',
    'donation_admin_mobile',
    'donation_qr_image_url'
  )
);

drop policy if exists app_settings_update_policy on public.app_settings;
create policy app_settings_update_policy
on public.app_settings
for update
to anon, authenticated
using (
  key in (
    'donation_upi_id',
    'donation_upi_name',
    'donation_admin_mobile',
    'donation_qr_image_url'
  )
)
with check (
  key in (
    'donation_upi_id',
    'donation_upi_name',
    'donation_admin_mobile',
    'donation_qr_image_url'
  )
);

drop policy if exists app_settings_delete_policy on public.app_settings;
create policy app_settings_delete_policy
on public.app_settings
for delete
to anon, authenticated
using (
  key in (
    'donation_upi_id',
    'donation_upi_name',
    'donation_admin_mobile',
    'donation_qr_image_url'
  )
);
