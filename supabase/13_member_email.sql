-- Add email field to members so registration and device verification can persist email.
alter table public.members
add column if not exists email text;

-- Optional uniqueness guard by normalized email (case-insensitive),
-- allowing null/blank rows for legacy records.
create unique index if not exists members_email_unique_idx
on public.members (lower(email))
where email is not null and btrim(email) <> '';

-- Set current seed admin email.
update public.members
set email = 'sainivaibhav742@gmail.com'
where id = 'seed-admin' or is_admin = true;
