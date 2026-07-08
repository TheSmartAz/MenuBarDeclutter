# MenuBarDeclutter

MenuBarDeclutter is a native macOS 26.0+ menu bar decluttering app built with Swift, AppKit, and SwiftUI.

The app is privacy-first and local-only. Basic Mode does not require Accessibility, Screen Recording, Apple Events, Input Monitoring, network access, telemetry, cloud sync, or ScreenCaptureKit.

## Current Status

The active release line is `v0.1.10`, build `11`.

- Stable core: Basic expand, collapse, toggle, reveal-all, auto-rehide, hover reveal, Launch at Login, guided manual arrange, diagnostics, backup/restore, recovery, and Safe Mode.
- Preview features: Pro Accessibility Discovery, Find Icon, Second Bar, Accurate Icons, Workspaces, Function Bar, Set Builder, Groups, Info Strip, Profiles, Smart Triggers, Dynamic Hotkeys, Private Access, App Intents, URL automation, and import/export workflows.
- Labs and Experimental: Menu Bar Spacing Labs and Assisted Move / Icon Moving.
- Out of scope for now: Developer ID signing, notarization, public distribution, network/cloud sync, telemetry, Apple Events control, Input Monitoring, and stable automated physical icon moving.

## Project

- Xcode project: `MenuBar-Manager.xcodeproj`
- Canonical scheme: `MenuBarDeclutter`
- Compatibility scheme: `MenuBar-Manager`
- App target/product/display name: `MenuBarDeclutter`
- Platform: macOS 26.0+

## Build And Test

Start by checking available schemes:

```sh
xcodebuild -list
```

Common local commands:

```sh
scripts/build_debug.sh
scripts/run_logic_tests.sh
scripts/test.sh
scripts/qa_preflight.sh
scripts/verify_privacy_boundary.sh
```

Direct Xcode commands:

```sh
xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO
xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests -enableCodeCoverage NO
```

Release dry-run commands:

```sh
scripts/build_release.sh
scripts/build_release.sh --dry-run
scripts/build_release.sh --dry-run --install --verify-installed
```

Release builds are local dry runs by default. Developer ID export and notarization are intentionally not configured at this stage.

## Docs

- Project summary: `docs/project-summary.md`
- Docs index: `docs/README.md`
- Architecture overview: `docs/architecture/architecture-overview.md`
- Privacy boundary: `docs/privacy/privacy-boundary.md`
- QA process: `docs/testing/qa-process.md`
- Manual QA: `docs/testing/manual-qa.md`
- Release notes: `docs/release/v0.1.10-release-notes.md`
- Known limitations: `docs/release/v0.1.10-known-limitations.md`
