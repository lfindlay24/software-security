# MFA Implementation Deployment Guide

## Backend Functions Deployment

You'll need to deploy the following Google Cloud Functions:

### 1. MFA Setup Function
```bash
cd "backend/google-cloud-functions/mfa"
gcloud functions deploy setup-mfa \
  --runtime python39 \
  --trigger-http \
  --allow-unauthenticated \
  --source . \
  --entry-point setup_mfa \
  --requirements-file requirements.txt
```

### 2. Complete MFA Setup Function
```bash
gcloud functions deploy complete-mfa-setup \
  --runtime python39 \
  --trigger-http \
  --allow-unauthenticated \
  --source . \
  --entry-point complete_mfa_setup \
  --requirements-file complete_requirements.txt
```

### 3. TOTP Verification Function
```bash
gcloud functions deploy verify-totp \
  --runtime python39 \
  --trigger-http \
  --allow-unauthenticated \
  --source . \
  --entry-point verify_totp \
  --requirements-file verify_requirements.txt
```

### 4. Check MFA Status Function
```bash
gcloud functions deploy check-mfa-status \
  --runtime python39 \
  --trigger-http \
  --allow-unauthenticated \
  --source . \
  --entry-point check_mfa_status \
  --requirements-file check_requirements.txt
```

### 5. Update Login Function
Redeploy the existing login function with the updated code that returns MFA status.

## Flutter App

The Flutter app now includes:

1. **MFA Setup Page** (`mfa_setup_page.dart`) - Shows QR code and manual secret entry
2. **TOTP Verification Page** (`totp_verification_page.dart`) - Handles 2FA code entry
3. **Updated Login Flow** - Checks MFA status and routes accordingly
4. **Updated Registration Flow** - Redirects new users to MFA setup
5. **MFA Management in Vault** - Users can set up MFA from the vault menu

## How It Works

### New User Registration:
1. User creates account
2. Redirected to MFA setup page
3. Can scan QR code or manually enter secret
4. Verifies setup with 6-digit code
5. MFA is enabled and user goes to vault

### Existing User Login:
1. User enters username/password
2. System checks if MFA is enabled
3. If enabled: redirected to TOTP verification
4. If not enabled: goes directly to vault

### MFA Setup Process:
1. Backend generates random base32 secret
2. Creates QR code URI for authenticator apps
3. User scans with Google Authenticator, Authy, etc.
4. User enters current 6-digit code to verify
5. Backend confirms code and enables MFA

## Security Features

- **TOTP (Time-based One-Time Password)** using industry standard
- **Base32 encoded secrets** for compatibility with authenticator apps
- **Time window validation** (30-second windows with 1-window tolerance)
- **Secure secret storage** in Firestore
- **Separation of temporary and permanent secrets** during setup
- **Skip option** for users who want to set up MFA later

## Authenticator App Compatibility

The implementation works with popular authenticator apps:
- Google Authenticator
- Microsoft Authenticator
- Authy
- 1Password
- LastPass Authenticator
- And any TOTP-compatible app

## URLs to Update in Frontend

Make sure to update these URLs in the frontend code to match your deployed functions:

- `https://setup-mfa-271131837642.us-west1.run.app`
- `https://complete-mfa-setup-271131837642.us-west1.run.app`
- `https://verify-totp-271131837642.us-west1.run.app`
- `https://check-mfa-status-271131837642.us-west1.run.app`
