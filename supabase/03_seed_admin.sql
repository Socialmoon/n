-- Seed one admin user directly in Supabase (no hardcoded app credentials).
--
-- Prerequisites:
-- 1) Run 01_schema.sql and 02_rls_policies.sql first.
-- 2) Ensure the target user's UUID exists in auth.users.
--
-- Replace all CHANGE_ME_* values before running.

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
  'CHANGE_ME_AUTH_USER_UUID',
  'Control Room Admin',
  'CHANGE_ME_MOBILE',
  'admin',
  'CHANGE_ME_PASSWORD_HASH_SHA256',
  'CHANGE_ME_6_DIGIT_MPIN',
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
values ('CHANGE_ME_AUTH_USER_UUID')
on conflict (user_id) do nothing;
