# Project Summary

`MenuBarDeclutter` is a native macOS 26.0+ menu bar utility written in Swift, AppKit, and SwiftUI. Its product direction is privacy-first menu bar decluttering: ship a permission-free Basic Mode similar to Hidden Bar / Dozer, then layer selected Bartender-like power features behind explicit opt-in gates.

The current checkout is far beyond the original Phase 0 skeleton. Phases 0 through 12 are implemented in the source tree, with Phase 9.1-9.5 hardening, Phase 10 layout work, Phase 11 power-user surfaces, and Phase 12 v0.1.1 release-confidence/trust hardening present. Phase 13 is now in progress on the `v0.1.1` line: the shared Command Center router exists, App Intents, URL automation, Dynamic Hotkey execution, Find Icon item actions, Second Bar item actions, advanced status-menu actions, and Private Access Settings explanations route through it, and Settings now explain command availability for Find Icon, Second Bar/Icon Panel, Groups, Profiles, and protected app actions. Focused automated validation, prior full-suite validation, dry-run alpha packaging, installed-app verification, and privacy-boundary checks are documented; the newest full/UI test attempts are currently blocked by XCTest UI runner automation-mode/handoff failures. Public distribution is still blocked by Developer ID notarization credentials and several hands-on macOS system QA gates.

## Current Checkout

- App/product/display identity: `MenuBarDeclutter`.
- Xcode project package: `MenuBar-Manager.xcodeproj`.
- Canonical shared scheme: `MenuBarDeclutter`.
- Deprecated compatibility scheme: `MenuBar-Manager`.
- Local QA fixture scheme: `MenuBarFixtureApp`.
- Main targets: `MenuBarDeclutter`, `MenuBarDeclutterTests`, `MenuBarDeclutterUITests`, and `MenuBarFixtureApp`.
- App bundle ID: `Yongjun-Zhang.MenuBarDeclutter`.
- Version/build in config: `0.1.1 (2)`.
- Deployment target: macOS `26.0`.
- Swift version: `6.0`.
- Runtime style: `LSUIElement` accessory app with no default document window.
- App Sandbox and hardened runtime are enabled in project settings.
- The app registers the local URL scheme `menubardeclutter://`.
- The shipping app has no runtime dependency on the local fixture app.

Source folder names still use `MenuBar-Manager` while product identity has moved to `MenuBarDeclutter`. Treat `MenuBarDeclutter` as the current product/scheme name and `MenuBar-Manager` as legacy project/folder naming plus compatibility scheme.

## Product Shape

Basic Mode is the default and remains the core product promise. It uses only public `NSStatusItem` behavior: a user-positioned app-owned control item and variable-length app-owned separator items push later menu bar items out of view. It does not request Accessibility, Screen Recording, Apple Events, Input Monitoring, network access, or ScreenCaptureKit.

Pro Mode is opt-in. It adds read-only Accessibility discovery for menu bar item metadata, then powers optional features such as Find Icon, Second Bar, explicit icon moving, richer layout estimates, groups, and some automation. Pro surfaces degrade to visible unavailable states when Pro Mode is off, Accessibility Discovery is off, Accessibility permission is missing, Safe Mode is active, or a feature-specific gate is disabled.

Power-user features exist, but `v0.1.1` remains centered on safe defaults. Risky or system-sensitive features are off, paused, Preview-labeled, Experimental, or Labs-gated by default: Pro discovery, Find Icon, Second Bar, icon moving, Smart Triggers, dynamic hotkeys, Private Access, group status items, App Intents automation, Import/Export migration, and Menu Bar Spacing Labs all require explicit enablement or opt-in context. Phase 12 made the release claims, feature gates, and Settings copy more honest. Phase 13 has started turning the Phase 10/11 Pro scaffolding into cohesive command-routed workflows, including Settings-level command availability explanations, routed Search/Second Bar item utilities, shared status-menu command outcomes for advanced actions, and protected-action availability explanations in Private Access Settings.

## Architecture

The app uses a SwiftUI app entry point with an AppKit delegate:

