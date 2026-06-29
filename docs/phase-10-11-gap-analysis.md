# Phase 10 & 11 Implementation Gap Analysis

Date: 2026-06-29

## Summary

Phases 10 and 11 have been implemented with core domain models, services,
persistence, Settings UI, runtime wiring, health/Safe Mode integration,
diagnostics coverage, focused docs, and unit tests. The follow-up pass on
2026-06-29 closed the previously listed remaining work.

## Build & Test Status

- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'`: **TEST SUCCEEDED**
- `scripts/verify_privacy_boundary.sh`: **PASSED**
- `scripts/qa_preflight.sh`: **PASSED**
- Unit/Swift Testing: 310 tests in 60 suites passed
- UI tests: 7 tests passed
- Phase 10 tests: 36 — all passing
- Phase 11 direct tests plus integration coverage — all passing

---

## Phase 10 — What's Done

### Core Services (17 files in `Layout/`)
- [x] `LayoutCoordinator` — wired into `AppEnvironment`
- [x] `LayoutCapacityService` — Basic geometry + Pro AX estimates
- [x] `LayoutSuggestionService` — non-invasive suggestions
- [x] `FullMenuBarModeService` — enter/exit/auto-exit with state restore
- [x] `CrowdedRevealRescueService` — Second Bar fallback
- [x] `SpacerItemModel` / `SpacerItemStore` / `SpacerStatusItemFactory` / `SpacerStatusItemController`
- [x] `MenuBarSpacingService` — Labs-only, dry-run by default, backup/restore/reset
- [x] `MenuBarSpacingCommandRunner` protocol + Default + Mock implementations
- [x] `MenuBarSpacingDefaultsKeys` — isolated constants
- [x] `LayoutMode`, `LayoutSettings`, `LayoutCapacityEstimate`, `LayoutSuggestion`
- [x] `MenuBarSpacingPreset`, `MenuBarSpacingBackup`

### Settings & Integration
- [x] `LayoutSettingsView` — full Layout tab with Capacity, Full Menu Bar Mode,
      Crowded Reveal, Spacer Items, Spacing Labs sections
- [x] `SettingsSection.layout` added to sidebar
- [x] Status menu items: Enter/Exit Full Menu Bar Mode, Layout Suggestions,
      Add Divider, Add Spacer, Toggle Spacer Markers, Open Layout Settings,
      Reveal Inline Anyway
- [x] URL automation: `full-menu-bar`, `exit-full-menu-bar`, `layout-suggestions`
- [x] Diagnostics `.layout` category
- [x] `SettingsStore` Phase 10 fields with defaults, clamping, persistence, reset
- [x] `SettingsMigrationService` snapshot extended for Phase 10 keys

### Tests (36 tests, all passing)
- [x] `LayoutCapacityServiceTests` — 4 tests
- [x] `LayoutSuggestionServiceTests` — 4 tests
- [x] `FullMenuBarModeServiceTests` — 5 tests
- [x] `CrowdedRevealRescueServiceTests` — 5 tests
- [x] `SpacerItemStoreTests` — 5 tests
- [x] `SpacerItemModelTests` — 2 tests
- [x] `MenuBarSpacingServiceTests` — 6 tests
- [x] `LayoutSettingsDefaultsTests` — 5 tests

### Docs
- [x] `docs/phase-10/README.md`
- [x] `docs/phase-10/privacy-boundary.md`
- [x] `docs/phase-10/manual-qa.md`
- [x] `docs/phase-10/known-limitations.md`
- [x] `docs/status/phase-10-starting-audit.md`
- [x] `docs/status/phase-10-final-report.md`

---

## Phase 10 — Follow-up Work Resolved

### Health and Safe Mode Integration
**Status: Resolved on 2026-06-29**

- `HealthService` now models Phase 10 layout state in `HealthCheckSnapshot`.
- `RecoveryService` can exit Full Menu Bar Mode and hide optional spacer items.
- `AppHealthCoordinator` wires layout recovery through `LayoutCoordinator`.
- Safe Mode exits Full Menu Bar Mode and hides optional spacers.

