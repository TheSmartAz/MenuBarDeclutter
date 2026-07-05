# MenuBarDeclutter Alpha RC Release Notes

Version:
Build:
Date:

Note: if this is based on a dated validation run, record the exact commit and avoid reusing stale test counts or version numbers from older Alpha RC notes.

## Highlights

- Privacy-first Basic Mode menu bar decluttering with no sensitive permissions.
- Opt-in Pro Mode for Accessibility-based discovery, Find Icon, Second Bar, and explicit icon moving.
- Health checks, targeted recovery, Safe Mode, and crash-marker recovery.
- Alpha hardening: canonical `MenuBarDeclutter` scheme, privacy verification, diagnostics filtering, automation pause, and QA scripts.

## Privacy

Basic Mode requires no Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.

Pro Mode uses Accessibility only after explicit opt-in and explicit permission request. No screenshots, screen contents, telemetry, cloud sync, or network access are used.

## Experimental

Icon moving is experimental. It uses simulated Command-drag and may fail depending on macOS, display layout, and third-party menu bar apps. It is disabled by default.

Smart triggers are opt-in and can be paused globally.

## Known Limitations

Include or link `docs/release/alpha-rc-known-limitations.md`.

## Validation Summary

- `xcodebuild test`:
- Privacy verification:
- Manual QA:
- Codesign:
- Notarization:

## Installation Notes

Launch at Login must be tested from an installed, signed app. Xcode-run behavior may differ from installed behavior.
