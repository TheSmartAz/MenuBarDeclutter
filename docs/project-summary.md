# Project Summary

Last updated: 2026-07-02

`MenuBarDeclutter` is a native macOS menu bar decluttering utility for macOS 26.0+. It is written in Swift with AppKit for real menu bar integration and SwiftUI for app-owned UI surfaces. The product direction is privacy-first: ship a useful Basic Mode that does not require sensitive permissions, then add selected power-user workflows behind explicit Pro, Preview, Labs, or Experimental gates.

The current sealed release line is `v0.1.7`, tagged after Phase 16-20 implementation and CI validation. Basic Mode remains the intended stable product core pending physical QA, while Workspaces, Function Bar, Set Builder, linked Groups, and Info Strip surfaces remain Preview-gated.

## Current Facts

- Product and app display name: `MenuBarDeclutter`.
- Xcode project package: `MenuBar-Manager.xcodeproj`.
- Canonical shared scheme: `MenuBarDeclutter`.
- Deprecated compatibility scheme: `MenuBar-Manager`.
- Local fixture scheme: `MenuBarFixtureApp`.
- Main targets: `MenuBarDeclutter`, `MenuBarDeclutterTests`, `MenuBarDeclutterUITests`, and `MenuBarFixtureApp`.
- The fixture target is local QA support only and is skipped for install.
- Bundle ID: `Yongjun-Zhang.MenuBarDeclutter`.
- Version/build: `0.1.7 (8)`.
- Deployment target: macOS `26.0`.
- Swift version: `6.0`.
- App style: `LSUIElement` accessory app with no default document window.
- Runtime identity: the main app target is intentionally non-sandboxed for opt-in Pro Accessibility Discovery, and hardened runtime remains enabled. No network entitlements, ScreenCaptureKit linkage, Screen Recording usage string, Apple Events usage string, or Input Monitoring usage string should be present.
- Local URL scheme: `menubardeclutter://`.
- Info.plist: `Config/MenuBarDeclutter-Info.plist`.
- Shared build settings: `Config/Shared.xcconfig`.
- Developer ID export options: `Config/ExportOptions.plist`.

The project, source, and test folders still use the legacy `MenuBar-Manager` name. Treat `MenuBarDeclutter` as the current product, target, app, and canonical scheme name. Treat `MenuBar-Manager` as legacy repository/project naming plus the temporary compatibility scheme.

## Current Status

`v0.1.7` keeps the privacy boundary intact while completing the Phase 16-20 track: competitive-core polish, Workspaces Foundation, Function Bar Preview, linked Groups / Set Builder Preview, and Info Strip Preview. It does not add Screen Recording, ScreenCaptureKit, Apple Events scripting/control, Input Monitoring, network access, telemetry, cloud sync, remote config, or private Apple menu bar APIs.

The intended stable claim is Basic Mode: app-owned menu bar controls, local settings, local diagnostics, local recovery, Launch at Login opt-in, permission-free hiding/reveal behavior, and Guided Manual Arrange using normal macOS Command-drag. The app mode is currently Basic; Pro is a separate opt-in capability gate, not a replacement runtime mode. Pro workflows are present, but most are still opt-in, Preview, Labs, or Experimental. Public docs and Settings copy should not describe those surfaces as Stable unless their feature gate explicitly does.

The Phase 16 ledger is `docs/progress/phase-16-v0.1.3-competitive-core-catch-up.md`. It records the v0.1.3 release identity work, Find & Rescue and Second Bar polish, crowded/notch rescue hardening, Guided Arrange / Placement Planner quality work, Assisted Move guardrails, New Item Inbox polish, Shortcuts validation, backup/restore confidence, Developer ID rehearsal, expanded manual QA docs, and public-claims cleanup.

The Phase 17-20 ledger is `docs/progress/phase-17-20-v0.1.7-workspaces-function-bar-info-strip.md`. It records the Workspaces track implementation: local workspace models, validation, persistence, switching, repair, backups, Advanced-only Workspaces Preview UI, Function Bar Preview, Set Switcher, Set Builder draft editing, linked/detached group references, Info Strip Preview, local tile providers, rotation, workspace display coordination, diagnostics, import/export, recovery, and release/privacy verification.

The latest sealed v0.1.7 validation evidence is strong for repository automation and local dry-run artifacts. `scripts/qa_preflight.sh` passed on merged `main`: build-for-testing succeeded, 538 app-unit tests in 75 suites passed, 16 UI tests passed, and privacy boundary source checks passed. `scripts/qa_dogfood_preflight.sh` passed after Phase 20 audit/UI stabilization fixes with the main app build, fixture build, 125 focused tests in 12 suites, privacy boundary checks, release artifact verification, and fixture launch. `scripts/build_release.sh --dry-run --install --verify-installed` passed for `0.1.7 (8)`, producing `MenuBarDeclutter-v0.1.7-alpha.zip` and `MenuBarDeclutter-v0.1.7.zip`, installing to `/Applications/MenuBarDeclutter.app`, and verifying the installed app as `0.1.7 (8)`. Expected dry-run warnings remain: non-notarized `spctl` rejection and missing stapled ticket.

Post-merge CI initially exposed a `TriggerServiceTests` debounce race. The fix stabilized the test by exercising deterministic DEBUG-only scheduling instead of relying on NotificationCenter delivery timing, while keeping production observers on `.main`. Local targeted and full app-unit tests passed, and GitHub Actions run `28611722018` passed for commit `d766a785bde7cf52c77978f94e1c686024b6540c`. The remote annotated tag `v0.1.7` points at that green commit.

