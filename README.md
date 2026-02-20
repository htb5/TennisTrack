# TennisBallTracker (No-Mac MVP)

Real-time tennis line-call assistant that works on iPhone without Xcode/Mac by using a Progressive Web App (PWA).

## What works now

- Live iPhone camera feed in browser
- Tennis ball centroid tracking (color-based MVP detector)
- Bounce detection from short trajectory history
- IN/OUT call against normalized court polygon
- OUT alert (vibration + beep + web notification)
- Replay of recent buffered frames
- Installable to home screen (PWA)

This is an assistive MVP baseline, not certified Hawk-Eye accuracy.

## Project layout

- `web/index.html`: UI shell
- `web/app.js`: tracking, bounce, in/out, replay logic
- `web/styles.css`: styling
- `web/manifest.webmanifest`: PWA manifest
- `web/sw.js`: service worker cache
- `.github/workflows/deploy-pages.yml`: auto deploy PWA to GitHub Pages
- `.github/workflows/ios-ci.yml`: optional native iOS CI (needs Mac runner)
- `Sources/`, `Tests/`, `project.yml`: optional native iOS scaffold from earlier phase

## Option A: Windows + iPhone setup (free, PWA)

1. Create a GitHub repository and push this folder.
2. In GitHub repository settings:
   - Open `Settings -> Pages`
   - Ensure source is `GitHub Actions`
3. Push to `main`; workflow `.github/workflows/deploy-pages.yml` publishes `web/`.
4. Open the Pages URL on your iPhone in Safari.
5. Use `Share -> Add to Home Screen` to install like an app.
6. Open installed app and tap `Start Camera`.

## Option B: No-local-Mac native iOS build with Codemagic

This follows your exact workflow:
- Code on Windows and push to GitHub.
- Codemagic uses a cloud Mac runner to build iOS.
- Codemagic signs and publishes using App Store Connect API key integration.

### Prerequisites

- Apple Developer Program membership (required for App Store Connect/API key/TestFlight).
- A GitHub repository for this project.
- Codemagic account linked to GitHub.

### Setup steps

1. In App Store Connect (browser):
   - Open `Users and Access -> Integrations -> App Store Connect API`.
   - Create API key and download the `.p8` key once.
2. In Codemagic:
   - Go to `Team settings -> Integrations -> Developer Portal`.
   - Add App Store Connect integration (Issuer ID, Key ID, `.p8` file).
   - Name it exactly as used in `codemagic.yaml`:
     - `CM_APPLE_KEY_NAME`
3. In App Store Connect:
   - Create app record and copy its numeric Apple ID.
4. In `codemagic.yaml`:
   - Replace `APP_STORE_APPLE_ID: "0000000000"` with your app's real Apple ID.
5. In Codemagic UI:
   - Start workflow `ios_no_mac_testflight`.

### What this workflow does

- Installs XcodeGen and generates `TennisBallTracker.xcodeproj`.
- Applies provisioning profiles automatically via Codemagic integration.
- Builds signed `.ipa`.
- Uploads to TestFlight (`submit_to_testflight: true`).

## Notes on iPhone behavior

- Camera and notifications require user permission.
- For best tracking, mount phone on tripod and keep court lines visible.
- Replay is in-memory and keeps recent seconds only.

## Important limits

- PWA path is fully free and does not need Apple Developer membership.
- Native iOS/TestFlight/App Store path needs Apple Developer membership; it is not free forever.
- If you only need personal use without membership, use Option A (PWA).

## Next improvements

1. Replace color detector with an on-device ML model.
2. Add interactive court calibration (tap court corners).
3. Add smoothing/Kalman filter and false-positive suppression.
4. Add replay export/share.
