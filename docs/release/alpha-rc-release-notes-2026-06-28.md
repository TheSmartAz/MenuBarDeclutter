# MenuBarDeclutter Alpha RC Release Notes

Version: 1.0
Build: 1
Date: 2026-06-28
Validated code commit: `a30414e`

## Highlights

- Privacy-first Basic Mode menu bar decluttering with no sensitive permissions.
- Opt-in Pro Mode for Accessibility-based discovery, Find Icon, Second Bar, and explicit icon moving.
- Health checks, targeted recovery, Safe Mode, and crash-marker recovery.
- Alpha hardening: canonical `MenuBarDeclutter` scheme, compatibility `MenuBar-Manager` scheme, privacy verification, diagnostics filtering, automation pause, and QA scripts.

## Privacy

Basic Mode requires no Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.

Pro Mode uses Accessibility only after explicit opt-in and explicit permission request. No screenshots, screen contents, telemetry, cloud sync, or network access are used.

The local Release app passed source/project privacy checks, built-app privacy checks, and a non-interactive runtime `lsof` probe with no network connections.

## Experimental

Icon moving is experimental. It uses simulated Command-drag and may fail depending on macOS, display layout, and third-party menu bar apps. It is disabled by default.

Smart triggers are opt-in and can be paused globally.

## Known Limitations

See `docs/release/alpha-rc-known-limitations.md`.

Key Alpha RC limitations:

- Phase 10 visual icon capture is intentionally not implemented.
- Launch at Login still requires installed signed app validation.
- External display, notch, sleep/wake, and display-disconnect behavior require hands-on hardware QA.
- Real Accessibility grant/revoke and real third-party icon moving require hands-on QA.
- Notarization was not attempted in this pass because no Developer ID notarized distribution artifact was produced.

## Validation Summary

- `xcodebuild -list`: PASS; canonical `MenuBarDeclutter` and deprecated fallback `MenuBar-Manager` schemes are present.
- `xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'`: PASS.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'`: PASS; 203 unit tests + 7 UI executions. Result bundle: `/tmp/MenuBarDeclutter-AlphaRCFull.xcresult`.
- `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'`: PASS; 203 unit tests + 7 UI executions. Result bundle: `/tmp/MenuBarDeclutter-CompatFull.xcresult`.
- `scripts/verify_privacy_boundary.sh`: PASS.
- `scripts/qa_preflight.sh`: PASS.
- Release build: PASS at `build/DerivedData/Build/Products/Release/MenuBarDeclutter.app`.
- `scripts/verify_release_artifact.sh build/DerivedData/Build/Products/Release/MenuBarDeclutter.app`: PASS.
- Basic runtime network probe: PASS; `lsof -nP -i -a -c MenuBarDeclutter` showed no network connections while the Release app was running.
- Manual QA: NOT COMPLETE; see `docs/testing/alpha-rc-qa-run-2026-06-28.md`.
- Notarization: NOT TESTED.

## Installation Notes

Launch at Login must be tested from an installed, signed app. Xcode-run behavior may differ from installed behavior.

Do not publish this Alpha RC until the remaining manual QA blockers in `docs/testing/alpha-rc-qa-run-2026-06-28.md` are passed or explicitly accepted.