The latest dated physical installed-app QA record before the Workspaces track remains `docs/testing/installed-app-qa-2026-06-30-native-redesign.md`. The Phase 20 release checklist adds the current v0.1.7 UI QA scope: single-screen behavior on the built-in display is recorded for Workspaces Preview and Info Strip Preview; external multi-display placement QA is deferred to future hardware follow-up and is not a current release blocker.

The current distribution stage is internal/local alpha. Public Developer ID distribution is intentionally deferred, so the repo uses dry-run archive/export/package/install flows for this stage. Developer ID export and notarization tooling remain available, but this machine/session only has an Apple Development identity; real Developer ID export, notarization, stapling, and Gatekeeper acceptance require external credentials when public distribution becomes in scope. Dry-run artifacts are expected to fail `spctl` and stapler validation until notarized.

Manual system QA remains partial. Release-blocking stable gates still need hands-on validation for Command-drag placement, always-hidden live visual behavior, hands-on auto-rehide timing/postponement/flicker behavior, notch and external-display layouts, sleep/wake, and logout/login or restart transition. Beyond those stable gates, Preview/Labs/Experimental surfaces still need non-blocking hands-on hardening for nonzero Pro Discovery metadata in a crowded/live menu setup, real Shortcuts execution, Touch ID / LocalAuthentication behavior, Spacing Labs apply/restore, real icon moving, and external multi-display placement for Workspaces / Function Bar / Info Strip Preview.

## Feature Status

Intended stable in current `v0.1.7`, pending physical QA:

- Basic expand, collapse, toggle, reveal-all, and always-hidden reveal when configured.
- App-owned `NSStatusItem` control and required primary separator.
- Optional auto-rehide, hover reveal, and global visibility hotkey.
- Launch at Login through public `SMAppService.mainApp`, only after user opt-in.
- Settings, onboarding, diagnostics, privacy-safe export, Safe Mode, health checks, and recovery.
- Pro Accessibility Discovery gating as a permission boundary.
- Guided Manual Arrange with normal macOS Command-drag.

Preview in current `v0.1.7`:

- Command Center routing.
- Workspaces Foundation: local workspace models, validation, switching, repair, backups, diagnostics, import/export, and an Advanced-only Workspaces Preview settings route.
- Function Bar Preview: app-owned floating panel, Set Switcher, local command items, gated menu bar item proxies, group items, spacers/dividers, placement, diagnostics, and Command Center-routed actions.
- Set Builder Preview: draft workspace composition, add/remove/reorder/commit/revert flows, library providers, linked/detached group references, and Function Bar preview integration.
- Info Strip Preview: app-owned local tile strip, local-only providers, rotation, placement, per-workspace selected providers, display coordination with Function Bar, and status-menu preview actions.
- Find Icon reveal/highlight when Pro gates are satisfied.
- Second Bar metadata/icon browsing when Pro gates are satisfied.
- Placement Planner, which reads Pro Discovery metadata and produces manual instructions without moving items.
- New Item Inbox, which uses privacy-safe hashed item memory to review newly discovered items.
- Crowded Reveal Rescue automation.
- Conservative local profile dry-run/apply for safe Basic settings.
- Smart Triggers.
- Dynamic Hotkeys.
- Private Access.
- Groups and optional group status items.
- App Intents automation.
- URL automation beyond manual Basic commands.
- Import / Export migration assistant.

Labs:

- Menu Bar Spacing Labs. It must remain explicit, reversible, and must not automatically mutate global menu bar spacing defaults or restart system processes.

Experimental:

- Assisted Move / Icon Moving. It is explicit single-item user action only, Pro and Accessibility gated, first-use-confirmation and per-move-confirmation gated, dry-run/result/recovery surfaced in Arrange, and still dependent on live macOS menu bar behavior and third-party item cooperation.

Deferred:

- ScreenCaptureKit visual capture.
- Screen Recording.
- Apple Events scripting.
- Input Monitoring.
- Network/cloud sync, telemetry, analytics, crash upload, or remote config.
- Stable competitor migration.
- Stable broad third-party menu bar item activation.
- Stable icon moving.
- A standalone Icon Panel as a stable release claim.

## Architecture

The app uses a SwiftUI entry point and an AppKit delegate:

- `MenuBar-Manager/App/MenuBarDeclutterApp.swift` defines the SwiftUI `App`.
- `MenuBar-Manager/App/AppDelegate.swift` sets `.accessory` activation, builds the environment, handles termination, and supports UI-test launch isolation.
- `MenuBar-Manager/App/AppEnvironment.swift` is the composition root and lifecycle facade.

`AppEnvironment` owns the long-lived services, starts and stops the runtime, and exposes callbacks used by the status menu, Settings, App Intents, URL automation, and tests. Behavior-heavy domains are split into focused coordinators:

- `AppHealthCoordinator` handles health snapshots, repair actions, Safe Mode, and recovery.
- `SettingsRuntimeCoordinator` applies settings changes to live runtime services.
- `ProfileAutomationCoordinator` owns profiles, triggers, and URL automation.
- `MenuBarItemSurfaceCoordinator` owns Find Icon, Second Bar, item actions, and icon move dispatch.
- `LayoutCoordinator` owns capacity, suggestions, Full Menu Bar Mode, crowded rescue, spacers, and Spacing Labs.
- `AppEnvironmentLiveStatusSynchronizer` keeps the diagnostics state current.
- `AppEnvironmentSystemRecoveryCoordinator` observes display, wake, and active-Space recovery events.