- `MenuBar-Manager/App/MenuBarDeclutterApp.swift` defines the SwiftUI `App`.
- `MenuBar-Manager/App/AppDelegate.swift` sets accessory activation, creates the environment, starts services, stops services, and provides UI-test launch isolation.
- `MenuBar-Manager/App/AppEnvironment.swift` is the composition root and lifecycle facade.

`AppEnvironment` wires long-lived services, but behavior is split across focused coordinators:

- `AppHealthCoordinator` handles health checks, recovery, Safe Mode, and repair actions.
- `SettingsRuntimeCoordinator` applies setting changes to runtime services.
- `ProfileAutomationCoordinator` owns profiles, triggers, and URL automation.
- `MenuBarItemSurfaceCoordinator` owns Find Icon, Second Bar, menu item activation, and icon move dispatch.
- `LayoutCoordinator` owns Phase 10 layout services.
- `AppEnvironmentLiveStatusSynchronizer` keeps core diagnostics state current.
- `AppEnvironmentSystemRecoveryCoordinator` observes display, wake, and active-Space recovery events.

Real menu bar control lives in AppKit services under `StatusBar/`, `Hiding/`, `Layout/`, `Groups/`, and `SecondBar/`. SwiftUI owns Settings, Onboarding, diagnostics surfaces, Search, Second Bar, groups, migration, Private Access, and automation settings.

## Major Source Areas

- `App/`: lifecycle, dependency graph, runtime coordinators, app constants.
- `CommandCenter/`: shared command actions, targets, sources, availability, result mapping, diagnostics, and routing.
- `StatusBar/`: `NSStatusItem` control, separators, status menu, drag hint.
- `Hiding/`: Basic visibility state, separator-based hiding, auto-rehide, hover reveal, screen geometry.
- `Hotkeys/`: Carbon global hotkey model/manager plus Phase 11 dynamic hotkey bindings.
- `Settings/`: Settings shell and feature-specific settings sections.
- `Onboarding/`: first-run SwiftUI onboarding.
- `Core/`: settings store, diagnostics, launch at login, paths, app icons, migration.
- `Permissions/` and `Accessibility/`: opt-in Accessibility permission checks and read-only menu bar scanning.
- `Search/`: Find Icon panel, search ranking, highlight overlay, non-clicking activation.
- `SecondBar/`: floating hidden-item panel and placement logic.
- `Moving/`: explicit Pro icon moving, drag planning, CGEvent execution, verification, safety rules.
- `Profiles/`: local profiles, trigger models, trigger runtime, URL automation.
- `Layout/`: capacity estimates, suggestions, Full Menu Bar Mode, crowded rescue, spacers, spacing labs.
- `Groups/`: icon groups, group panels, group status items, import/export helpers.
- `PrivateAccess/`: LocalAuthentication-backed app-owned action gates.
- `Shortcuts/`: App Intents and automation settings.
- `Migration/`: settings export/import scaffolding, backups, profile packs, migration assistant UI.
- `Health/`: health reports, recovery, Safe Mode, crash marker support.
- `Dogfood/`: local dogfood run state, notes, checklists, privacy-safe export bundles.
- `DesignSystem/`: reusable settings and panel primitives.
- `Tools/MenuBarFixtureApp/`: local-only fixture app with deterministic menu bar items for QA.

## Implemented Features

### Basic Mode

- Permission-free expand, collapse, toggle, and reveal-all behavior.
- App-owned control item plus primary separator and optional always-hidden separator.
- Persisted collapsed state and optional start-collapsed preference.
- Separator geometry recomputation after display changes.
- Optional drag hint popover for command-drag positioning.
- Optional auto-rehide with postponement while the menu bar, Settings window, or status menu is active.
- Optional hover reveal using `NSEvent.mouseLocation` polling, without event taps.
- Optional always-hidden zone and Option-click reveal-all behavior.
- Optional global visibility hotkey using Carbon `RegisterEventHotKey`.
- Status menu commands for visibility, recovery, Settings, Diagnostics, About, and Quit.

### Settings, Onboarding, Launch, And Diagnostics

