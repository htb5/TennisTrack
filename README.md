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

## Option B: No-local-Mac iOS build artifacts with Codemagic (no ASC)

This follows your exact workflow:
- Code on Windows and push to GitHub.
- Codemagic uses a cloud Mac runner to build iOS.
- No App Store Connect integration is required.

### Prerequisites

- A GitHub repository for this project.
- Codemagic account linked to GitHub.

### Setup steps

1. In Codemagic UI:
   - When adding the app, select configuration from `codemagic.yaml`.
   - Start workflow `ios_sideload_ipa` for iPhone sideloading.
   - Start workflow `ios_simulator_ci` for simulator-only CI validation.

### What the workflows do

- `ios_sideload_ipa`:
  - Installs XcodeGen and generates `TennisBallTracker.xcodeproj`.
  - Builds an unsigned `Release-iphoneos` app.
  - Packages `TennisBallTracker-unsigned.ipa` as an artifact.
- `ios_simulator_ci`:
  - Builds an unsigned iOS Simulator `.app` artifact for CI checks.

### Important limitation

- The sideload IPA is unsigned; deploy it with a sideload tool (for example AltStore or Sideloadly), which signs at install time with your Apple ID.
- Simulator artifacts cannot be installed directly on a physical iPhone.

### Scanner compatibility note

- The repository includes an `ios/` project structure so Codemagic app scanning detects it as a mobile repository.
- Publishing still uses the root `codemagic.yaml` workflows.

## Notes on iPhone behavior

- Camera and notifications require user permission.
- For best tracking, mount phone on tripod and keep court lines visible.
- Replay is in-memory and keeps recent seconds only.

## Important limits

- PWA path is fully free and does not need Apple Developer membership.
- No-ASC Codemagic path can produce unsigned sideload IPA artifacts, not a TestFlight/App Store release.
- If you only need browser install, use Option A (PWA).

## Next improvements

1. Replace color detector with an on-device ML model.
2. Add interactive court calibration (tap court corners).
3. Add smoothing/Kalman filter and false-positive suppression.
4. Add replay export/share.