Real menu bar control lives in AppKit services around `NSStatusItem`. SwiftUI owns Settings, onboarding, diagnostics, Search, Second Bar, groups, automation, Private Access, and import/export surfaces.

## Source Map

- `MenuBar-Manager/App/`: lifecycle, dependency graph, runtime coordinators, app constants.
- `MenuBar-Manager/Assets.xcassets/`: app icon and accent assets.
- `MenuBar-Manager/StatusBar/`: control item, separator items, status menu, menu presenter, drag hint.
- `MenuBar-Manager/Hiding/`: visibility state, separator-based hiding, auto-rehide, hover reveal, screen geometry.
- `MenuBar-Manager/Arrange/`: Guided Manual Arrange steps, Placement Planner, New Item Inbox, and Assisted Move gate/dry-run/confirmation/result flow.
- `MenuBar-Manager/CommandCenter/`: shared command source/action/target/result/availability/routing model.
- `MenuBar-Manager/Core/`: settings, migration, diagnostics export, launch at login, app support paths, icons.
- `MenuBar-Manager/Settings/`: native Settings shell and feature-specific settings pages.
- `MenuBar-Manager/DesignSystem/`: reusable Settings/page primitives, badges, feedback controls.
- `MenuBar-Manager/Onboarding/`: first-run onboarding and System Settings opener.
- `MenuBar-Manager/Permissions/`: Accessibility permission status and explicit prompt flow.
- `MenuBar-Manager/Accessibility/`: public Accessibility metadata scanner, item snapshots, zone classification.
- `MenuBar-Manager/Search/`: Find Icon panel, search ranking, filters, local item memory, reveal/highlight activation.
- `MenuBar-Manager/SecondBar/`: floating hidden-item panel, view model, row views, placement.
- `MenuBar-Manager/Layout/`: capacity, suggestions, Full Menu Bar Mode, crowded rescue, spacers, spacing labs.
- `MenuBar-Manager/Workspaces/`: Preview workspace models, validation, store, switching service, diagnostics, and repair/recovery helpers.
- `MenuBar-Manager/FunctionBar/`: Preview floating Function Bar runtime, placement, item resolution, dispatch, views, Set Switcher, and diagnostics.
- `MenuBar-Manager/SetBuilder/`: Preview draft editor, library providers, drag/drop validation, linked/detached group reference editing, and SwiftUI views.
- `MenuBar-Manager/InfoStrip/`: Preview local tile providers, registry, rotation runtime, placement, controller, views, display coordination, and diagnostics.
- `MenuBar-Manager/Moving/`: experimental icon moving, drag planning, CGEvent execution, verification, safety rules.
- `MenuBar-Manager/Profiles/`: profiles, trigger models, trigger runtime, profile application, URL automation.
- `MenuBar-Manager/Groups/`: icon groups, group panels, group status items, import/export, item actions.
- `MenuBar-Manager/Hotkeys/`: global Basic hotkey and dynamic hotkey bindings/registration.
- `MenuBar-Manager/PrivateAccess/`: LocalAuthentication-backed gates for app-owned protected actions.
- `MenuBar-Manager/Shortcuts/`: App Intents provider, execution service, automation Settings UI.
- `MenuBar-Manager/Migration/`: settings export/import packages, backups, migration assistant.
- `MenuBar-Manager/Health/`: health reports, issue modeling, recovery, Safe Mode.
- `MenuBar-Manager/Dogfood/`: local dogfood run state, notes, checklist, privacy-safe export bundles.
- `Tools/MenuBarFixtureApp/`: local-only fixture app with deterministic menu bar items for QA.
- `MenuBar-ManagerTests/`: pure logic, service, privacy, and integration-oriented tests.
- `MenuBar-ManagerUITests/`: smoke UI coverage for Settings, Search, diagnostics, and launch behavior.
- `scripts/`: build, test, QA, release, notarization, install, privacy, and fixture helpers.
- `docs/`: plans, progress, release docs, feature docs, QA records, support docs, design artifacts, and architecture notes.

## Local Data And Persistence

`SettingsStore` is the central UserDefaults-backed settings model. `AppMode` currently supports Basic Mode; Pro, Accessibility Discovery, Find Icon, Second Bar, Layout, Groups, Dynamic Hotkeys, Private Access, App Intents, Labs, and automation behavior are separate settings and gates.

`AppSupportPaths` centralizes the local Application Support tree:

- `Application Support/MenuBarDeclutter/`.
- `diagnostics/` for explicit diagnostics exports.
- `profiles/` for profile JSON files and `triggers.json`.
- `backups/` for migration/import backups and corrupted-store backups.
- `Dogfood/runs/` and `Dogfood/exports/`.
- `menu-bar-item-memory.json` for hashed Find Icon / Second Bar recents and favorites.
- `workspaces/workspaces.json` for Preview workspace snapshots, active workspace selection, Function Bar composition, Set Builder output, and Info Strip configuration.

Other local stores are intentionally focused:

- Profiles are stored as per-profile UUID JSON files.
- Groups are stored in `groups.json`.
- Dynamic hotkeys are stored in `hotkeys.json`.
- App-owned spacers are stored in `spacers.json`.
- Settings export packages include schema metadata, real privacy-safe setting values, profiles, groups, hotkeys, spacer items, workspace snapshots, and Private Access policy export fields.

