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
  - [supabase/13_member_email.sql](supabase/13_member_email.sql)
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

If no dart-define values are provided, the app uses the built-in default Supabase URL from `lib/core/supabase_config.dart`, but you still need to provide `SUPABASE_ANON_KEY` (recommended for all environments).

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

## Email OTP (Gmail SMTP)

- Email OTP send/verify are handled through Supabase Edge Functions:
  - `send-email-otp`
  - `verify-email-otp`
- Required Supabase secrets:
  - `GMAIL_SMTP_USER` (default sender can be `apnesaathiheadquarter@gmail.com`)
  - `EMAIL_FROM_NAME` (optional sender name, e.g. `Apne Saathi`)
  - `GMAIL_SMTP_APP_PASSWORD` (Google App Password, not account password)
  - `EMAIL_OTP_SECRET` (long random secret used to sign OTP slots)

Set email OTP secrets manually:

```bash
npx supabase@latest secrets set \
  GMAIL_SMTP_USER=apnesaathiheadquarter@gmail.com \
  EMAIL_FROM_NAME="Apne Saathi" \
  GMAIL_SMTP_APP_PASSWORD=YOUR_16_CHAR_APP_PASSWORD \
  EMAIL_OTP_SECRET=YOUR_LONG_RANDOM_SECRET \
  --project-ref YOUR_PROJECT_REF
```

Deploy email OTP functions:

```bash
npx supabase@latest functions deploy send-email-otp --project-ref YOUR_PROJECT_REF --no-verify-jwt
npx supabase@latest functions deploy verify-email-otp --project-ref YOUR_PROJECT_REF --no-verify-jwt
```

### One-command deploy (Twilio + Email OTP)

Fill values in `.env`, then run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/deploy_otp_stack.ps1
```

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

## Image CDN & Storage Optimisation

The app uses a three-layer strategy to keep Supabase egress well within the 5 GB free-tier limit:

### Layer 1 — WebP compression on upload
Every profile photo and donation screenshot is automatically compressed to WebP (quality 82, max 900 px) before being uploaded to Supabase Storage. This reduces file sizes by 50–70 % compared to raw JPEG.

### Layer 2 — Cloudflare CDN (one-time setup)

1. Add your domain to Cloudflare (free plan is fine).
  If the zone shows as pending, update the domain's nameservers at your registrar to the two Cloudflare nameservers shown in the dashboard.
2. Create a DNS CNAME record:
   ```
  img.vaibhavsaini.in  →  iuhecyqizatkiskoznwq.supabase.co
   ```
3. In Cloudflare dashboard → **Rules → Cache Rules**, add:
  - URL pattern: `img.vaibhavsaini.in/*`
   - Cache: **Cache Everything**
   - Edge TTL: **1 month**
   - Browser TTL: **7 days**
4. Build the app with the CDN base URL:
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=YOUR_PROJECT_URL \
     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=CDN_BASE_URL=https://img.vaibhavsaini.in
   ```
   For release APK:
   ```bash
   flutter build apk --release \
     --dart-define=SUPABASE_URL=YOUR_PROJECT_URL \
     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=CDN_BASE_URL=https://img.vaibhavsaini.in
   ```

When `CDN_BASE_URL` is set, all Supabase Storage URLs are automatically rewritten to go through Cloudflare. CDN-served images require no `apikey` header, so Cloudflare caches them correctly. If `CDN_BASE_URL` is not set, the app falls back to direct Supabase URLs transparently.

### Optional local `.env` values for Cloudflare

If you want to keep Cloudflare settings in the repo's local `.env`, add values like these:

```text
CLOUDFLARE_API_TOKEN=
CLOUDFLARE_ACCOUNT_ID=
CLOUDFLARE_ZONE_ID=
CLOUDFLARE_MEDIA_HOST=img.vaibhavsaini.in
CLOUDFLARE_R2_BUCKET=app-releases
CLOUDFLARE_R2_PUBLIC_BASE_URL=
CLOUDFLARE_CDN_BASE_URL=https://img.vaibhavsaini.in
```

Use them as follows:

- `CLOUDFLARE_CDN_BASE_URL` maps to the Flutter build flag `CDN_BASE_URL`.
- `CLOUDFLARE_R2_PUBLIC_BASE_URL` is the public APK download URL you save in Supabase `app_settings.app_download_url`.
- `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, and `CLOUDFLARE_ZONE_ID` are for terminal scripts or manual Cloudflare API work, not for the Flutter app.

To run Flutter using the `.env` values, use the helper script:

```powershell
powershell -ExecutionPolicy Bypass -File tools/flutter_from_env.ps1 -Mode run
```

For a release APK:

```powershell
powershell -ExecutionPolicy Bypass -File tools/flutter_from_env.ps1 -Mode build-apk
```

### Layer 3 — Flutter disk cache
`cached_network_image` caches every image to device disk. Users scrolling through the member list will not re-download the same avatars on subsequent app sessions.

### Combined impact
| Optimisation | Benefit |
|---|---|
| WebP compression | ~50–70 % smaller files stored and transferred |
| Cloudflare CDN | ~80–95 % fewer Supabase origin hits |
| Flutter disk cache | Zero repeat downloads within a device session |



## APK Deployment

APK releases are hosted on **Supabase Storage** (`app-releases` bucket) — no GitHub authentication needed, works with private repos.

### One-time setup

1. Run [supabase/22_app_update_enforcement.sql](supabase/22_app_update_enforcement.sql) in Supabase SQL editor.
2. Set the download URL (run once — URL stays the same because you always overwrite the same filename):

```sql
update public.app_settings
set value = 'https://YOUR_PROJECT_REF.supabase.co/storage/v1/object/public/app-releases/apne-saathi-latest.apk'
where key = 'app_download_url';
```

### How to release a new version

**Step 1 — Build the APK:**
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=YOUR_PROJECT_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

**Step 2 — Upload to Supabase Storage (always same filename so URL never changes):**

Option A — Supabase Dashboard:
- Storage → `app-releases` → Upload → select APK → rename to `apne-saathi-latest.apk`

Option B — Supabase CLI:
```bash
npx supabase@latest storage cp ./build/app/outputs/flutter-apk/app-release.apk \
  ss://app-releases/apne-saathi-latest.apk \
  --project-ref YOUR_PROJECT_REF
```

**Step 3 — Force old users to update (set to your new pubspec.yaml version):**
```sql
update public.app_settings set value = '0.1.5' where key = 'min_app_version';
```

Users below that version see a non-dismissible update dialog on next app open. Tapping **Download Update** downloads the APK directly from Supabase Storage and Android prompts to install it.

To disable enforcement (allow all versions):
```sql
update public.app_settings set value = '0.0.0' where key = 'min_app_version';
```
