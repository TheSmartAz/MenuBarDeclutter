# MenuBarDeclutter

MenuBarDeclutter is a native macOS 26.0+ menu bar decluttering utility built with Swift, AppKit, and SwiftUI.

The current release target is `v0.1.1`. This release line hardens the privacy-first Basic Mode core and release tooling; it is not `v0.2`.

## Product Promise

- Basic Mode works without Accessibility, Screen Recording, Apple Events, Input Monitoring, network access, telemetry, cloud sync, or ScreenCaptureKit.
- Pro Mode is opt-in. It can use Accessibility metadata only after the user enables Pro Mode, enables Accessibility Discovery, and explicitly grants macOS Accessibility permission.
- Labs and Experimental features are off by default and must fail closed when permissions or gates are missing.

## Stable In v0.1.1

- Basic expand, collapse, toggle, reveal-all, and always-hidden reveal.
- Auto-rehide, hover reveal, and global visibility hotkey.
- Launch at Login.
- Privacy-safe diagnostics export.
- Safe Mode, recovery, and reset layout.
- Pro Accessibility Discovery gating.
- Find Icon search with reveal/highlight only.
- Second Bar metadata/icon browsing.
- Conservative local profile dry-run/apply.

## Preview, Labs, Or Experimental

- Preview: Smart Triggers, Dynamic Hotkeys, Private Access, group status items, App Intents automation, import/export migration assistant, and crowded reveal rescue automation.
- Labs: Menu Bar Spacing Labs.
- Experimental: Icon Moving.
- Deferred: ScreenCaptureKit visual capture, Screen Recording, Apple Events scripting, Input Monitoring, network/cloud sync, telemetry, and broad third-party import promises.

## User Docs

- Basic Mode contract: `docs/features/basic-mode-v0.1.1-contract.md`
- Pro Mode boundary: `docs/features/pro-mode-v0.1.1-boundary.md`
- Privacy claims: `docs/privacy/v0.1.1-privacy-claims.md`
- Feature gates: `docs/release/v0.1.1-feature-gates.md`
- Troubleshooting: `docs/support/troubleshooting.md`
- Permissions: `docs/support/permissions.md`
- Safe Mode: `docs/support/safe-mode.md`
- Uninstall: `docs/support/uninstall.md`

## Build And Test

```sh
xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build
xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
scripts/verify_privacy_boundary.sh
```

## Release Dry Run

```sh
scripts/build_release.sh --dry-run
scripts/build_release.sh --dry-run --install --verify-installed
```

Dry-run release builds create local `v0.1.1` artifacts without Developer ID export, notarization credentials, uploads, or network access.

Real Developer ID notarization uses `notarytool` credentials supplied by keychain profile or environment variables. No credentials are stored in this repository.