Corrupted groups, hotkeys, spacers, and workspace snapshots are backed up before resetting. Recents/favorites store hashed item IDs only and are treated as convenience state, so persistence failures fail closed without breaking Basic Mode.

## Basic Mode

Basic Mode is the intended stable product core in current `v0.1.7`; release completion still depends on the manual QA gates. It must work when Pro Mode is off, Accessibility is denied or revoked, and all Preview/Labs/Experimental features are disabled.

Basic Mode uses only public macOS behavior:

- An app-owned control `NSStatusItem`.
- A required app-owned primary separator `NSStatusItem`.
- An optional app-owned always-hidden separator.
- Public `NSEvent.mouseLocation` polling for hover reveal, without event taps.
- Carbon `RegisterEventHotKey` for app hotkeys, without Input Monitoring.
- Public `SMAppService.mainApp` for Launch at Login.
- Local UserDefaults and Application Support files.

Implemented Basic behavior includes expand, collapse, toggle, reveal all, optional always-hidden reveal, Option-click reveal-all, optional auto-rehide, optional hover reveal, optional global visibility hotkey, display-change geometry recomputation, wake/display recovery, status menu controls, and reset/recovery actions.

Basic hiding is separator-based. The app does not directly control third-party menu extras and does not use private Apple menu bar APIs. Users still need normal macOS command-drag positioning for best results.

## Pro Accessibility Discovery

Pro Mode is an optional layer. Metadata-dependent features require all of these gates:

- Pro Mode enabled.
- Accessibility Discovery enabled.
- macOS Accessibility permission granted.
- Feature-specific setting enabled.
- Safe Mode inactive.

The app checks Accessibility trust without prompting by default. The system prompt is shown only after an explicit user action.

When enabled and permitted, the scanner reads public Accessibility metadata such as role, subrole, title, description, identifier, process ID, frame, ownership metadata, and children. It does not capture pixels, screenshots, or screen contents. Zone classification compares item frames with the app-owned separator frames to mark items as visible, hidden, always-hidden, or unknown.

If Pro Mode is off, discovery is off, permission is missing, or Safe Mode is active, Pro surfaces show unavailable/degraded states and Basic Mode continues working.

## User-Facing Surfaces

Settings uses a native sidebar/detail layout with these visible sections:

- General.
- Hide & Reveal.
- Arrange.
- Find & Rescue.
- Privacy.
- Recovery.
- Advanced.

Legacy detail pages remain reachable from Advanced or page actions where needed. The visible sidebar intentionally keeps Preview, Labs, Experimental, and power-user features from becoming top-level product pillars.

Onboarding is a SwiftUI flow hosted in AppKit and includes native cleanup guidance plus an Arrange test step. The status menu remains the primary everyday surface for Basic controls, Arrange, Find & Rescue, Settings, Diagnostics, recovery, and selected advanced actions.

Find Icon is a floating search panel over the latest Accessibility snapshot index. It supports ranking, filters, recents/favorites memory, keyboard navigation, reveal/highlight actions, Second Bar handoff, and group item actions. It does not click arbitrary menu bar items or activate third-party menu extras broadly.

Second Bar is a floating metadata/icon panel for hidden and always-hidden snapshots. It uses app/bundle icons plus Accessibility metadata, not live menu bar pixels. It supports placement modes, search, filters, keyboard selection, item actions, and clear Pro requirement states.

Arrange is the intended stable icon-placement surface pending physical QA. Guided Manual Arrange teaches Command-drag placement for the control item, separator, hidden side, optional always-hidden side, and placement test actions. Placement Planner is Preview, reads Pro Discovery metadata when gates are satisfied, and produces manual instructions only. Assisted Move remains Experimental, single-item, and confirmation gated.

Find & Rescue consolidates Find Icon, Second Bar, New Items, Crowded Reveal Rescue, and lightweight collections/tags into one workflow. New Item Inbox has privacy-safe detection/dismiss/reset/persistence logic, live Pro Discovery scan persistence, Settings count plumbing, a dedicated review list with generic item labels and user-facing dismiss/reset controls, and a conditional status-menu New Items row behind Pro Discovery gates. Richer per-item placement actions remain deferred to Placement Planner work.

Groups let users organize discovered item identities into local groups, open group panels, reveal groups, assign group hotkeys, protect groups with Private Access, and import/export group data with protected-name redaction by default.

Workspaces Preview is an Advanced-only surface in `v0.1.7`, not a stable top-level Settings section. It stores local workspace compositions, validates and repairs snapshots, switches active workspace selection without physical profile application or icon movement, and backs up corrupted workspace data before reset/repair.

Function Bar Preview is an app-owned floating panel for active Workspace items. It can show command items, group items, gated menu bar item proxies, spacers, dividers, and deferred Info Strip placeholders. It routes actions through Command Center, suppresses itself in Safe Mode, and does not replace Basic Mode hiding.

Set Builder Preview lets users draft, reorder, commit, and revert Workspace / Function Bar compositions. It supports linked and detached Group references, keeps menu bar item proxy behavior behind Pro Discovery gates, and preserves Workspaces and group references in local import/export snapshots.