- SwiftUI Settings window with sections for General, Behavior, Layout, Search, Second Bar, Private Access, Groups, Hotkeys, Profiles, Automation, Import / Export, Privacy, Diagnostics, and Advanced.
- First-run onboarding hosted in an AppKit window.
- Launch at Login through public `SMAppService.mainApp`, only from explicit/persisted user opt-in.
- Typed `SettingsStore` backed by UserDefaults, with clamping and safe defaults.
- Application Support directory management for diagnostics, profiles, backups, dogfood runs, groups, hotkeys, and exports.
- Structured diagnostics logger with category/severity filtering.
- Privacy-safe diagnostics export to `.txt` or `.json`.
- Reset App Layout, Reset All Settings, migration notices, and v0.1 safe-default repair.

### Pro Accessibility Discovery

- Pro Mode and Accessibility Discovery are separate explicit settings.
- Accessibility permission is checked without prompting by default.
- The prompt is shown only from an explicit user action.
- The scanner reads public Accessibility metadata only: roles, subroles, titles, descriptions, identifiers, process IDs, frames, ownership metadata, and children.
- Zone classification maps item frames relative to the primary and always-hidden separator frames.
- Scans are gated by Pro Mode, Accessibility Discovery, and granted Accessibility permission.
- Diagnostics expose permission state, scan counts, zone counts, failure counts, and scan snapshots.

### Find Icon

- Floating SwiftUI/AppKit Search panel.
- Search index over latest Accessibility snapshots.
- Ranking by app name, title, bundle ID, prefix/contains matches, zone priority, and recency.
- Keyboard navigation and optional Find Icon hotkey.
- Selection reveals hidden zones or reveal-all when configured, then highlights the approximate frame.
- Selection does not click, drag, activate third-party apps, or inspect screen pixels.
- Search settings and diagnostics are present; live query text and selected identity are excluded from diagnostics export.

### Second Bar

- Floating SwiftUI `NSPanel` showing hidden and always-hidden snapshots.
- Uses app/bundle icons plus Accessibility metadata, not screenshots.
- Placement modes: below menu bar, near mouse, and last position.
- Placement service clamps to visible frames and models notch avoidance.
- Search, keyboard selection, labels, zone badges, optional outside-click close, and optional owning-app activation setting.
- Unavailable states explain missing Pro Mode, Accessibility Discovery, or permission.

### Icon Moving

- Explicit Pro-only, experimental, disabled-by-default feature.
- Commands originate from Search or Second Bar item actions.
- Requires Pro Mode, Accessibility permission, icon-moving setting, valid frame metadata, and first-use confirmation unless suppressed.
- Blocks MenuBarDeclutter's own status items and likely system items by default.
- Plans conservative Command-drag operations, suspends conflicting runtime behaviors, executes via `CGEvent`, rescans, verifies, retries, and restores visibility on failure.
- Real movement remains fragile and requires manual QA because it depends on live macOS menu bar behavior and third-party item cooperation.

### Profiles, Triggers, And URL Automation

- Local JSON profiles stored under Application Support.
- Profile editor/list UI with create, duplicate, delete, dry-run, apply, import, and export affordances.
- Profile application applies conservative Basic settings and visibility; target-zone moves are reported rather than silently bulk-moved.
- Smart Triggers are opt-in and paused by default.
- Trigger rules cover display count, launched app, frontmost app, battery-low, and time of day; Focus and Wi-Fi remain modeled but inactive until safe providers exist.
- URL automation supports local command-limited routes such as expand, collapse, reveal-all, second bar, profiles, Full Menu Bar Mode, and layout suggestions through the shared Command Center router.
- Automation pause prevents triggers and URL commands without blocking manual Basic Mode controls.

### Health, Recovery, And Safe Mode

- Startup is recovery-first: status items are installed, health is checked, recovery can run, and only then can collapsed launch preferences apply.
- Health checks cover missing status items, invalid separator lengths, invalid screen geometry, corrupted settings, hotkey drift, stuck auto-rehide/hover state, Pro permission mismatches, repeated AX failures, stale scans, layout state, groups, dynamic hotkeys, and Private Access sessions.
- Recovery can reset separator lengths, recreate status items, expand/reveal, temporarily disable risky runtime behaviors, disable Pro Mode, hide optional spacers/group items, clear sessions, and request Safe Mode.
- Safe Mode can be triggered by holding Option at launch, a one-shot flag, or an unclean crash marker.
- Safe Mode starts expanded and suppresses optional services while preserving the visible Basic control and reset menu.
- Health reports are exportable and privacy-safe.

