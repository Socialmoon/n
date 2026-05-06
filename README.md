<p align="center">
  <img src="logos/logo2.png" alt="Apne Saathi logo" width="160" />
</p>

# Apne Saathi App

Private Flutter application for internal member coordination and Android-first distribution.

This repository is private and is not intended for public use, external contribution, or general documentation. The README is intentionally kept short.

## Basic Details

- **App name:** Apne Saathi
- **Project:** `apne_saathi_app`
- **Version:** `0.1.5+6`
- **Framework:** Flutter
- **Backend:** Supabase
- **Primary target:** Android
- **Distribution:** Private APK releases

## What The App Covers

- Member login and profile management
- Member directory and search
- Admin approvals and member lifecycle controls
- Emergency alerts
- Help feed and comments
- Donation/payment records and admin verification
- App version gate for update enforcement

## Local Development

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

Build a release APK:

```bash
flutter build apk --release
```

Runtime values such as Supabase keys, OTP secrets, CDN settings, and release storage details should stay outside the README and be managed through local environment files, Supabase settings, or private deployment scripts.