Info Strip Preview is an app-owned local tile strip. It uses local providers such as current workspace, clock, battery, hidden count, new item count, recovery warning, and stale-scan warning, skips unavailable providers during rotation, and requires explicit global plus per-Workspace opt-in for idle display. Calendar, reminder, online/media/news/weather/stocks tiles are not implemented in v0.1.7.

Profiles and triggers provide local workflow presets. Profile application is conservative: Basic settings can apply directly, while target-zone movement remains explicit and gated. Smart Triggers are opt-in and paused by default.

Private Access uses LocalAuthentication for app-owned gates. It protects app commands and local app surfaces; it is not encryption and cannot hide third-party icons that are already visible in the system menu bar.

Import / Export writes local JSON settings packages with schema and redaction metadata. Import dry-runs first, creates a backup, and safe-applies supported settings/objects by ID. It intentionally avoids destructive full restore semantics and does not enable Icon Moving, Smart Triggers, Launch at Login system state, or Spacing Labs from imported packages.

## Command Center

Phase 13 added `MenuBar-Manager/CommandCenter/` to unify action routing across advanced workflows, and Phase 14 extended the vocabulary for Assisted Move dry-run, try, cancel, and guide actions. A `MenuBarCommand` has a source, action, target, and structured result. Sources include status menu, Settings, Find Icon, Second Bar, icon panel, group panel, dynamic hotkeys, smart triggers, App Intents, URL automation, crowded rescue, and internal recovery.

The router evaluates shared gates before execution:

- Safe Mode.
- App Intents enablement.
- automation pause.
- profile/labs automation opt-in.
- Pro Mode.
- Accessibility Discovery.
- Accessibility permission.
- feature enablement.
- Labs enablement.
- experimental confirmation.
- target compatibility.
- Private Access lock status.

The result model is privacy-safe and uses statuses such as success, unavailable, blocked, permission needed, unlock needed, Pro required, Labs required, Preview only, failed, and no change. Diagnostics log command/action/source/target kind and reason, not raw item IDs, profile names, protected group names, live search text, or file paths.

Command Center currently routes App Intents, URL automation, Dynamic Hotkeys, Find Icon item actions, Second Bar item actions, group actions, selected status-menu advanced actions, profile apply/dry-run, crowded rescue fallbacks, assisted-move dry-run vocabulary, and Private Access availability explanations. Continued work should keep moving remaining advanced surfaces through this path instead of adding one-off gate logic.

## Automation Surfaces

Automation is local and command-limited. It does not add a scripting dictionary, network access, telemetry, cloud sync, or remote config. The app registers the `menubardeclutter://` URL scheme and handles URLs through a local URL event handler, but URL commands still route through Command Center and respect Safe Mode, automation pause, profile automation opt-in, Labs automation opt-in, Pro gates, Accessibility gates, and Private Access.

Documented URL routes include expand, collapse, reveal-all, Second Bar, profile-by-name, group-by-UUID, reveal-group-by-UUID, Full Menu Bar Mode, and layout suggestion / spacing preview routes where enabled by the current code and docs.

App Intents are exposed through `MenuBarDeclutterShortcutsProvider` and `AppIntentExecutionService`. Current intent types cover expand, collapse, reveal all, show/hide Second Bar, enter/exit Full Menu Bar Mode, apply profile by name, open group panel by group ID, reveal group by group ID, pause/resume automation, and preview a layout spacing preset. Rich Shortcuts entities for browsing profiles, groups, or items by name remain deferred.

Dynamic Hotkeys share the same command path. They use Carbon global hotkey registration, reject invalid/conflicting bindings, obey max-count limits, and route protected/profile/group actions through Command Center and Private Access gates.

## Privacy Boundary

Basic Mode does not request or use:

- Accessibility.
- Screen Recording.
- ScreenCaptureKit.
- Apple Events permission, scripting dictionaries, or control of other apps through Apple Events.
- Input Monitoring.
- Network access.
- Telemetry, analytics, crash upload, cloud sync, or remote config.
- Private Apple menu bar APIs.

Pro Mode may use Accessibility metadata only after explicit user enablement and explicit macOS permission grant. It still does not use Screen Recording, ScreenCaptureKit, Apple Events scripting/control, Input Monitoring, network calls, screenshots, pixel sampling, or private APIs.

Diagnostics, health reports, dogfood bundles, settings exports, and backups are local and privacy-safe by design. They exclude screenshots, screen contents, live search text, selected item identity, protected group names, protected hotkey targets, active unlock sessions, Accessibility snapshots by default, network data, and import/export paths unless the user explicitly selected a local file as part of the action.

## Defaults And Gates

Safe defaults matter because older alpha builds exposed more switches while features were under construction. Current `v0.1.7` defaults keep Basic Mode available and keep risky surfaces off or paused:

- Launch at Login is off until user opt-in.
- Start collapsed is off by default.
- Auto-rehide is off by default.
- Hover reveal is off by default.
- Always-hidden zone is off by default.
- Global hotkey is off by default.
- Pro Mode is off by default.
- Accessibility Discovery is off by default.
- Find Icon and Second Bar require Pro gates.
- Icon Moving is off and Experimental.
- Smart Triggers are off and automation is paused.
- App Intents UI can be present, but automation is paused and profile/Labs automation access is off by default.
- Private Access is off by default.
- Dynamic Hotkeys are off by default.
- Optional group status items are off by default.
- Spacing Labs is off by default.
- Workspaces Preview, Function Bar Preview, Set Builder Preview, and Info Strip Preview are off by default or reachable only through explicit Preview/Advanced controls.