### Dogfood And Fixture QA

- `MenuBarFixtureApp` creates deterministic local menu bar items for manual and script-assisted QA.
- Fixture scripts build, launch, validate, and stop the fixture.
- Dogfood Mode stores local run IDs, checklists, notes, and privacy-safe export bundles.
- Dogfood exports exclude screenshots, screen contents, telemetry, live search text, selected-item identity, and network data.

### Phase 10 Layout Pack

- Capacity estimation from Basic geometry and, when available, Pro Accessibility snapshots.
- Non-invasive layout suggestions.
- Full Menu Bar Mode with temporary reveal and auto-exit.
- Crowded Reveal Rescue service with Second Bar / Full Menu Bar Mode fallback logic and a status-menu inline override hook.
- App-owned spacer/divider status items.
- Layout Settings UI for capacity, suggestions, Full Menu Bar Mode, crowded reveal, spacers, and Spacing Labs.
- Menu Bar Spacing Labs service for dry-run/apply/backup/restore/reset of menu bar spacing defaults; the current Settings UI exposes enablement, preset selection, and status, but not full apply/restore/reset controls.
- Spacing Labs is experimental, off by default, reversible by design, and never restarts system processes automatically.
- ScreenCaptureKit visual icon capture remains intentionally deferred.

### Phase 11 Power-User Pack

- Icon groups with local storage, validation, matching, editor, picker, preview, searchable group panels, and import/export helpers.
- Optional app-owned group status items, off by default.
- Private Access with LocalAuthentication, unlock sessions, protected resources, policies, and protected-action gate.
- Dynamic hotkey bindings with conflict detection, max count, registration service, and Settings UI.
- App Intents / Shortcuts provider with command-routed actions for visibility, Second Bar, groups by ID, Full Menu Bar Mode, profile apply, automation pause/resume, and spacing preset requests.
- Automation Settings UI for App Intents, profile apply, and Labs access.
- Import / Export and Migration Assistant UI with export, dry-run import, backup creation, and explicit safe apply.
- Profile integration for groups, protected groups, dynamic hotkeys, layout preferences, Full Menu Bar Mode preference, and Labs-gated settings.

Some Phase 11 surfaces are better described as implemented scaffolding or guarded local UI rather than fully release-proven automation. Phase 12 replaced placeholder settings export values with real privacy-safe local values plus omission metadata, and Phase 13 added safe settings-package apply after dry-run plus backup. Phase 13 command-routing now covers App Intents, URL automation, Dynamic Hotkey execution, Find Icon item actions, Second Bar item actions, advanced status-menu actions, group status item Open Group, group reveal, and Settings command availability explanations for Find Icon, Second Bar/Icon Panel, Groups, Profiles, and Private Access protected actions. Remaining direct utility execution paths and spacing preset actions still need more gate-unification work before broad public claims.

## Privacy Boundary

Basic Mode:

- Does not request Accessibility.
- Does not request Screen Recording.
- Does not use ScreenCaptureKit.
- Does not request Apple Events.
- Does not request Input Monitoring.
- Does not use network access, telemetry, cloud sync, or analytics.
- Uses public AppKit `NSStatusItem`, `NSEvent.mouseLocation`, `SMAppService`, local UserDefaults, and local Application Support files.

Pro Mode:

- Is opt-in.
- Uses Accessibility only after explicit user enablement and explicit permission request.
- Reads metadata needed for menu bar discovery and assistance.
- Does not capture pixels, screenshots, or screen contents.
- Degrades to Basic Mode when permission is denied, revoked, or unavailable.

Private Access:

- Uses LocalAuthentication for app-owned gates only.
- Stores no biometric data.
- Is not encryption and cannot hide third-party menu bar items that are already visible outside app-owned UI.

