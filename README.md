# Police Network App

This Flutter app now supports cloud sync through Supabase with local fallback.

## Supabase Setup

1. Create a Supabase project.
2. In Supabase dashboard, copy:
   - Project URL
   - anon public key
3. Run SQL files in order:
   - [supabase/01_schema.sql](supabase/01_schema.sql)
   - [supabase/02_rls_policies.sql](supabase/02_rls_policies.sql)
  - [supabase/03_seed_admin.sql](supabase/03_seed_admin.sql) (after replacing placeholders)
4. Start Flutter with runtime keys (do not hardcode in source files):

```bash
flutter run \
  --dart-define=SUPABASE_URL=YOUR_PROJECT_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

For release APK:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=YOUR_PROJECT_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

If no dart-define values are provided, the app automatically falls back to local-only mode.

## Admin Access Setup

The app uses Supabase anonymous auth to get an authenticated user id (`auth.uid()`) for RLS.

To grant admin permissions:

1. Get target user's `id` from Supabase table `auth.users`.
2. Insert into `public.app_admins`:

```sql
insert into public.app_admins (user_id)
values ('USER_UUID_HERE')
on conflict (user_id) do nothing;
```

Admins can read all rows. Non-admin users can only access rows where `owner_id = auth.uid()`.

Current MVP note:
The app uses shared member-directory lookup for login and search, so `members` select access is enabled for all authenticated app users by the RLS policy file. Insert, update, and delete remain restricted.

## Seed Admin Without Hardcoded App Credentials

This app no longer embeds default admin credentials in source code.

To seed admin directly in Supabase:

1. Open [supabase/03_seed_admin.sql](supabase/03_seed_admin.sql).
2. Replace:
  - `CHANGE_ME_AUTH_USER_UUID`
  - `CHANGE_ME_MOBILE`
  - `CHANGE_ME_PASSWORD_HASH_SHA256`
  - `CHANGE_ME_6_DIGIT_MPIN`
3. Run the script in Supabase SQL editor.

After this, any app instance configured with your Supabase project can log in using that admin mobile + M-PIN.

## Required Supabase Tables

Tables and RLS policies are provided in:

- [supabase/01_schema.sql](supabase/01_schema.sql)
- [supabase/02_rls_policies.sql](supabase/02_rls_policies.sql)

## Notes

- Member records and emergency alerts are synced to Supabase.
- URL and anon key are expected to be visible in client builds. Security is enforced by RLS policies, not by hiding anon keys.
