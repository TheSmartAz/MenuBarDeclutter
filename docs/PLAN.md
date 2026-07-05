# MenuBarDeclutter Plan

Last reviewed: 2026-07-05

MenuBarDeclutter is a native macOS 26.0+ menu bar decluttering utility built with Swift, AppKit, and SwiftUI. The current release line is `v0.1.10` build `11`. It is a release-hardening checkpoint, not a new feature promotion.

## Current Product Shape

Stable Basic Mode is the product core:

- App-owned `NSStatusItem` control and separator items provide expand, collapse, reveal all, and always-hidden reveal.
- Basic hiding, Guided Manual Arrange, Launch at Login, diagnostics, backup/restore, health, recovery, and Safe Mode remain usable without sensitive permissions.
- Basic Mode must not request Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.

Preview surfaces are opt-in or gated:

- Pro Accessibility Discovery, Find Icon, Second Bar, Workspaces, Workspace Integration, Function Bar, Set Builder, linked/detached Groups, Info Strip, Placement Planner, New Item Inbox, Crowded Reveal Rescue, Profiles, Smart Triggers, Dynamic Hotkeys, Private Access, App Intents, URL automation, import/export, and Accurate Icons.
- Preview features must degrade gracefully when Pro Mode, Accessibility Discovery, Accessibility permission, Screen Recording, Labs gates, or Private Access gates are unavailable.

Labs and Experimental:

- Menu Bar Spacing remains Labs.
- Assisted Move / Icon Moving remains Experimental, disabled by default, and user-triggered only.

## Active Work Priorities

1. Keep Basic Mode reliable and permission-free.
2. Keep the current v0.1.10 docs, support docs, release docs, and QA docs aligned with source.
3. Record hardware-only QA honestly: external displays, notch behavior, hands-on Safe Mode launch, physical Command-drag placement, and real permission prompts can remain `PARTIAL` or `BLOCKED` when the local environment cannot exercise them.
4. Keep Preview, Labs, and Experimental surfaces labeled clearly in code, docs, release notes, and support docs.
5. Treat Developer ID signing, notarization, stapling, public distribution, network/cloud features, and private/offscreen menu bar capture as out of scope until explicitly requested.

## Implementation Boundaries

- Use Swift, AppKit, and SwiftUI only.
- Use AppKit `NSStatusItem` for real menu bar status item control.
- Use SwiftUI for Settings, onboarding, diagnostics, search panels, second bar, workspaces, profile, and preview UI.
- Do not use Electron, private APIs, GPL/source-available code from similar utilities, telemetry, analytics, cloud sync, or remote config.
- Keep service ownership in focused classes and coordinators instead of growing `AppDelegate`.
- Add unit tests for pure logic and manual QA docs for system behavior that cannot be automated.

## Current Validation Commands

Canonical project inspection:

```sh
xcodebuild -list
```

Canonical build:

```sh
xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO
```

Focused logic tests:

```sh
scripts/run_logic_tests.sh
```

Current release/risk gates:

```sh
scripts/qa_preflight.sh
scripts/verify_privacy_boundary.sh
scripts/build_release.sh --dry-run --install --verify-installed
scripts/qa_installed_app_smoke.sh --app-path /Applications/MenuBarDeclutter.app
```

Direct full-scheme `xcodebuild test` remains useful, but this local environment has documented Xcode LaunchServices/UI-runner failures before assertions. Use split unit/UI lanes and record exact infra failures when that occurs.