Diagnostics, dogfood, health reports, settings exports, and local backups exclude screenshots, screen contents, network data, Accessibility snapshots by default, protected group names, protected hotkey targets, active unlock sessions, live search text, selected item identity, and import/export paths unless a user explicitly selects a local file.

## Defaults And Gates

Default safe state:

- Basic collapse/expand/reveal controls are available.
- Settings, onboarding, diagnostics, health, Safe Mode, layout guidance, groups, and App Intents UI are present.
- Launch at Login is off until user opt-in.
- Auto-rehide, hover reveal, always-hidden zone, and global hotkey are off until user opt-in.
- Pro Mode and Accessibility Discovery are off.
- Find Icon and Second Bar are off and require Pro requirements.
- Icon Moving is off, experimental, and confirmation-gated.
- Smart Triggers are off and automation is paused.
- Private Access is off.
- Dynamic hotkeys are off.
- Optional group status items are off.
- Menu Bar Spacing Labs is off and dry-run oriented by default.

Safe Mode suppresses optional automation, Pro scanning, icon moving, hotkeys, hover/rehide behaviors, and optional status items while keeping Basic Mode recovery available.

## Testing And Validation

The latest green full-suite Phase 13 command-routing validation snapshot records:

- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'`: passed on June 29, 2026.
- Swift Testing tests: 338 tests in 61 suites passed.
- UI tests: 7 tests passed.
- Focused Command Center/App Intents/URL automation/Dynamic Hotkey tests: 30 tests in 4 suites passed.
- Focused status-menu and Command Center router tests: 16 tests in 2 suites passed.
- Focused Private Access and Command Center router tests: 21 tests in 2 suites passed.
- `scripts/qa_preflight.sh`: passed.
- `scripts/verify_privacy_boundary.sh`: passed.
- `APP_PATH=/Applications/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh`: passed.
- `scripts/qa_dogfood_preflight.sh`: passed.
- `scripts/build_release.sh --dry-run --install --verify-installed`: passed.
- `scripts/verify_release_artifact.sh build/Export/MenuBarDeclutter.app --expected-version 0.1.1 --expected-build 2`: passed.
- Installed-app verification passed for `/Applications/MenuBarDeclutter.app`.
- Notarization dry-run passed with credentials unset.
- Real notarization submission with credentials unset failed safely before upload with a clear missing-credentials message.
- Local alpha package creation passed for `build/Dist/MenuBarDeclutter-v0.1.1-alpha.zip` and `build/Dist/MenuBarDeclutter-v0.1.1.zip`.

The current Phase 13 integration batch adds newer non-UI coverage for shared Find Icon / Second Bar filtering, local hashed recents/favorites, crowded reveal rescue, group import/export, group item actions, group reveal/search, group hotkey assignment, safe settings-package apply, URL automation, App Intents, and Command Center routing. `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -skip-testing:MenuBarDeclutterUITests -quiet` passes with 403 tests in the latest local run. Full/UI test attempts after the Private Access slice did not complete because the XCTest UI runner timed out while enabling automation mode or stayed at `Running tests...`; during the full attempts, Swift Testing reached 341 tests in 61 suites before the UI handoff failed or was interrupted.

Important test coverage areas include settings defaults/migration, diagnostics export privacy, hiding/reveal/auto-rehide/hover, Accessibility discovery logic, scan gating and throttling, search ranking, Search and Second Bar command routing, status-menu command routing, Private Access redaction and protected command availability, Second Bar placement/view model behavior, profile store and trigger logic, URL automation, App Intents execution, hotkey models and dynamic registration, layout capacity/suggestions, Full Menu Bar Mode, crowded rescue, spacers, spacing service, icon moving safety/planning/verification, groups, Private Access, health/recovery/Safe Mode, dogfood storage, and QA script wiring.

UI tests run with `--ui-testing` isolation: dedicated defaults, temporary App Support paths, onboarding skipped, Launch at Login disabled, and Pro off. Current UI coverage is smoke-level for settings/diagnostics/privacy/search unavailable states/Second Bar requirements, not a substitute for manual menu bar QA.

## Release State

The local release workflow exists:

