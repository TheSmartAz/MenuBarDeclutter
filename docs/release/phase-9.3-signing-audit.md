# Phase 9.3 Signing Audit

Date: 2026-06-28
Project: `MenuBar-Manager.xcodeproj`
Canonical scheme: `MenuBarDeclutter`
Configuration audited: `Release`

## Commands Run

```sh
xcodebuild -list
xcodebuild -showBuildSettings -scheme MenuBarDeclutter -configuration Release
security find-identity -v -p codesigning || true
```

## Results

| Item | Result |
| --- | --- |
| Bundle identifier | `Yongjun-Zhang.MenuBarDeclutter` |
| Product name | `MenuBarDeclutter` |
| Executable name | `MenuBarDeclutter` |
| Wrapper extension | `.app` |
| LSUIElement | `true` in `Config/MenuBarDeclutter-Info.plist` |
| URL scheme | `menubardeclutter://` |
| Deployment target | macOS `26.0` |
| Hardened Runtime | `ENABLE_HARDENED_RUNTIME = YES` |
| App Sandbox | `ENABLE_APP_SANDBOX = YES` |
| Entitlements file | No explicit `CODE_SIGN_ENTITLEMENTS`; Xcode injects base sandbox entitlements |
| Network entitlements | `ENABLE_INCOMING_NETWORK_CONNECTIONS = NO`; `ENABLE_OUTGOING_NETWORK_CONNECTIONS = NO`; no network entitlement string found |
| Accessibility usage | Pro Mode docs/UI only; no Basic Mode permission request |
| ScreenCaptureKit linkage | Absent by source/release verification |
| Screen Recording usage string | Absent |
| Apple Events usage string | Absent |
| Input Monitoring usage string | Absent |
| Code signing identity | Apple Development identity found: `Apple Development: emailyongjunzhang@gmail.com (834922P6J6)` |
| Developer ID Application identity | Not found in local keychain audit |
| Team ID | `LT2MVX436A` from build settings |
| Notarization credentials | No `NOTARYTOOL_*`, `APPLE_ID`, `TEAM_ID`, or app-specific password environment variables were present |

## Credential Gap

Installed-app dry-run release validation is available now. Real notarization is blocked until both are configured:

- A valid Developer ID Application certificate in the keychain.
- A `notarytool` credential path, preferably a keychain profile created with `xcrun notarytool store-credentials`.

No secrets should be committed to the repository.

## Privacy Boundary

This audit did not introduce new permissions. Basic Mode remains permission-free. Pro Mode remains opt-in and Accessibility-only. ScreenCaptureKit, Screen Recording, Apple Events, Input Monitoring, network access, telemetry, and cloud sync remain excluded.
