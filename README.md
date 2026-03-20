# Apne Saathi App

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
  - [supabase/04_seed_test_member.sql](supabase/04_seed_test_member.sql) (optional, for non-admin test login)
  - [supabase/05_help_feed.sql](supabase/05_help_feed.sql) (optional migration for existing databases)
  - [supabase/06_donations.sql](supabase/06_donations.sql) (optional migration for existing databases)
  - [supabase/07_help_feed_comments.sql](supabase/07_help_feed_comments.sql) (optional migration for existing databases)
  - [supabase/08_member_blocking.sql](supabase/08_member_blocking.sql) (optional migration for existing databases)
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

If no dart-define values are provided, the app now uses the built-in default Supabase project configured in `lib/core/supabase_config.dart`.

## OTP (Twilio Verify)

- OTP send and verification are handled through Supabase Edge Functions.
- Twilio secrets are stored only in Supabase Function secrets, not in the Flutter app.

### OTP Function Setup (CLI)

From project root:

```bash
npx supabase@latest functions new send-otp
npx supabase@latest functions new verify-otp
```

Set secrets on Supabase (replace values):

```bash
npx supabase@latest secrets set \
  TWILIO_ACCOUNT_SID=YOUR_TWILIO_ACCOUNT_SID \
  TWILIO_AUTH_TOKEN=YOUR_TWILIO_AUTH_TOKEN \
  TWILIO_VERIFY_SERVICE_SID=YOUR_VERIFY_SERVICE_SID \
  --project-ref YOUR_PROJECT_REF
```

Deploy functions:

```bash
npx supabase@latest functions deploy send-otp --project-ref YOUR_PROJECT_REF --no-verify-jwt
npx supabase@latest functions deploy verify-otp --project-ref YOUR_PROJECT_REF --no-verify-jwt
```

### Rotate Revoked Twilio Credentials (Windows PowerShell)

If previous Twilio credentials were revoked, set new values and redeploy:

```powershell
$env:TWILIO_ACCOUNT_SID="YOUR_NEW_ACCOUNT_SID"
$env:TWILIO_AUTH_TOKEN="YOUR_NEW_AUTH_TOKEN"
$env:TWILIO_VERIFY_SERVICE_SID="YOUR_NEW_VERIFY_SERVICE_SID"

npx supabase@latest secrets set `
  TWILIO_ACCOUNT_SID=$env:TWILIO_ACCOUNT_SID `
  TWILIO_AUTH_TOKEN=$env:TWILIO_AUTH_TOKEN `
  TWILIO_VERIFY_SERVICE_SID=$env:TWILIO_VERIFY_SERVICE_SID `
  --project-ref YOUR_PROJECT_REF

npx supabase@latest functions deploy send-otp --project-ref YOUR_PROJECT_REF --no-verify-jwt
npx supabase@latest functions deploy verify-otp --project-ref YOUR_PROJECT_REF --no-verify-jwt
```

How to get new Twilio values:
- `TWILIO_ACCOUNT_SID`: Twilio Console Home -> Account Info -> Account SID.
- `TWILIO_AUTH_TOKEN`: Twilio Console Home -> Account Info -> Auth Token -> reveal/regenerate.
- `TWILIO_VERIFY_SERVICE_SID`: Twilio Console -> Verify -> Services -> open your service (or create one) -> Service SID.
- If you regenerate the Auth Token, immediately update Supabase secrets and redeploy both OTP functions.

Notes:
- Current app calls these functions using the Supabase anon key headers.
- Add rate limiting and abuse controls on server side before production rollout.
- There is no local OTP fallback; OTP works only through the deployed Supabase Edge Functions and Twilio Verify.

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
- Help Feed posts are synced and visible to all members for support requests.
- Help Feed comments are synced and visible to all members.
- Donation entries are synced with proof details for admin verification workflows.
- URL and anon key are expected to be visible in client builds. Security is enforced by RLS policies, not by hiding anon keys.
