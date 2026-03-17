-- Core schema for Police Network app sync.

create extension if not exists pgcrypto;

create table if not exists public.members (
  id text primary key,
  owner_id uuid not null default auth.uid(),
  name text not null,
  mobile_number text not null,
  user_id text not null,
  password_hash text not null,
  mpin text not null,
  reference_mobile_number text,
  reference_member_name text,
  selfie_path text,
  home_district text not null,
  posting_district text not null,
  posting_location text not null,
  appointment_date timestamptz not null,
  role text not null,
  last_updated timestamptz not null,
  password_updated_at timestamptz not null,
  is_admin boolean not null default false
);

create table if not exists public.emergency_alerts (
  id text primary key,
  owner_id uuid not null default auth.uid(),
  member_id text not null,
  member_name text not null,
  timestamp timestamptz not null,
  message text not null,
  location text not null
);

create table if not exists public.app_admins (
  user_id uuid primary key,
  created_at timestamptz not null default now()
);

create index if not exists idx_members_owner_id on public.members(owner_id);
create index if not exists idx_alerts_owner_id on public.emergency_alerts(owner_id);
create index if not exists idx_alerts_timestamp on public.emergency_alerts(timestamp desc);

-- Helper used by RLS policies.
create or replace function public.is_app_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.app_admins a
    where a.user_id = auth.uid()
  );
$$;
