# MenuBarDeclutter

MenuBarDeclutter is a native macOS 26.0+ menu bar decluttering utility built with Swift, AppKit, and SwiftUI.

The current release target is `v0.1.10`. This is a release-hardening checkpoint for the v0.1.9 source/docs baseline: build, test, privacy, manual QA, dry-run packaging, and installed-app verification are the focus. Basic Mode remains the stable product core.

## Product Promise

- Hide clutter without sensitive permissions, arrange icons safely, find hidden items when needed, and recover if layout breaks.
- Basic Mode works without Accessibility, Screen Recording, Apple Events permission or other-app control, Input Monitoring, network access, telemetry, cloud sync, or ScreenCaptureKit.
- Pro metadata remains gated by macOS Accessibility. The app never prompts automatically; after the user grants macOS Accessibility permission, private discovery surfaces default on and Basic Mode still works if permission is missing or revoked.
- Labs and Experimental features are off by default and must fail closed when permissions or gates are missing.

## Stable Surfaces Under v0.1.10 Verification

- Basic expand, collapse, toggle, reveal-all, and always-hidden reveal.
- Auto-rehide, hover reveal, and global visibility hotkey.
- Launch at Login.
- Privacy-safe diagnostics export.
- Local MenuBarDeclutter backup/restore mechanics.
- Safe Mode, recovery, and reset layout.
- Guided Manual Arrange with normal macOS Command-drag.
- Pro Accessibility Discovery gating and degraded states.

These are the intended stable product surfaces for `v0.1.10`. Current release completion is scoped to the QA gates tracked in the v0.1.10 manual QA templates. External multi-display QA remains documented separately and is not claimed complete until it is run.

## Preview, Labs, Or Experimental

- Preview: Workspaces, Function Bar, Set Builder, Info Strip, Workspace Integration, Find Icon, Second Bar, Placement Planner, New Item Inbox, Crowded Reveal Rescue, Profiles, Smart Triggers, Dynamic Hotkeys, Private Access, groups, App Intents automation, URL automation, and broader import/export migration assistant workflows.
- Labs: Menu Bar Spacing Labs.
- Experimental: Assisted Move / Icon Moving.
- Deferred: ScreenCaptureKit visual capture, Screen Recording, Apple Events scripting, Input Monitoring, network/cloud sync, telemetry, broad third-party import promises, and stable automated icon moving.

## User Docs

- Workspaces: `docs/features/workspaces-v0.1.10-preview.md`
- Function Bar: `docs/features/function-bar-v0.1.10-preview.md`
- Set Builder: `docs/features/set-builder-v0.1.10-preview.md`
- Linked Groups: `docs/features/linked-groups-v0.1.10-preview.md`
- Info Strip: `docs/features/info-strip-v0.1.10-preview.md`
- Workspace Integration: `docs/features/workspace-integration-v0.1.10-preview.md`
- Arrange: `docs/features/arrange-v0.1.10.md`
- Find & Rescue: `docs/features/find-rescue-v0.1.10.md`
- Second Bar: `docs/features/second-bar-v0.1.3.md`
- Placement Planner: `docs/features/placement-planner-v0.1.3.md`
- Assisted Move: `docs/features/assisted-move-v0.1.3-experimental.md`
- New Item Inbox: `docs/features/new-item-inbox-v0.1.3.md`
- Shortcuts: `docs/features/shortcuts-v0.1.3.md`
- Workspaces support: `docs/support/workspaces.md`
- Function Bar support: `docs/support/function-bar.md`
- Info Strip support: `docs/support/info-strip.md`
- Set Builder support: `docs/support/set-builder.md`
- Linked Groups support: `docs/support/linked-groups.md`
- Backup and restore: `docs/support/backup-restore.md`
- Settings overview: `docs/support/settings-overview.md`
- Lost icons recovery: `docs/support/i-cant-find-my-icons.md`
- Troubleshooting: `docs/support/troubleshooting.md`
- Permissions: `docs/support/permissions.md`
- Safe Mode: `docs/support/safe-mode.md`
- Uninstall: `docs/support/uninstall.md`
- Release notes: `docs/release/v0.1.10-release-notes.md`
- Known limitations: `docs/release/v0.1.10-known-limitations.md`
- Release checklist: `docs/release/v0.1.10-release-checklist.md`

## Build And Test

```sh
scripts/build_debug.sh
scripts/run_logic_tests.sh
scripts/test.sh
scripts/qa_preflight.sh
scripts/verify_privacy_boundary.sh
```

The default local build scripts use CI-style ad-hoc/no-account signing overrides (`CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO`) so a personal Apple signing account is not required. `scripts/test.sh` uses the project's local signing defaults and runs the hosted unit lane by default. Run `scripts/test.sh --ui` when you explicitly want the local UI runner.

For pure logic coverage during local development, use `scripts/run_logic_tests.sh`; it builds `MenuBarDeclutterLogicTests` and runs the resulting bundle directly with `xcrun xctest`, avoiding app-hosted LaunchServices attachment.

Direct Xcode equivalents:

```sh
xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO
xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests -enableCodeCoverage NO
```

Current release validation uses `scripts/qa_preflight.sh` for its `build-for-testing` plus split `test-without-building` lanes. Direct full-scheme `xcodebuild test` is still useful for diagnosis; use the focused unit lane when UI automation is not part of the pass.

## Release Dry Run

```sh
scripts/build_release.sh
scripts/build_release.sh --dry-run
scripts/build_release.sh --dry-run --install --verify-installed
```

Release builds are dry-run by default and create local `v0.1.10` artifacts without Developer ID export, notarization credentials, uploads, or network access.

Developer ID export/notarization is intentionally out of scope for the current project stance. The future path is behind explicit script opt-in and should only be used after Developer ID distribution is requested.