1. Clean release outputs.
2. Archive the app.
3. Export or copy the archived app.
4. Verify release artifact and privacy boundary.
5. Package zip artifacts.
6. Run notarization in dry-run mode or real mode when credentials exist.
7. Staple and validate Gatekeeper.
8. Install locally to `/Applications`.
9. Verify the installed app and privacy boundary.
10. Collect local QA artifacts.

Current status:

- Local archive/export/package/install dry-runs are documented as passing.
- The app is signed with available local development signing.
- Strict code signing checks pass in local validation.
- `Config/ExportOptions.plist` is present for Developer ID export without secrets.
- Release artifact verification checks bundle ID, version/build, `LSUIElement`, app category, local URL scheme, sensitive usage strings, sandbox entitlement, hardened runtime metadata, network entitlements, ScreenCaptureKit linkage, code signature, `spctl`, and stapler state.
- Installed-app verification checks the same privacy and packaging boundary on `/Applications/MenuBarDeclutter.app`.
- App category metadata is set to `public.app-category.utilities`.
- Public distribution is blocked by missing Developer ID Application identity/notarization credentials.
- Gatekeeper/stapler warnings are expected for non-notarized dry-run artifacts.
- Manual system QA is partially complete through Codex Computer Use and local shell verification; physical menu bar, display, permission, login, sleep/wake, and real Shortcuts flows remain hands-on gates.

## Remaining Manual Gates

Before public or stable claims, these require hands-on macOS validation or explicit acceptance:

- Real command-drag placement of the Basic control/separators.
- Collapse, expand, reveal-all, and reset behavior against a live crowded menu bar.
- Hover-only reveal behavior against the live menu bar band.
- Launch at Login across install, restart, logout/login, and removal.
- Accessibility grant, revoke, restart, and degraded-state flows.
- Safe Mode via Option launch, one-shot flag, and crash marker recovery.
- External displays, notch layouts, sleep/wake, active Space changes, and menu bar appearance variants.
- Touch ID/password success, cancel, unavailable, and failure flows.
- Shortcuts app discovery and manual execution of App Intents.
- Command-drag of app-owned spacer and group status items.
- Real crowded-menu-bar rescue behavior.
- Any service-level Menu Bar Spacing Labs apply, restore, and reset path because it mutates global defaults.
- Real third-party/system item icon moving.

## Known Limitations

- Basic hiding is separator-based; it does not use private Apple menu bar APIs and does not directly control third-party status items.
- The primary Basic Mode separator is required and recoverable; legacy `showPrimarySeparator = false` state is repaired and excluded from real diagnostics/settings migration snapshots to avoid false configurability.
- Menu bar ordering and command-drag placement depend on macOS behavior and user setup.
- Crowded Reveal Rescue has a service, diagnostics, and status-menu override hook, but automatic interception of the normal expand/reveal path still needs wiring validation.
- Some menu bar items expose incomplete or stale Accessibility metadata.
- Second Bar uses metadata and app/bundle icons, not captured menu bar pixels.
- No ScreenCaptureKit visual icon capture is implemented.
- Icon Moving may fail on third-party or system items and remains experimental.
- Profiles do not silently run bulk icon moves.
- Smart Triggers are conservative, disabled by default, and paused by default.
- Focus and Wi-Fi trigger providers remain inactive.
- Private Access gates app-owned UI actions only; it is not encryption.
- Private Access diagnostics log protected resource kinds, not protected target IDs.
- Competitor config auto-import is not implemented.
- Import/Export Preview writes a real local JSON settings package with privacy-safe values and omission metadata; import has dry-run analysis, backup creation, and an explicit safe apply path that merges by ID and skips imported experimental enablement.
- App Intents, URL automation, dynamic hotkeys, routed Search/Second Bar item utilities, group status item Open Group, and advanced status-menu commands now use shared Command Center gates/results, but remain Preview surfaces until hands-on Shortcuts/URL/status-menu QA and protected/Pro/Labs/automation-pause flows are exercised end to end.
- Basic status-menu expand/collapse/toggle controls intentionally stay on direct Basic execution paths so Safe Mode recovery remains permission-free and Pro-independent.
- Spacing Labs has service-level dry-run/apply/restore/reset code, but the Settings UI currently lacks explicit apply/restore/reset controls and backup persistence is not sufficient for reliable real restore semantics.
- Dynamic hotkeys and group status items are local app-owned conveniences, not system-wide menu bar ownership.
- Launch at Login must be validated from an installed `/Applications` app, not only from Xcode or DerivedData.
- Public notarization requires credentials that were not available during the recorded local audit.