Safe Mode starts expanded and suppresses optional Pro/automation/hotkey/hover/rehide/moving/status-item behaviors while preserving the visible Basic control, Settings, Diagnostics, reset, and recovery paths.

## Health, Recovery, And QA Harness

Startup is recovery-first. The app installs status items, checks Safe Mode and crash markers, runs health checks, applies recovery if needed, and only then honors collapsed launch preferences when the runtime is healthy.

Health checks cover status item installation, separator lengths, screen geometry, settings corruption, hotkey drift, stuck rehide/hover state, Pro permission mismatches, repeated Accessibility failures, stale scans, layout state, groups, dynamic hotkeys, and Private Access sessions.

Recovery can recreate status items, reset separator lengths, expand/reveal, disable risky runtime behaviors temporarily, disable Pro Mode, hide optional spacers/group items, clear unlock sessions, and request Safe Mode for the next launch.

`MenuBarFixtureApp` is a separate local-only fixture target. It creates deterministic menu bar items for QA and dogfood runs. The shipping app has no runtime dependency on it.

Dogfood Mode is local-only, off by default, and stores run/checklist/notes/export data under Application Support. Dogfood exports avoid screenshots, screen contents, telemetry, network data, live search text, and selected item identity.

## Testing And Release Evidence

Current important commands:

```sh
xcodebuild -list
xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build
xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
scripts/qa_preflight.sh
scripts/verify_privacy_boundary.sh
scripts/qa_dogfood_preflight.sh
scripts/build_release.sh --dry-run
scripts/build_release.sh --dry-run --install --verify-installed
```

Script families:

- Developer wrappers: `scripts/build_debug.sh` and `scripts/test.sh`.
- QA and fixture helpers: `scripts/qa_preflight.sh`, `scripts/qa_dogfood_preflight.sh`, `scripts/qa_installed_app_smoke.sh`, `scripts/qa_build_fixture.sh`, `scripts/qa_run_fixture.sh`, `scripts/qa_stop_fixture.sh`, `scripts/qa_collect_artifacts.sh`, `scripts/qa_network_watch.sh`, and `scripts/export_visual_smoke_screenshots.sh`.
- Release flow: `scripts/build_release.sh`, `scripts/release_archive.sh`, `scripts/release_export_app.sh`, `scripts/release_package_zip.sh`, `scripts/release_notarize.sh`, `scripts/release_staple.sh`, `scripts/release_install_local.sh`, `scripts/release_uninstall_local.sh`, and `scripts/release_clean.sh`.
- Verification: `scripts/verify_privacy_boundary.sh`, `scripts/verify_release_artifact.sh`, `scripts/verify_installed_app.sh`, and `scripts/release_validate_gatekeeper.sh`.

Release verification checks bundle identity, version/build, `LSUIElement`, app category, URL scheme, the expected sandbox state, no-network entitlements, hardened runtime, sensitive usage-string absence, code signature, ScreenCaptureKit linkage, `spctl`, and stapler status where relevant. The release and installed-app verifiers preserve already-high file limits, raise low soft limits before Gatekeeper/stapler checks, accept known non-notarized dry-run rejection wording, and fail unexpected resource errors such as `Too many open files`.

Latest evidence to consult:

- `docs/progress/phase-16-v0.1.3-competitive-core-catch-up.md`: Phase 16 competitive core catch-up ledger.
- `docs/progress/phase-17-20-v0.1.7-workspaces-function-bar-info-strip.md`: current Workspaces, Function Bar, Set Builder, and Info Strip validation ledger.
- `docs/progress/phase-17-v0.1.4-workspaces-foundation.md`: Workspaces Foundation implementation and audit ledger.
- `docs/progress/phase-18-v0.1.5-set-switcher-function-bar.md`: Function Bar Preview implementation and validation ledger.
- `docs/progress/phase-19-v0.1.6-linked-groups-set-builder.md`: linked Groups and Set Builder Preview implementation ledger.
- `docs/progress/phase-20-v0.1.7-info-strip-mvp.md`: Info Strip MVP implementation, audit fixes, and validation ledger.
- `docs/release/v0.1.7-release-notes.md`: current v0.1.7 release notes.
- `docs/release/v0.1.7-release-checklist.md`: current v0.1.7 release gate checklist.
- `docs/testing/manual-v0.1.7-workspaces-function-bar-info-strip-qa.md`: current preview manual QA matrix.
- `docs/testing/manual-v0.1.7-results.md`: current manual QA and automated-evidence record.
- `docs/release/v0.1.7-known-limitations.md`: current v0.1.7 limitations.
- `docs/release/v0.1.5-release-checklist.md`: historical Function Bar Preview release checklist.
- `docs/testing/installed-app-qa-2026-06-30-native-redesign.md`: installed-app acceptance pass after the native Settings redesign.
- `docs/release/v0.1.1-release-checklist.md`: historical v0.1.1 release gate checklist.
- `docs/progress/phase-12-v0.1.1-release-confidence.md`: release-confidence progress and validation ledger.
- `docs/progress/phase-13-v0.1.1-pro-workflow-completion.md`: Command Center / Pro workflow progress and validation ledger.
- `docs/progress/phase-14-v0.1.1-product-diet-guided-placement.md`: product diet, Arrange, Find & Rescue, and validation ledger.

