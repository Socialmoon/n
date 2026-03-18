-- Seed one non-admin test member for login and directory testing.
--
-- Default values below create:
-- mobile: 9193410558
-- mpin:   180001
--
-- Update owner_id only if your admin/auth UUID is different.

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
  'seed-member-1',
  '6d1c8e08-a173-4171-ad20-0dc5e314bd69',
  'Test Member One',
  '9193410558',
  'u_9193410558',
  '6d3754c29cb87af22a5d7f28b7d08086eb9484b738bc65056dc99ef6658ddcb6',
  '180001',
  '9193410557',
  'Control Room Admin',
  null,
  null,
  'Headquarters',
  'Headquarters',
  'Field Unit Alpha',
  now(),
  'Member',
  now(),
  now(),
  false
)
on conflict (id) do update
set
  owner_id = excluded.owner_id,
  name = excluded.name,
  mobile_number = excluded.mobile_number,
  user_id = excluded.user_id,
  password_hash = excluded.password_hash,
  mpin = excluded.mpin,
  reference_mobile_number = excluded.reference_mobile_number,
  reference_member_name = excluded.reference_member_name,
  posting_location = excluded.posting_location,
  role = excluded.role,
  is_admin = false,
  last_updated = now();

-- Quick verification query:
-- select id, name, mobile_number, mpin, is_admin from public.members where id = 'seed-member-1';
