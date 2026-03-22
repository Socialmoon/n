-- Seed one admin user directly in Supabase (no hardcoded app credentials).
--
-- Prerequisites:
-- 1) Run 01_schema.sql and 02_rls_policies.sql first.
-- 2) Ensure the target user's UUID exists in auth.users.

insert into public.members (
  id,
  owner_id,
  name,
  mobile_number,
  user_id,
  password_hash,
  mpin,
  reference_mobile_number,
  reference_member_name,
  selfie_path,
  id_card_photo_path,
  home_district,
  posting_district,
  posting_location,
  appointment_date,
  role,
  last_updated,
  password_updated_at,
  is_admin
)
values (
  'seed-admin',
  '6d1c8e08-a173-4171-ad20-0dc5e314bd69',
  'Control Room Admin',
  '9193410557',
  'admin',
  '6d1a8c14a653079e16d4c1163f1231470c1958f6c728e5234f9db560e16a901a',
  '180000',
  '',
  null,
  null,
  null,
  'Headquarters',
  'Headquarters',
  'Central Desk',
  now(),
  'Administrator',
  now(),
  now(),
  true
)
on conflict (id) do update
set
  owner_id = excluded.owner_id,
  mobile_number = excluded.mobile_number,
  password_hash = excluded.password_hash,
  mpin = excluded.mpin,
  is_admin = true,
  last_updated = now();

insert into public.app_admins (user_id)
values ('6d1c8e08-a173-4171-ad20-0dc5e314bd69')
on conflict (user_id) do nothing;