### Spacer Management UI
**Status: Resolved on 2026-06-29**

- `SpacerItemListView` lists app-owned spacer/divider items.
- `SpacerItemEditorView` edits spacer type, title, width, marker, and visibility.
- `LayoutSettingsView` now surfaces live capacity, suggestions, spacer
  management, and Spacing Labs controls.

### Diagnostics and Tests
**Status: Resolved on 2026-06-29**

- Diagnostics export includes Phase 10 layout, spacer, and spacing settings.
- `Phase10Phase11HealthTests` covers layout recovery conditions.
- `DiagnosticsExportTests` locks the expanded diagnostics schema.

---

## Phase 11 — What's Done

### Groups Domain (7 files in `Groups/`)
- [x] `IconGroup` — model with id, name, symbol, color, notes, protection, visibility, sort
- [x] `IconGroupItemRef` — bundle ID / snapshot ID / title / zone / manual label matching
- [x] `IconGroupStore` — JSON persistence with corruption backup/reset
- [x] `IconGroupMatcher` — priority-based matching (bundle → stableID → title → app → zone)
- [x] `IconGroupSort` — deterministic sort by sortOrder then name
- [x] `IconGroupValidation` — empty name, duplicate name detection
- [x] `IconGroupImportExport` — encode/decode helpers

### Private Access (6 files in `PrivateAccess/`)
- [x] `ProtectedResource` — revealAll, alwaysHidden, findIcon, secondBar, iconMoving, protectedGroup, profileApply, spacingLabs, appIntent
- [x] `PrivateAccessPolicy` — value-type snapshot
- [x] `AuthenticationService` — protocol + `LocalAuthenticationService` + `MockAuthenticationService`
- [x] `UnlockSession` — cached unlock with configurable timeout
- [x] `PrivateAccessCoordinator` — owns auth service, unlock session, policy
- [x] `ProtectedActionGate` — gates protected actions behind auth

### Hotkeys (4 new files in `Hotkeys/`)
- [x] `HotkeyAction` — Codable enum with 9 action cases
- [x] `HotkeyBinding` — Codable model with key/modifiers/conflict detection
- [x] `HotkeyBindingStore` — JSON persistence with corruption recovery
- [x] `HotkeyConflictDetector` — conflict detection between bindings

### Shortcuts (3 files in `Shortcuts/`)
- [x] `AppIntentExecutionService` — centralized intent execution with Safe Mode/pause/Labs gating
- [x] `AppIntentResultMapper` — maps results to user-facing strings
- [x] `MenuBarDeclutterShortcutsProvider` — 11 App Intents + AppShortcutsProvider:
  - Expand, Collapse, Reveal All, Show/Hide Second Bar, Enter/Exit Full Menu Bar Mode
  - Apply Profile, Pause/Resume Automation, Set Layout Spacing Preset

### Migration (5 files in `Migration/`)
- [x] `SettingsExportPackage` — versioned export with settings, profiles, groups, hotkeys, spacers
- [x] `SettingsExportService` — create and encode export packages
- [x] `SettingsImportService` — decode, dry-run with conflict/experimental flag detection
- [x] `ImportBackupService` — backup creation and listing
- [x] `ProfilePack` / `ProfilePackStore` — reusable profile packs

### Settings & Integration
- [x] `SettingsStore` Phase 11 fields: groups, private access, app intents, dynamic hotkeys
- [x] `AppEnvironment` wired with `groupStore`, `privateAccessCoordinator`, `protectedActionGate`, `hotkeyBindingStore`, `intentExecutionService`
- [x] `AppEnvironment.shared` for App Intents access
- [x] `applyProfileNamed` exposed for intent execution

