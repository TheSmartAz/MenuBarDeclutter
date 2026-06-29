# Phase 10 & 11 Implementation Gap Analysis

Date: 2026-06-29

## Summary

Phases 10 and 11 have been implemented with core domain models, services,
persistence, and unit tests. Build succeeds, privacy verification passes,
and 79 new tests pass. However, several UI surfaces, health integrations,
and secondary features remain to be implemented.

## Build & Test Status

- `xcodebuild build -scheme MenuBarDeclutter`: **BUILD SUCCEEDED**
- `xcodebuild build-for-testing`: **TEST BUILD SUCCEEDED**
- `scripts/verify_privacy_boundary.sh`: **PASSED**
- Phase 10 tests: 36 — all passing
- Phase 11 tests: 43 — all passing
- Existing tests: still passing (verified SettingsStore + DiagnosticsLogger suites)

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

## Phase 10 — What's Missing

### 1. Health and Safe Mode Integration (Task 11)
**Status: Not implemented**

The plan called for extending `HealthService` and `RecoveryService` with:
- Corrupted spacer store detection
- Invalid spacer lengths
- Missing app-owned spacer status items
- Invalid full menu bar mode state
- Stuck full menu bar mode auto-exit
- Spacing backup missing while custom spacing says applied
- Spacing apply failure
- Layout capacity stale if Pro scan stale
- Crowded rescue repeated too often

Recovery actions needed:
- Reset spacer store after backup
- Hide optional spacer items
- Exit Full Menu Bar Mode
- Reset crowded rescue state
- Reset menu bar spacing settings to safe app defaults (without mutating global defaults)

Safe Mode behavior needed:
- Disable auto-enter full menu mode
- Disable crowded rescue automation
- Hide optional spacer status items
- Disable spacing apply UI
- Keep Reset Layout and Diagnostics visible

**Files to create/modify:**
- `Health/HealthService.swift` — add Phase 10 checks to `HealthCheckSnapshot` and `makeReport`
- `Health/RecoveryService.swift` — add Phase 10 recovery actions
- `Layout/LayoutCoordinator.swift` — add `enterSafeMode()` (stub exists but needs HealthService wiring)

### 2. Spacer Management UI (Task 7, Task 9)
**Status: Basic toggles only, no list/editor**

The plan called for:
- `SpacerItemEditorView` — edit individual spacer properties
- `SpacerItemListView` — list, reorder, add/remove spacers
- Add Divider / Add Thin Spacer / Add Wide Spacer / Add Label / Add Icon buttons
- Hide All Spacer Markers button
- Reset Spacers button

The current `LayoutSettingsView` has basic enable/markers toggles but no
list or editor UI.

**Files to create:**
- `Layout/SpacerItemListView.swift`
- `Layout/SpacerItemEditorView.swift`

### 3. Detailed Layout Views (Task 9)
**Status: Consolidated into sections, no separate views**

The plan called for separate views:
- `LayoutCapacityView` — show capacity ratio, slots, known items, warnings, recommended action
- `LayoutSuggestionsView` — list suggestions with actions
- `FullMenuBarModeSettingsView`
- `CrowdedRevealSettingsView`
- `SpacerItemsSettingsView`
- `MenuBarSpacingLabsView`

These were consolidated into sections within `LayoutSettingsView`. The
capacity view does not show live estimate data, and the suggestions view
does not list actual suggestions.

### 4. Missing Tests (Task 12)
**Status: Not written**

- `LayoutHealthTests` — health detects corrupted Phase 10 state
- `LayoutURLAutomationTests` — URL automation throttling for new commands

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

## Phase 11 — What's Missing

### 5. Groups Settings UI (Task 2)
**Status: Not implemented**

No Settings tab for Groups exists. Users cannot create, edit, or manage
groups through the UI.

**Files to create:**
- `Groups/IconGroupsSettingsView.swift` — main Settings tab
- `Groups/IconGroupEditorView.swift` — create/edit group (name, symbol, color, notes)
- `Groups/IconGroupItemPickerView.swift` — pick items from AX snapshots
- `Groups/IconGroupRowView.swift` — row in the groups list
- `Groups/IconGroupPreviewView.swift` — preview matched items

**SettingsStore section to add:**
- `SettingsSection.groups` — sidebar item with "person.2" icon

### 6. Group Panel (Task 3)
**Status: Not implemented**

No group panel window exists. Users cannot browse group items in a panel.

**Files to create:**
- `Groups/IconGroupPanelWindowController.swift` — NSPanel + SwiftUI hosting
- `Groups/IconGroupPanelRootView.swift` — SwiftUI root with search, keyboard nav
- `Groups/IconGroupPanelItemRowView.swift` — item row in panel
- `Groups/IconGroupActivationService.swift` — visible/hidden/always-hidden activation logic
- `Groups/IconGroupStatusItemController.swift` — optional app-owned group status items
- `Groups/IconGroupStatusItemFactory.swift` — NSStatusItem creation for groups

### 7. Dynamic Hotkey Registration (Task 5)
**Status: Store and conflict detection only, no actual registration**

`HotkeyBindingStore` can save/load bindings, and `HotkeyConflictDetector`
can detect conflicts, but no service actually registers hotkeys with the
system via `GlobalHotkeyManager`.

**Files to create:**
- `Hotkeys/DynamicHotkeyRegistrationService.swift` — registers/unregisters
  dynamic hotkeys via `GlobalHotkeyManager`, respects max limit, handles
  protected action gating

