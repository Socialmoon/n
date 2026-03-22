-- Adds extended posting/home profile fields and live location columns for members.

alter table public.members
  add column if not exists department text;

alter table public.members
  add column if not exists post_rank text;

alter table public.members
  add column if not exists official_name text;

alter table public.members
  add column if not exists batch_year text;

alter table public.members
  add column if not exists whatsapp_number text;

alter table public.members
  add column if not exists calling_contact_number text;

alter table public.members
  add column if not exists posting_place_location text;

alter table public.members
  add column if not exists emergency_contact text;

alter table public.members
  add column if not exists home_village_mohalla text;

alter table public.members
  add column if not exists home_gali_no text;

alter table public.members
  add column if not exists home_post_office text;

alter table public.members
  add column if not exists home_police_station text;

alter table public.members
  add column if not exists home_tehsil text;

alter table public.members
  add column if not exists home_village_location text;

alter table public.members
  add column if not exists live_latitude double precision;

alter table public.members
  add column if not exists live_longitude double precision;

alter table public.members
  add column if not exists live_location_updated_at timestamptz;