### Tests (43 tests, all passing)
- [x] `IconGroupStoreTests` — 3 tests (save/load, corruption, reset)
- [x] `IconGroupMatcherTests` — 3 tests (bundle ID, stable ID, unavailable)
- [x] `IconGroupValidationTests` — 3 tests (empty, duplicate, valid)
- [x] `ProtectedActionGateTests` — 6 tests (success, cancel, failure, cached, unprotected, disabled)
- [x] `UnlockSessionTests` — 4 tests (active, expiry, clear, remaining)
- [x] `PrivateAccessPolicyTests` — 3 tests (disabled, enabled, defaults)
- [x] `HotkeyBindingStoreTests` — 3 tests (save/load, corruption, reset)
- [x] `HotkeyConflictDetectorTests` — 4 tests (conflict, different keys, new binding, same binding)
- [x] `AppIntentExecutionServiceTests` — 8 tests (expand, safe mode, profile, labs, pause/resume)
- [x] `SettingsExportImportTests` — 4 tests (export, dry-run, conflict, experimental)
- [x] `ProfilePackTests` — 2 tests (save/load, list)

### Docs
- [x] `docs/phase-11/README.md`
- [x] `docs/phase-11/privacy-boundary.md`
- [x] `docs/phase-11/known-limitations.md`
- [x] `docs/status/phase-11-starting-audit.md`
- [x] `docs/status/phase-11-final-report.md`

---

## Phase 11 — Follow-up Work Resolved

### Settings UI
**Status: Resolved on 2026-06-29**

- `IconGroupsSettingsView` plus group editor, picker, row, and preview views.
- `PrivateAccessSettingsView` for policy toggles, unlock duration, test auth,
  and clearing active sessions.
- `DynamicHotkeysSettingsView` for enabling, adding, disabling, and deleting
  dynamic bindings with conflict warnings.
- `AutomationSettingsView` for App Intents, profile apply, Labs access, and
  Shortcuts app launch.
- `MigrationAssistantRootView` and `MigrationAssistantWindowController` for
  export, import dry-run, and backups.
- `SettingsRootView` and `SettingsWindowController` expose the new sections.

### Group Panel and Status Items
**Status: Resolved on 2026-06-29**

- `IconGroupPanelWindowController` hosts the panel.
- `IconGroupPanelRootView` provides search and keyboard navigation.
- `IconGroupActivationService` performs conservative reveal/highlight actions.
- `IconGroupStatusItemFactory` and `IconGroupStatusItemController` manage
  optional app-owned group status items.

### Dynamic Hotkey Registration
**Status: Resolved on 2026-06-29**

- `DynamicHotkeyRegistrationService` registers enabled, non-conflicting dynamic
  bindings with `GlobalHotkeyManager`.
- Registration respects max limits, disabled settings, Safe Mode, Pro-only
  actions, and protected action gating.
- `GlobalHotkeyManager.RegistrationIdentifier` supports dynamic UUID-backed
  registrations.

### Profile Integration
**Status: Resolved on 2026-06-29**

- `ProfileModel` schema v2 includes group visibility, protected group IDs,
  dynamic hotkey preferences, layout mode, full menu bar preference, and
  spacing preset preference.
- `ProfileApplicationService` dry-run and apply flows report group, layout,
  protected, and Labs changes.
- Profile application can refresh groups, toggle group status items, enter or
  exit Full Menu Bar Mode, and apply Labs-gated spacing only when allowed.

### Diagnostics, Health, and Safe Mode
**Status: Resolved on 2026-06-29**

- Diagnostics export includes Phase 11 settings and explicitly excludes
  protected group names, protected hotkey targets, and import/export paths.
- `HealthService` detects duplicate groups, group status items visible while
  disabled, dynamic hotkey conflicts, dynamic hotkeys registered while disabled,
  and active Private Access unlock sessions while Private Access is disabled.
- `RecoveryService` can disable dynamic hotkeys, hide group status items, and
  clear Private Access unlock sessions.
- `AppHealthCoordinator` wires Phase 11 snapshots and recovery hooks.

### Tests and Docs
**Status: Resolved on 2026-06-29**

- Added `DynamicHotkeyRegistrationServiceTests`.
- Added `ProfilePhase11IntegrationTests`.
- Added `Phase10Phase11HealthTests`.
- Expanded `DiagnosticsExportTests`.
- Added Phase 10 and Phase 11 release notes, QA docs, schemas, risk register,
  and plans.
