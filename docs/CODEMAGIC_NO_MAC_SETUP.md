# Codemagic No-Mac Setup (No App Store Connect)

This project supports building iOS artifacts on Codemagic cloud Macs from Windows without App Store Connect.

## 1. Add the repository in Codemagic

1. Push your code to GitHub.
2. In Codemagic, add the app and use repository configuration (`codemagic.yaml`).

## 2. Run the sideload IPA workflow

1. Start workflow `ios_sideload_ipa`.
2. The workflow will:
   - Install XcodeGen
   - Generate `TennisBallTracker.xcodeproj`
   - Build an unsigned iOS device app (`Release-iphoneos`)
   - Package `TennisBallTracker-unsigned.ipa`
   - Publish logs and IPA artifact

## 3. Retrieve artifacts

1. Open the build result in Codemagic.
2. Download artifact:
   - `TennisBallTracker-unsigned.ipa`

## 4. Install to iPhone (sideload)

1. Use AltStore, Sideloadly, or a similar sideload tool on your computer.
2. Select `TennisBallTracker-unsigned.ipa`.
3. Sign during install with your Apple ID in the sideload tool.

## Notes

- No App Store Connect setup is required.
- This workflow does not upload to TestFlight and does not produce an App Store distributable IPA.
- `ios_simulator_ci` remains available for simulator-only CI checks.
