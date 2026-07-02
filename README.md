# MenuBarDeclutter

MenuBarDeclutter is a native macOS 26.0+ menu bar decluttering utility built with Swift, AppKit, and SwiftUI.

The current release target is `v0.1.7`. It completes the Preview track for Workspaces, Function Bar, Set Builder, and the local-only Info Strip MVP while keeping Basic Mode as the stable product core.

## Product Promise

- Hide clutter without sensitive permissions, arrange icons safely, find hidden items when needed, and recover if layout breaks.
- Basic Mode works without Accessibility, Screen Recording, Apple Events permission or other-app control, Input Monitoring, network access, telemetry, cloud sync, or ScreenCaptureKit.
- Pro Mode is opt-in. It can use Accessibility metadata only after the user enables Pro Mode, enables Accessibility Discovery, and explicitly grants macOS Accessibility permission.
- Labs and Experimental features are off by default and must fail closed when permissions or gates are missing.

## Intended Stable In v0.1.7 Pending Physical QA

- Basic expand, collapse, toggle, reveal-all, and always-hidden reveal.
- Auto-rehide, hover reveal, and global visibility hotkey.
- Launch at Login.
- Privacy-safe diagnostics export.
- Local MenuBarDeclutter backup/restore mechanics.
- Safe Mode, recovery, and reset layout.
- Guided Manual Arrange with normal macOS Command-drag.
- Pro Accessibility Discovery gating and degraded states.

These are the intended stable product surfaces for `v0.1.7`. Current release completion is scoped to the single-screen UI QA gates tracked in `docs/testing/manual-v0.1.7-results.md`, including workspace preview behavior and Info Strip preview behavior on the built-in display. External multi-display QA is deferred to a future hardware follow-up and is not a current release blocker.

## Preview, Labs, Or Experimental

- Preview: Workspaces, Function Bar, Set Builder, Info Strip, Find Icon, Second Bar, Placement Planner, New Item Inbox, Crowded Reveal Rescue, Profiles, Smart Triggers, Dynamic Hotkeys, Private Access, groups, App Intents automation, URL automation, and broader import/export migration assistant workflows.
- Labs: Menu Bar Spacing Labs.
- Experimental: Assisted Move / Icon Moving.
- Deferred: ScreenCaptureKit visual capture, Screen Recording, Apple Events scripting, Input Monitoring, network/cloud sync, telemetry, broad third-party import promises, and stable automated icon moving.

## User Docs

- Workspaces: `docs/features/workspaces-v0.1.7-preview.md`
- Function Bar: `docs/features/function-bar-v0.1.7-preview.md`
- Info Strip: `docs/features/info-strip-v0.1.7-preview.md`
- Workspaces track summary: `docs/features/workspaces-function-bar-info-strip-v0.1.7.md`
- Arrange: `docs/features/arrange-v0.1.3.md`
- Find & Rescue: `docs/features/find-rescue-v0.1.3.md`
- Second Bar: `docs/features/second-bar-v0.1.3.md`
- Placement Planner: `docs/features/placement-planner-v0.1.3.md`
- Assisted Move: `docs/features/assisted-move-v0.1.3-experimental.md`
- New Item Inbox: `docs/features/new-item-inbox-v0.1.3.md`
- Shortcuts: `docs/features/shortcuts-v0.1.3.md`
- Backup and restore: `docs/support/backup-restore.md`
- Settings overview: `docs/support/settings-overview.md`
- Lost icons recovery: `docs/support/i-cant-find-my-icons.md`
- Troubleshooting: `docs/support/troubleshooting.md`
- Permissions: `docs/support/permissions.md`
- Safe Mode: `docs/support/safe-mode.md`
- Uninstall: `docs/support/uninstall.md`
- Release notes: `docs/release/v0.1.7-release-notes.md`
- Known limitations: `docs/release/v0.1.7-known-limitations.md`
- Release checklist: `docs/release/v0.1.7-release-checklist.md`

## Build And Test

```sh
xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build
xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
scripts/qa_preflight.sh
scripts/verify_privacy_boundary.sh
```

Current release validation uses `scripts/qa_preflight.sh` for its `build-for-testing` plus `test-without-building` lanes. Direct `xcodebuild test` is still useful, but this macOS/Xcode runner has intermittently failed before tests attach.

## Release Dry Run

```sh
scripts/build_release.sh --dry-run
scripts/build_release.sh --dry-run --install --verify-installed
```

Dry-run release builds create local `v0.1.7` artifacts without Developer ID export, notarization credentials, uploads, or network access.

Real Developer ID notarization uses `notarytool` credentials supplied by keychain profile or environment variables and requires an installed Developer ID Application signing certificate. No credentials are stored in this repository.
