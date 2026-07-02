# AGENTS.md

Guidance for coding agents working in this repository.

## Project Overview

- Product/app name: `MenuBarDeclutter`.
- Current Xcode project in this checkout: `MenuBar-Manager.xcodeproj`.
- Current canonical scheme reported by `xcodebuild -list`: `MenuBarDeclutter`.
- Deprecated compatibility scheme retained: `MenuBar-Manager`.
- Current app target/product/wrapper/executable/bundle identity: `MenuBarDeclutter`.
- Current app display name: `MenuBarDeclutter` via the explicit Info.plist at `Config/MenuBarDeclutter-Info.plist`.
- Target platform: native macOS 26.0+ only.
- Language and frameworks: Swift, AppKit, and SwiftUI.
- Current signing/distribution stance: this app is not using an Apple Developer ID for code signing, notarization, or distribution at this stage. Reconsider this later only when explicitly requested.
- Primary goal: build a privacy-first macOS menu bar decluttering utility similar to Hidden Bar / Dozer first, then add selected Bartender-like Pro features.

Prefer the canonical `MenuBarDeclutter` commands below. The `MenuBar-Manager` scheme remains only as a deprecated compatibility fallback during the temporary naming transition.

## Phase 0 Baseline

Phase 0 has been implemented in this checkout.

- SwiftUI app lifecycle is in `MenuBar-Manager/App/MenuBarDeclutterApp.swift`.
- AppKit lifecycle and service ownership start in `MenuBar-Manager/App/AppDelegate.swift` and `MenuBar-Manager/App/AppEnvironment.swift`.
- The temporary menu bar item is implemented in `MenuBar-Manager/StatusBar/`.
- Settings and diagnostics UI are implemented in `MenuBar-Manager/Settings/`.
- Core settings, diagnostics, and path helpers are implemented in `MenuBar-Manager/Core/`.
- Phase summary: `docs/project-summary.md`.
- Detailed progress log: `docs/progress/PROGRESS-phase-0.md`.
- Architecture notes: `docs/architecture/architecture-overview.md`.
- Manual QA and macOS 26 matrix: `docs/testing/`.

Phase 0 deliberately does not implement real hiding, hotkeys, auto-hide, Accessibility, Screen Recording, Apple Events, Input Monitoring, search, network behavior, or a second bar.

## Hard Constraints

1. Target macOS 26.0+ only. Do not add compatibility branches or fallback code for macOS 13, 14, or 15.
2. Use Swift + AppKit + SwiftUI.
3. Use AppKit `NSStatusItem` for all real menu bar status item control.
4. Use SwiftUI for Settings, onboarding, diagnostics, search panels, second bar UI, and profile UI.
5. Do not use Electron.
6. Do not use private APIs.
7. Do not copy GPL or source-available code from Ice, Thaw, SaneBar, or similar projects.
8. Basic Mode must not request Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.
9. Pro Mode must be opt-in and must degrade gracefully if permissions are missing.
10. Keep Basic Mode fully usable even if all Pro features are disabled or fail.
11. Prefer small service classes over a massive `AppDelegate`.
12. Add unit tests for pure logic.
13. Add manual QA docs for system-level behavior that cannot be unit tested.
14. Use modern Swift concurrency where useful, but keep UI work on `MainActor`.
15. If modifying the Xcode project, ensure every new Swift file is added to the correct app or test target.
16. Run `xcodebuild build` and/or `xcodebuild test` where available and report exact results.
17. Do not configure, require, or assume Apple Developer ID signing/notarization for this app right now. Developer ID distribution may be considered later, but is out of scope until explicitly requested.

## Architecture Guidelines

- Keep menu bar control in focused AppKit services built around `NSStatusItem`.
- Keep SwiftUI views declarative and limited to app UI surfaces such as Settings, onboarding, diagnostics, search, profile, and second bar experiences.
- Split behavior into small services, models, coordinators, and view models instead of growing a central app delegate.
- Isolate pure logic from macOS system integration so it can be unit tested.
- Mark UI-facing types or methods with `@MainActor` when they touch AppKit, SwiftUI state, or observable UI models.
- Prefer async/await and structured concurrency for asynchronous work, but avoid adding concurrency where a simple synchronous flow is clearer.
- Treat permission-dependent Pro features as separate capabilities behind explicit user opt-in.

## Privacy And Permissions

- Basic Mode is the default and must remain fully usable without sensitive permissions.
- Do not request Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access from Basic Mode.
- Pro Mode may use elevated permissions only after clear opt-in.
- If a Pro permission is denied, missing, revoked, or unavailable, show a graceful degraded state and keep Basic Mode working.
- Avoid network calls unless a feature explicitly requires them and the user has opted into that feature.
- Store only the minimum data needed for functionality.

## Implementation Rules

- Do not use private macOS APIs, reverse-engineered APIs, or fragile system introspection.
- Do not port, copy, or closely adapt GPL/source-available implementations from Ice, Thaw, SaneBar, or similar menu bar utilities.
- Follow the existing project style and naming conventions unless a change is needed for clarity.
- Keep new files in the appropriate app, unit test, or UI test target.
- When editing `project.pbxproj`, make the smallest possible target membership change and verify with `xcodebuild`.
- Keep behavior-specific manual QA notes under a docs location when system behavior cannot be verified by unit tests.

## Testing Expectations

- Add unit tests for pure logic such as profile selection, visibility rules, preference migration, permission state modeling, sorting, filtering, and feature gating.
- Use UI tests only where they add real confidence; many menu bar behaviors will require manual QA.
- Add or update manual QA documentation for `NSStatusItem`, permissions, launch behavior, Settings UI, and any Pro feature that depends on macOS system state.
- Before finishing implementation work, run the most relevant available command and report the exact command and result.

## Build And Test Commands

First inspect available schemes:

```sh
xcodebuild -list
```

Canonical commands:

```sh
xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build
xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
```

Deprecated compatibility fallback commands:

```sh
xcodebuild -scheme MenuBar-Manager -destination 'platform=macOS' build
xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'
```

## Definition Of Done

- The change respects the Basic Mode and Pro Mode permission boundary.
- Basic Mode still works when Pro functionality is unavailable.
- New Swift files are added to the correct Xcode target.
- Pure logic has unit test coverage where practical.
- System-level behavior has manual QA notes when it cannot be automated.
- Relevant `xcodebuild` commands have been run, or any inability to run them is clearly reported.
