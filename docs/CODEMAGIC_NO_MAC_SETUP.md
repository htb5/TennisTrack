# Codemagic No-Mac Setup

This project supports building iOS on Codemagic cloud Macs from Windows.

## 1. Create App Store Connect API key (browser)

1. Open App Store Connect.
2. Go to `Users and Access -> Integrations -> App Store Connect API`.
3. Create key and save:
   - `Issuer ID`
   - `Key ID`
   - `.p8` private key file (download once)

## 2. Add integration in Codemagic

1. Open Codemagic `Team settings -> Integrations -> Developer Portal`.
2. Add App Store Connect integration with `Issuer ID`, `Key ID`, `.p8`.
3. Name the integration:
   - `CM_APPLE_KEY_NAME`

## 3. Create app record in App Store Connect

1. Create your app entry if missing.
2. Copy the app's numeric Apple ID.

## 4. Update `codemagic.yaml`

In workflow `ios_no_mac_testflight`:
- Keep integration as:
  - `app_store_connect: CM_APPLE_KEY_NAME`
- Replace:
  - `APP_STORE_APPLE_ID: "0000000000"`

## 5. Run workflow

1. Push to GitHub.
2. In Codemagic, run `ios_no_mac_testflight`.
3. Workflow outputs:
   - Signed IPA artifact
   - TestFlight upload

## Notes

- Automatic code signing is handled by Codemagic when App Store Connect integration is configured.
- This flow requires Apple Developer Program membership.