The test suite has broad pure-logic coverage for settings, migration, diagnostics privacy, hiding/reveal/rehide/hover, Accessibility scanning/gates, Search, Second Bar, Command Center routing, status menu behavior, profiles, triggers, URL automation, App Intents, hotkeys, layout, icon moving safety/planning, groups, Private Access, health/recovery/Safe Mode, onboarding, dogfood, Application Support paths, and QA scripts. UI tests are smoke-level and mainly cover launch, Settings, diagnostics, unavailable states, Search, Second Bar requirements, visual structure, and window behavior.

For docs-only changes, a full build/test run is usually not necessary. For code, project, release-script, or target-membership changes, run the relevant `xcodebuild` and script gates and record exact results.

## Known Limitations

- Basic Mode is based on app-owned status items and normal macOS menu bar layout. It cannot privately or directly control arbitrary third-party menu extras.
- Users may need to command-drag the control/separators into useful positions.
- Accessibility metadata can be stale, missing, inconsistent, or unavailable depending on macOS and third-party apps.
- Find Icon and Second Bar reveal/highlight approximate known frames; they do not capture pixels or click arbitrary menu bar items.
- Second Bar is a metadata/icon browser, not a duplicate live menu bar.
- Placement Planner is advisory and non-mutating.
- New Item Inbox has live scan persistence, a Find & Rescue review list, and a conditional status-menu New Items row behind Pro Discovery gates; richer per-item placement actions remain deferred.
- Assisted Move / Icon Moving can fail on system items, protected items, or third-party items that resist command-drag movement.
- Private Access protects app-owned actions only; it is not encryption and does not hide already-visible system menu bar content.
- Import/export safe apply is merge-by-ID, not destructive full restore or stable competitor migration.
- Focus and Wi-Fi trigger providers remain model-level/deferred until safe providers exist.
- Spacing Labs apply/restore/reset UI remains constrained until backup/restore behavior is sufficiently proven.
- Developer ID export/notarization is deferred for the current internal/local alpha stage and requires external Apple credentials when public distribution becomes in scope.
- Several system behaviors still require physical QA outside repository automation.

## Phase History

- Phase 0: project skeleton, lifecycle, temporary menu item, Settings/Diagnostics foundation.
- Phase 1: permission-free Basic hiding MVP.
- Phase 2: Basic UX polish: auto-rehide, hover reveal, hotkey, always-hidden zone, Option-click reveal.
- Phase 3: Settings, onboarding, Launch at Login, diagnostics export, app support paths, reset actions.
- Phase 4: opt-in Pro Accessibility discovery.
- Phase 5: Find Icon search/reveal/highlight.
- Phase 6: Second Bar.
- Phase 7: Experimental Icon Moving.
- Phase 8: profiles, triggers, local URL automation.
- Phase 9: health, recovery, Safe Mode, wake/display hardening.
- Phase 9.1-9.5: alpha/release hardening, product identity cleanup, privacy verification, dogfood harness, installed-app workflow, safe defaults, v0.1 Basic Stable freeze.
- Phase 10: capacity/layout pack, Full Menu Bar Mode, crowded rescue, app-owned spacers, Spacing Labs.
- Phase 11: groups, Private Access, dynamic hotkeys, App Intents, import/export, migration assistant, profile integration.
- Phase 12: `v0.1.1` release confidence, public claims, feature-gate vocabulary, release tooling, installed-app QA, native cleanup onboarding, diagnostics export hardening.
- Phase 13: shared Command Center and cohesive Pro workflow completion.
- Phase 14: `v0.1.1` product diet, seven-section Settings shell, stable Guided Manual Arrange, Preview Placement Planner/New Item Inbox, Find & Rescue consolidation, and Experimental Assisted Move gating.
- Phase 15: `v0.1.2` core polish and manual-QA closeout: release identity, Settings/status-menu clarity, Arrange copy, Find & Rescue routes, Recovery lost-icons flow, Safe Mode menu path, crowded-rescue ask-before-switching, support/release docs, and validation evidence.
- Phase 16: `v0.1.3` competitive core catch-up: assisted move, shortcuts, crowded/notch polish, and expanded QA evidence.
- Phase 17: `v0.1.4` Workspaces foundation: local workspace models, validation, switching, diagnostics, and privacy boundary docs.
- Phase 18: `v0.1.5` Function Bar Preview: app-owned floating panel, set switcher, local command items, gated proxy actions, settings controls, diagnostics, and manual QA docs.
- Phase 19: `v0.1.6` linked groups and Set Builder Preview.
- Phase 20: `v0.1.7` Info Strip MVP and workspace display coordination.

## Roadmap

Immediate work:

- Branch future post-`v0.1.7` work separately from the sealed release tag so `main` keeps a clean release checkpoint.
- Finish the remaining physical/manual QA gates for live menu bar behavior, OS state changes, and current Preview surfaces.
- Keep the hardened preflight and dogfood scripts as the canonical automated gates, while tracking any future direct `xcodebuild test` runner/bootstrap instability with preserved logs.
- Harden live Pro Discovery planner behavior, New Item Inbox persistence, and Assisted Move on disposable third-party menu bar items through hands-on QA before making broader claims.
- Harden Workspaces, Function Bar, Set Builder, linked Groups, and Info Strip Preview through focused single-screen QA first, then external multi-display QA when hardware is available.
- Keep Developer ID Application credentials and real notarization/stapling/Gatekeeper validation deferred until public distribution becomes in scope.
- Keep public docs and Settings copy aligned with Stable/Preview/Labs/Experimental/Deferred statuses.