## Documentation Map

- Architecture: `docs/architecture/architecture-overview.md`.
- Phase plans: `docs/plans/`.
- Phase progress snapshots: `docs/progress/`.
- Feature docs: `docs/features/`.
- Privacy boundary: `docs/privacy/privacy-boundary.md`, Phase 10/11 privacy docs, and `docs/privacy/v0.1.1-privacy-claims.md`.
- Manual QA and matrix docs: `docs/testing/`.
- Dogfood docs: `docs/testing/dogfood/` and `docs/dogfood/`.
- Release docs: `docs/release/`.
- Phase 10 docs: `docs/phase-10/`.
- Phase 11 docs: `docs/phase-11/`.
- Roadmap: `docs/roadmap/post-v0.1.md`.
- Research/license references: `docs/research/`.
- Refactoring audit: `docs/refactoring-audit.md`.

Historical phase/progress files intentionally preserve older test counts, scheme names, and deferred-scope notes. Prefer this summary, the latest status reports, and current release/QA docs when making current-state decisions.

## Phase Index

- Phase 0: project skeleton, AppKit/SwiftUI lifecycle, status item baseline, Settings, diagnostics, docs, tests.
- Phase 1: permission-free separator-based Basic hiding MVP.
- Phase 2: Basic behavior polish: auto-rehide, hover reveal, always-hidden zone, Option-click reveal all, global hotkey.
- Phase 3: Settings, onboarding, Launch at Login, diagnostics export, App Support paths, reset actions.
- Phase 4: opt-in Accessibility discovery and diagnostics.
- Phase 5: Find Icon search panel with non-clicking reveal/highlight activation.
- Phase 6: floating Second Bar using Accessibility metadata and app/bundle icons.
- Phase 7: explicit Pro icon moving with guarded Command-drag simulation.
- Phase 8: local profiles, smart triggers, and command-limited URL automation.
- Phase 9: health checks, recovery, Safe Mode, crash markers, and macOS system-change recovery.
- Phase 9.1: Alpha RC validation and release hardening.
- Phase 9.2: local dogfood harness and fixture app.
- Phase 9.3: installed alpha workflow and dry-run distribution tooling.
- Phase 9.4: stability gates, safe defaults, migration groundwork, emergency recovery.
- Phase 9.5: v0.1 Basic Stable Freeze docs, defaults, migration, and release validation.
- Phase 10: Capacity & Layout Pack, excluding deferred visual capture.
- Phase 11: Private Access & Power User Pack.
- Phase 12: v0.1.1 release confidence, trust hardening, release tooling, public claims, support docs, manual QA evidence, installed-app verification, and auto-rehide runtime fix.
- Phase 13: in-progress v0.1.1 Pro workflow completion and command-routing unification.

## Roadmap

Immediate release work:

- Complete manual system QA gates.
- Configure Developer ID Application signing and notary credentials.
- Run real notarization, stapling, Gatekeeper validation, and installed-app regression.
- Continue Phase 13 command-routing work so Find Icon, Second Bar, groups, profiles, hotkeys, App Intents, URL automation, and Private Access share one predictable gate/result model end to end.
- Tighten Phase 10/11 Pro workflows that are currently scaffolded, preview-only, or only smoke-tested.

Post-v0.1 candidates:

- ScreenCaptureKit or visual icon capture only after a separate privacy review.
- AppleScript dictionary support if it can preserve the permission model.
- Real Focus/Wi-Fi trigger providers using safe public APIs.
- Stronger external display/notch handling.
- More evidence and guardrails for icon moving.
- Competitor config import, if schema and licensing boundaries are clear.
- More complete App Intent and import/export execution coverage.