### 8. Private Access Settings UI (Task 4)
**Status: Not implemented**

No Settings tab for Private Access exists. Users cannot enable/configure
Private Access through the UI.

**Files to create:**
- `PrivateAccess/PrivateAccessSettingsView.swift` — toggle Private Access,
  configure protected surfaces, unlock duration, test auth, clear session

**SettingsStore section to add:**
- `SettingsSection.privateAccess` — sidebar item with "lock.fill" icon

### 9. Hotkeys Settings UI (Task 5)
**Status: Not implemented**

No Settings tab for dynamic hotkeys exists.

**Files to create:**
- `Hotkeys/DynamicHotkeysSettingsView.swift` — list bindings, add/edit/delete,
  conflict warnings, disable all

**SettingsStore section to add:**
- `SettingsSection.hotkeys` — sidebar item with "keyboard" icon

### 10. Automation/Shortcuts Settings UI (Task 6)
**Status: Not implemented**

No Settings tab for App Intents/Shortcuts exists.

**Files to create:**
- `Shortcuts/AutomationSettingsView.swift` — show available intents, toggle
  profile apply, toggle Labs access, link to Shortcuts app

**SettingsStore section to add:**
- `SettingsSection.automation` — sidebar item with "link" icon

### 11. Import/Export Settings UI (Task 7)
**Status: Not implemented**

No Settings tab for Import/Export exists.

**Files to create:**
- `Migration/MigrationAssistantWindowController.swift` — NSWindowController
- `Migration/MigrationAssistantRootView.swift` — SwiftUI root with
  export/import/dry-run/backup list/restore

**SettingsStore section to add:**
- `SettingsSection.importExport` — sidebar item with "arrow.up.arrow.down" icon

### 12. Profile Integration (Task 8)
**Status: Not implemented**

`ProfileModel` was not extended with Phase 11 features.

**Changes needed in `Profiles/ProfileModel.swift`:**
- Add `groupVisibilityPreferences: [UUID: Bool]`
- Add `protectedGroupIDs: Set<UUID>`
- Add `dynamicHotkeyPreferences: [UUID]?`
- Add `layoutModePreference: LayoutMode?`
- Add `fullMenuBarModePreference: Bool?`
- Add `spacingPresetPreference: String?` (Labs-gated)

**Changes needed in `Profiles/ProfileApplicationService.swift`:**
- Profile apply can show/hide group status items
- Profile apply can show Second Bar filtered to a group
- Profile apply can enable/disable spacer visibility
- Profile apply can enter/exit Full Menu Bar Mode
- Profile dry-run must show group/Labs/protected changes

### 13. Diagnostics, Health, and Safe Mode (Task 10)
**Status: Not implemented**

HealthService and SafeMode were not extended for Phase 11.

**Health checks needed:**
- Corrupted group store
- Duplicate group names
- Invalid group item refs
- Missing group status item
- Protected access misconfiguration
- Stale unlock session
- Dynamic hotkey conflicts
- Corrupted hotkey binding store
- Corrupted import backup
- App Intent disabled/misconfigured state
- Profile references missing group

**Safe Mode behavior needed:**
- Disable dynamic hotkeys
- Disable group status items
- Disable protected action prompts (except Settings/Diagnostics)
- Disable App Intents (except safe commands)
- Disable imports
- Preserve Settings/Diagnostics/Reset access

**Diagnostics export privacy:**
- Protected group names redacted by default
- Hotkey target identity redacted if protected
- Import/export file paths app-support-relative or redacted

### 14. Missing Tests (Task 11)
**Status: Not written**

- `IconGroupPanelActivationTests`
- `IconGroupImportExportTests`
- `DynamicHotkeyRegistrationServiceTests`
- `HotkeyProtectedActionTests`
- `AppIntentResultMapperTests`
- `AppIntentSafeModeTests`
- `AppIntentPrivateAccessTests`
- `AppIntentAutomationPauseTests`
- `ImportBackupServiceTests`
- `ExperimentalFlagImportSafetyTests`
- `ProfileGroupIntegrationTests`
- `ProfilePrivateAccessGateTests`
- `ProfileLayoutPreferenceTests`
- `Phase11HealthTests`
- `SafeModePhase11Tests`

### 15. Missing Docs (Task 13)
**Status: Partially created**

Created:
- `docs/phase-11/README.md`
- `docs/phase-11/privacy-boundary.md`
- `docs/phase-11/known-limitations.md`

Not created:
- `docs/phase-11/private-access-plan.md`
- `docs/phase-11/power-user-plan.md`
- `docs/phase-11/app-intents-plan.md`
- `docs/phase-11/import-export-format.md`
- `docs/phase-11/group-schema.md`
- `docs/phase-11/hotkey-schema.md`
- `docs/phase-11/risk-register.md`
- `docs/phase-11/manual-qa.md`
- `docs/release/phase-11-release-notes.md`
- `docs/testing/phase-11-*.md` (5 QA docs)

---

## Priority Recommendation

1. **High: Settings UI** (items 5, 8, 9, 10, 11) — makes features usable
2. **High: Group Panel** (item 6) — core Groups functionality
3. **Medium: Dynamic hotkey registration** (item 7) — makes hotkeys functional
4. **Medium: Profile integration** (item 12) — connects profiles to groups/layout
5. **Medium: Health/Safe Mode** (items 1, 13) — reliability
6. **Low: Remaining tests and docs** (items 4, 14, 15) — completeness
