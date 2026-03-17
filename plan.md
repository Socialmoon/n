# PROJECT_PLAN.md

## Police Network Secure Member App

This document explains the **complete project requirements, architecture, and implementation plan** so an AI coding agent (Claude) can understand the entire project and build it step-by-step without additional explanation.

---

# 1. Project Goal

Build a **secure mobile application for internal member networking** that allows verified members to:

* Register through a **referral system**
* Log in securely using mobile authentication
* View posting information of other members
* Contact members via phone or WhatsApp
* Send emergency alerts
* Maintain posting history
* Prevent misuse of sensitive data

Initial delivery target is an **Android APK for internal distribution**.

No Play Store publishing is required for the first version.

APK will be distributed through **GitHub Releases**.

---

# 2. Target Platform

Primary platform:

* Android (APK)

Future support:

* iOS

Framework:

* Flutter

Programming language:

* Dart

---

# 3. Development Philosophy

The system should be developed in **phases**.

Start with a **Minimum Viable Product (MVP)** and gradually add security and advanced features.

Phase structure:

Phase 1
Core application

Phase 2
Security enhancements

Phase 3
Backend and infrastructure

Phase 4
Advanced features

---

# 4. Core Features

## 4.1 Member Registration

Registration must follow a **referral-based system**.

Steps:

1. User opens app
2. Clicks **New Member Register**
3. Enters:

   * mobile number
   * reference member mobile number
4. OTP verification
5. User creates:

   * user ID
   * password

User must upload:

* selfie photo
* personal details
* home district
* posting district
* posting location
* appointment date
* role or designation

Before final submission:

* reference member information should auto-display
* user confirms correctness
* registration completes

---

## 4.2 Login System

Users can log in using:

Option 1
OTP via mobile number

Option 2
6 digit M-PIN

Option 3
Fingerprint authentication

Login must validate user credentials and device.

---

## 4.3 Member Directory

Users can search members by:

* district
* posting location

Visible fields:

* name
* posting location
* role
* active mobile number

Hidden fields:

* home district

Home district information should be **accessible only to admin**.

---

## 4.4 Contact System

User can interact with another member using:

* Phone call
* WhatsApp message

Actions:

* copy phone number
* open dialer
* open WhatsApp

---

## 4.5 Screenshot Protection

Users must **not be able to take screenshots** of the member directory.

However:

* copying phone number is allowed

Implementation suggestion:

Android secure flag.

---

## 4.6 Device Binding

Application must only work on the **device used during registration**.

Login should fail if attempted from a different device.

Approach:

Store device identifier with user account.

---

## 4.7 Emergency Alert System

Add an emergency button.

When triggered:

* sends alert notification
* activates vibration
* displays alert message

Future extension:

broadcast alert to multiple members.

---

## 4.8 Mandatory Data Update

Every **6 months** user must update:

* active mobile number
* posting information

If user does not update:

* login should be blocked

Posting history should store **last two posting locations**.

---

## 4.9 Password Renewal

Every **12 months** user must change login password.

---

## 4.10 Admin Controls

Admin panel should allow:

* viewing user details
* removing users
* retaining removed user data for records

Admin should have access to:

* confidential fields
* home district information

---

# 5. Future Feature

## UPI Emergency Contribution System

In emergency situations the system should allow:

* collection of funds via UPI
* automatic generation of contributor list

This feature is **not required for MVP**.

---

# 6. Data Model

## Users Table

Fields:

id
name
mobile_number
user_id
password_hash
mpin
reference_user_id
selfie_url
home_district
posting_district
posting_location
appointment_date
role
device_id
last_updated
is_active

---

## Posting History

Fields:

id
user_id
posting_location
start_date
end_date

---

## Emergency Alerts

Fields:

id
user_id
timestamp
location
message

---

# 7. Application Architecture

Use **clean architecture**.

Suggested folder structure:

lib

core
constants
utils

models
user_model
posting_model

services
auth_service
storage_service
member_service

screens
login_screen
registration_screen
dashboard_screen
member_search_screen
member_profile_screen
emergency_screen

widgets
member_card
search_bar
contact_buttons

main.dart

---

# 8. UI Screens

Required screens:

Splash Screen
Login Screen
Registration Screen
Selfie Upload Screen
Dashboard Screen
Member Search Screen
Member Profile Screen
Emergency Alert Screen
Settings Screen

---

# 9. Build Process

Steps to generate APK:

1. install Flutter
2. create Flutter project
3. integrate generated code
4. run project
5. build release APK

Command:

flutter build apk --release

Output location:

build/app/outputs/flutter-apk/app-release.apk

---

# 10. Distribution Strategy

APK will be distributed through:

GitHub Releases

Repository structure:

project repository
source code
APK release

Users download APK directly and install.

---

# 11. Security Considerations

Because the system contains sensitive information:

Recommended safeguards:

* encrypted local storage
* device validation
* screenshot blocking
* authentication checks
* secure communication with backend (future)

---

# 12. Development Priority

Priority order for implementation:

1 registration system
2 login system
3 member directory
4 contact features
5 emergency alert
6 posting history
7 screenshot protection
8 device binding
9 admin controls

---

# 13. Expected Output

The system should produce:

Flutter mobile application
Android APK build
clean folder architecture
maintainable codebase

---

# 14. Long Term Vision

This application can evolve into a **secure internal communication network** with:

* real-time alerts
* verified member registry
* emergency response coordination
* secure information sharing
* financial support coordination

---

End of project plan.