Near-term hardening:

- Shortcuts/App Intents real-device validation.
- Private Access prompt and unlock-session dogfood.
- Group/profile/hotkey automation workflows.
- Crowded menu rescue behavior on real crowded systems.
- Workspaces / Function Bar / Set Builder / Info Strip Preview integration hardening.
- Import/export compatibility and recovery testing.
- Spacing Labs backup/restore proving before broader exposure.

Post-`v0.1` exploration:

- Visual icon capture only after a separate privacy review.
- Focus and Wi-Fi trigger providers if they can satisfy the privacy model.
- Better notch/external-display behavior based on hands-on QA data.
- Safer icon moving if dogfood evidence justifies it.
- Competitor import only with narrow, honest claims and non-destructive semantics.

## Source-Of-Truth Docs

- `AGENTS.md`: coding-agent constraints and project rules.
- `README.md`: public-facing project overview.
- `docs/architecture/architecture-overview.md`: detailed architecture notes.
- `docs/plans/PHASE-16.md` through `docs/plans/PHASE-20.md`: Phase 16-20 implementation plans and definitions of done.
- `docs/progress/phase-16-v0.1.3-competitive-core-catch-up.md`, `docs/progress/phase-17-v0.1.4-workspaces-foundation.md`, `docs/progress/phase-18-v0.1.5-set-switcher-function-bar.md`, `docs/progress/phase-19-v0.1.6-linked-groups-set-builder.md`, `docs/progress/phase-20-v0.1.7-info-strip-mvp.md`, and `docs/progress/phase-17-20-v0.1.7-workspaces-function-bar-info-strip.md`: current Phase 16-20 progress and validation ledgers.
- `docs/release/v0.1.7-release-notes.md`, `docs/release/v0.1.7-release-checklist.md`, and `docs/release/v0.1.7-known-limitations.md`: current release notes, gate checklist, and limitations.
- `docs/features/arrange-v0.1.3.md`, `docs/features/find-rescue-v0.1.3.md`, `docs/features/second-bar-v0.1.3.md`, `docs/features/new-item-inbox-v0.1.3.md`, `docs/features/workspaces-v0.1.7-preview.md`, `docs/features/function-bar-v0.1.7-preview.md`, `docs/features/set-builder-v0.1.6-preview.md`, `docs/features/linked-groups-v0.1.6-preview.md`, and `docs/features/info-strip-v0.1.7-preview.md`: current Phase 16-20 feature behavior.
- `docs/testing/manual-v0.1.7-workspaces-function-bar-info-strip-qa.md` and `docs/testing/manual-v0.1.7-results.md`: current manual QA matrix and evidence record.
- `docs/support/settings-overview.md`, `docs/support/arrange-menu-bar-items.md`, `docs/support/i-cant-find-my-icons.md`, `docs/support/icon-moving-boundary.md`, `docs/support/troubleshooting.md`, `docs/support/backup-restore.md`, and `docs/support/safe-mode.md`: current user support docs.
- `docs/features/`: feature notes for Basic behavior, Pro discovery, Find Icon, Second Bar, profiles, triggers, automation, diagnostics, dogfood, health/recovery, and Preview/Labs/Experimental surfaces.

Historical/reference docs, superseded for active v0.1.7 claims by the current docs above:

- `docs/product/v0.1.1-product-taxonomy.md` and `docs/product/v0.1.1-product-diet.md`: Phase 14 product-shape reference.
- `docs/features/arrange-v0.1.1.md`, `docs/features/guided-manual-arrange-v0.1.1.md`, `docs/features/placement-planner-v0.1.1.md`, and `docs/features/assisted-move-v0.1.1-experimental.md`: historical icon-placement layers.
- `docs/features/find-rescue-v0.1.1.md` and `docs/features/new-item-inbox-v0.1.1.md`: historical consolidated item finding/rescue workflows.
- `docs/features/basic-mode-v0.1.1-contract.md`: historical Basic Mode contract.
- `docs/features/pro-mode-v0.1.1-boundary.md`: historical Pro permission boundary.
- `docs/release/v0.1.1-feature-gates.md`: historical feature status vocabulary and gates.
- `docs/release/v0.1.1-public-claims.md`: historical allowed and forbidden public claims.
- `docs/release/v0.1.1-known-limitations.md`: historical v0.1.1 limitations.
- `docs/release/v0.1.1-release-checklist.md`: historical v0.1.1 release checklist and blockers.
- `docs/release/v0.1.1-release-runbook.md` and `docs/release/v0.1.1-local-dry-run.md`: historical release execution flow.
- `docs/privacy/v0.1.1-privacy-claims.md`: historical privacy claims.
- `docs/testing/manual-v0.1.1-system-qa.md`: historical v0.1.1 manual system QA matrix.
- `docs/testing/installed-app-qa-2026-06-30-native-redesign.md`: latest dated physical installed-app QA evidence.
- `docs/design/hig-native-2026-06-30/`: native macOS redesign HIG inventory, route inventory, template map, and generated mockups.
- `docs/design/redesign-2026-06/`: earlier redesign guidance pack and visual direction.
- `docs/progress/phase-12-v0.1.1-release-confidence.md`: Phase 12 validation record.
- `docs/progress/phase-13-v0.1.1-pro-workflow-completion.md`: Phase 13 progress record.
- `docs/progress/phase-14-v0.1.1-product-diet-guided-placement.md`: Phase 14 progress record.
