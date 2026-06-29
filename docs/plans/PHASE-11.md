Implement New Phase 11 — Private Access & Power User Pack.

Context:
MenuBarDeclutter is a native macOS 26.0+ menu bar utility. Phases 0–9.1 are implemented. New Phase 10 added layout/capacity features and kept ScreenCaptureKit deferred.

Phase 11 goal:
Add private access controls and power-user organization features without adding Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring, network access, telemetry, or cloud sync.

Hard constraints:
1. Do not implement ScreenCaptureKit.
2. Do not request Screen Recording.
3. Do not add Apple Events.
4. Do not add Input Monitoring.
5. Do not add network access.
6. Do not add telemetry.
7. Do not add cloud sync.
8. Do not use private APIs.
9. Do not copy competitor code.
10. Keep Basic Mode fully usable without Accessibility.
11. Keep Pro Mode opt-in.
12. Keep icon moving disabled by default and experimental.
13. Touch ID/password lock must use LocalAuthentication only.
14. Do not store biometric data.
15. Do not log protected item names in diagnostics exports unless redacted.
16. App Intents must honor privacy locks, automation pause, and Pro requirements.
17. Import must be explicit and user-selected; do not scrape competitor files automatically.
18. Do not silently run bulk icon moves from groups, profiles, imports, or shortcuts.
Task 0 — Phase 11 planning docs
Create:
- docs/phase-11/README.md
- docs/phase-11/private-access-plan.md
- docs/phase-11/power-user-plan.md
- docs/phase-11/privacy-boundary.md
- docs/phase-11/risk-register.md
- docs/phase-11/manual-qa.md
- docs/status/phase-11-starting-audit.md

Audit:
1. Existing Search snapshots.
2. Existing Second Bar item derivation.
3. Existing Profiles/ProfileStore.
4. Existing Hotkeys/GlobalHotkeyManager.
5. Existing URL automation.
6. Existing Settings tabs.
7. Existing Diagnostics export privacy rules.
8. Existing Safe Mode behavior.
9. Existing Phase 10 Layout module.

Document Phase 11 non-goals:
- no ScreenCaptureKit.
- no screen/pixel capture.
- no AppleScript dictionary.
- no Apple Events.
- no network/cloud sync.
- no telemetry.
- no automatic competitor config scraping.

Acceptance criteria:

- Phase 11 docs exist.
- Starting build/test/privacy status is recorded.
Task 1 — Icon Groups domain model and store
Create module:
- Groups/

Create files:
- Groups/IconGroup.swift
- Groups/IconGroupItemRef.swift
- Groups/IconGroupStore.swift
- Groups/IconGroupMatcher.swift
- Groups/IconGroupSort.swift
- Groups/IconGroupValidation.swift
- Groups/IconGroupImportExport.swift

IconGroup fields:
- id: UUID
- name: String
- symbolName: String?
- colorName: String?
- notes: String?
- isEnabled: Bool
- isProtected: Bool
- showInSecondBar: Bool
- showAsStatusItem: Bool
- sortOrder: Int
- itemRefs: [IconGroupItemRef]
- createdAt: Date
- updatedAt: Date

IconGroupItemRef supports:
- bundleIdentifier
- appName
- snapshotStableID
- titleContains
- zone
- manualLabel

Matching rules:
- Prefer bundleIdentifier.
- Then snapshotStableID.
- Then title/appName fallback.
- If multiple items match, preserve deterministic ordering.
- Unknown/missing items should be shown as unavailable, not deleted automatically.

Storage:
- Application Support/MenuBarDeclutter/Groups/groups.json
- Versioned JSON schema.
- Corruption handling:
  - back up corrupted file to Backups/.
  - reset to empty groups.
  - log warning.
- Import/export helpers.

SettingsStore additions:
- groupsEnabled: Bool default true
- groupStatusItemsEnabled: Bool default false
- protectedGroupsRequireAuth: Bool default false
- groupsJSONVersion: Int default 1

Diagnostics:
- group count.
- protected group count.
- group store path redacted or app-support-relative.
- last group action.

Tests:
- save/load.
- corrupted JSON backup.
- matching by bundle id.
- matching by stable ID.
- matching unavailable item.
- validation rejects empty/duplicate group names.

Acceptance criteria:

- Groups can be stored and loaded.
- Group matching works against mock MenuBarItemSnapshot values.
- Corruption does not crash app.
Task 2 — Groups UI
Create UI:
- Groups/IconGroupsSettingsView.swift
- Groups/IconGroupEditorView.swift
- Groups/IconGroupItemPickerView.swift
- Groups/IconGroupRowView.swift
- Groups/IconGroupPreviewView.swift

Add Settings tab/section:
- Settings -> Groups

Features:
1. Create group.
2. Rename group.
3. Choose SF Symbol.
4. Optional color label using semantic colors only.
5. Add items from current AX snapshots.
6. Add item manually by bundle ID.
7. Add item manually by app name/title contains.
8. Remove item from group.
9. Reorder groups.
10. Reorder items inside group.
11. Toggle show in Second Bar.
12. Toggle show as status item.
13. Toggle protected group.
14. Export group.
15. Import group.

Requirement states:
- If Pro Mode unavailable:
  - allow manual bundle-id groups.
  - show “Enable Pro Mode for current menu bar item picker.”
- If Accessibility missing:
  - show manual entry and unavailable picker.

Privacy:
- Do not show protected group item names in diagnostics export unless redacted.
- UI can show them locally.

Acceptance criteria:
- User can create and edit groups.
- Groups work even if Pro Mode is unavailable, though item picker is limited.
- Settings remain usable without Accessibility.
Task 3 — Group Panel and Second Bar integration
Create:
- Groups/IconGroupPanelWindowController.swift
- Groups/IconGroupPanelRootView.swift
- Groups/IconGroupPanelItemRowView.swift
- Groups/IconGroupActivationService.swift
- Groups/IconGroupStatusItemController.swift
- Groups/IconGroupStatusItemFactory.swift

Group panel:
- NSPanel + SwiftUI.
- Shows group items.
- Keyboard navigation.
- Search within group.
- Escape dismiss.
- Select item:
  - if visible: highlight original item.
  - if hidden: reveal needed zone and highlight.
  - if always-hidden: reveal-all if allowed and highlight.
  - no automatic click unless existing experimental activation setting allows it.

Second Bar integration:
- Add group filter.
- Add “Groups” section if enabled.
- Allow showing group chips.
- Selecting a group opens group panel.

Optional group status items:
- App-owned NSStatusItem for selected groups.
- Default disabled.
- User can Command-drag group status item.
- Click opens group panel.
- Right click opens group menu:
  - Open Group
  - Edit Group
  - Hide Group Status Item
- Safe Mode hides optional group status items.

Diagnostics:
- group panel visible.
- last opened group redacted if protected.
- group status item count.
- last group activation outcome.

Tests:
- group activation visible/hidden/always-hidden decisions.
- protected group requires auth once Task 4 lands.
- Second Bar filtering by group.

Acceptance criteria:

- Groups appear in Second Bar.
- Group panel works with keyboard.
- Optional group status items work and are disabled by default.
- No new permissions are required.
Task 4 — Private Access with LocalAuthentication
Create module:
- PrivateAccess/

Create files:
- PrivateAccess/ProtectedResource.swift
- PrivateAccess/PrivateAccessPolicy.swift
- PrivateAccess/AuthenticationService.swift
- PrivateAccess/LocalAuthenticationService.swift
- PrivateAccess/MockAuthenticationService.swift
- PrivateAccess/UnlockSession.swift
- PrivateAccess/PrivateAccessCoordinator.swift
- PrivateAccess/ProtectedActionGate.swift

ProtectedResource cases:
- revealAll
- alwaysHiddenZone
- findIcon
- secondBar
- iconMoving
- protectedGroup(UUID)
- profileApply
- layoutSpacingLabs
- appIntent(String)

SettingsStore additions:
- privateAccessEnabled: Bool default false
- privateAccessProtectAlwaysHidden: Bool default false
- privateAccessProtectSecondBar: Bool default false
- privateAccessProtectFindIcon: Bool default false
- privateAccessProtectIconMoving: Bool default true
- privateAccessProtectSpacingLabs: Bool default true
- privateAccessUnlockDurationSeconds: Double default 300
- privateAccessLastAuthStatus: String?
- privateAccessAllowDevicePasswordFallback: Bool default true

Authentication:
- Use LAContext.
- Prefer .deviceOwnerAuthentication if password fallback is allowed.
- Use clear localizedReason.
- Do not store biometric data.
- Do not log biometric details.
- Store only success/failure/cancel status.
- Cache successful unlock in UnlockSession for configured timeout.
- Cancel should leave action blocked.
- Safe Mode should allow user to open Settings/Diagnostics and disable Private Access, but should not automatically reveal protected groups.

ProtectedActionGate:
- All protected actions must call gate before execution.
- If auth required and unavailable:
  - show unavailable explanation.
- If user cancels:
  - no action.
- If auth succeeds:
  - execute action.
- If auth fails:
  - log warning and keep locked.

Protect:
- reveal all if setting enabled.
- always-hidden reveal if setting enabled.
- opening protected groups.
- opening Second Bar if setting enabled.
- Find Icon if setting enabled.
- icon moving by default.
- spacing labs apply/restore/reset by default.

UI:
- Settings -> Private Access.
- Toggle Private Access.
- Explain Touch ID/device password.
- Toggle protected surfaces.
- Unlock duration.
- Test Authentication button.
- Clear Unlock Session.

Diagnostics:
- private access enabled.
- active unlock session yes/no.
- protected resources enabled.
- last auth status.
- protected group names redacted in exports.

Tests:
- auth success executes action.
- auth cancel blocks action.
- auth failure blocks action.
- unlock session expiry.
- password fallback setting.
- protected group redaction.
- Safe Mode behavior.

Acceptance criteria:

- Private Access is off by default.
- No biometric data is stored.
- Protected actions are gated.
- Cancel/failure safely blocks action.
- Diagnostics export remains privacy-safe.
Task 5 — Per-icon and per-group hotkeys
Extend Hotkeys module.

Create:
- Hotkeys/HotkeyBinding.swift
- Hotkeys/HotkeyBindingStore.swift
- Hotkeys/HotkeyAction.swift
- Hotkeys/HotkeyConflictDetector.swift
- Hotkeys/DynamicHotkeyRegistrationService.swift

HotkeyAction cases:
- revealAndHighlightItem(ref)
- openGroup(UUID)
- openSecondBarFilteredToGroup(UUID)
- openSecondBarFilteredToItem(ref)
- applyProfile(UUID or name)
- enterFullMenuBarMode
- exitFullMenuBarMode
- pauseAutomation
- resumeAutomation

Rules:
- All dynamic hotkeys disabled by default.
- Existing Basic visibility hotkey and Find Icon hotkey continue to work.
- Detect conflicts before registering.
- Maximum dynamic hotkeys default 20.
- Hotkey conflict should not crash.
- Protected actions must call ProtectedActionGate.
- Direct original-menu click activation remains experimental and must not be default.

Settings UI:
- Settings -> Hotkeys or Power User.
- List bindings.
- Add binding.
- Edit binding.
- Delete binding.
- Conflict warning.
- Test binding.
- Disable all dynamic hotkeys.

Diagnostics:
- dynamic hotkey count.
- registered count.
- conflict count.
- last hotkey action, redacted if protected.

Tests:
- binding save/load.
- conflict detection.
- dynamic registration success/failure using mock manager.
- protected action gate called.
- max hotkey limit.

Acceptance criteria:

- User can bind hotkeys to groups/items/profiles.
- Conflicts are detected.
- Protected items require authentication if enabled.
- Existing hotkeys keep working.
Task 6 — App Intents / Shortcuts integration
Add App Intents support.

Create module:
- Shortcuts/

Create files:
- Shortcuts/MenuBarDeclutterShortcutsProvider.swift
- Shortcuts/ExpandMenuBarItemsIntent.swift
- Shortcuts/CollapseMenuBarItemsIntent.swift
- Shortcuts/RevealAllMenuBarItemsIntent.swift
- Shortcuts/ShowSecondBarIntent.swift
- Shortcuts/HideSecondBarIntent.swift
- Shortcuts/EnterFullMenuBarModeIntent.swift
- Shortcuts/ExitFullMenuBarModeIntent.swift
- Shortcuts/ApplyProfileIntent.swift
- Shortcuts/PauseAutomationIntent.swift
- Shortcuts/ResumeAutomationIntent.swift
- Shortcuts/SetLayoutSpacingPresetIntent.swift
- Shortcuts/AppIntentExecutionService.swift
- Shortcuts/AppIntentResultMapper.swift

Actions:
1. Expand Menu Bar Items.
2. Collapse Menu Bar Items.
3. Reveal All Menu Bar Items.
4. Show Second Bar.
5. Hide Second Bar.
6. Enter Full Menu Bar Mode.
7. Exit Full Menu Bar Mode.
8. Apply Profile.
9. Pause Automation.
10. Resume Automation.
11. Set Layout Spacing Preset, optional and Labs-gated.

Requirements:
- Use App Intents framework.
- Do not add Apple Events.
- Do not add AppleScript dictionary.
- Do not add network.
- Intents must run through shared AppIntentExecutionService, not directly mutate random services.
- Intents must respect:
  - Safe Mode.
  - Pause All Automation.
  - Private Access locks.
  - Pro Mode requirements.
  - Accessibility requirements.
  - Labs requirements.
- Protected actions:
  - If LocalAuthentication UI cannot be presented safely from intent context, return a clear result asking user to unlock in the app.
  - Do not bypass protection.
- App intent results should be short and privacy-safe.
- Do not include protected group names in exported diagnostics.

Settings:
- Settings -> Automation / Shortcuts.
- Show available App Intents.
- Link/help text for Shortcuts app.
- Toggle whether App Intents are allowed to apply profiles.
- Toggle whether App Intents can access Labs features.

Diagnostics:
- last App Intent invoked.
- result.
- blocked reason.
- automation pause state.

Tests:
- AppIntentExecutionService pure handler tests.
- protected action returns locked result.
- automation pause blocks profile apply but allows Resume Automation.
- Safe Mode blocks risky actions.
- Labs disabled blocks spacing preset intent.

Acceptance criteria:

- App Intents compile.
- Shortcuts actions are available.
- Intents do not require Apple Events.
- Protected actions are not bypassed.
- URL automation remains backward-compatible.
Task 7 — Import / Export / Migration Assistant
Create module:
- Migration/

Create files:
- Migration/SettingsExportPackage.swift
- Migration/SettingsExportService.swift
- Migration/SettingsImportService.swift
- Migration/SettingsImportDryRun.swift
- Migration/ImportConflict.swift
- Migration/ImportBackupService.swift
- Migration/MigrationAssistantWindowController.swift
- Migration/MigrationAssistantRootView.swift
- Migration/ProfilePack.swift
- Migration/ProfilePackStore.swift

Goal:
Let user safely export/import local MenuBarDeclutter settings, groups, profiles, layout settings, hotkeys, and trigger configs.

Export package contents:
- packageVersion
- appVersion
- createdAt
- settings subset
- profiles
- triggers
- groups
- hotkey bindings
- spacer items
- layout preferences
- private access policy, but do not export active unlock session
- no diagnostics logs by default
- no health reports by default
- no screenshots
- no screen contents
- no Accessibility snapshots unless user explicitly opts in, default false
- no protected item names if private access export redaction is enabled

Import behavior:
1. User selects file manually.
2. Validate schema.
3. Dry-run first.
4. Show changes:
   - added profiles.
   - modified settings.
   - added groups.
   - hotkey conflicts.
   - risky experimental flags.
5. Back up current settings to Backups/.
6. Apply only after explicit confirmation.
7. Experimental flags remain safe by default unless user checks “import experimental settings.”
8. Never silently enable icon moving.
9. Never silently enable spacing labs.
10. Never silently enable smart triggers.
11. Never run icon moves during import.

Profile Packs:
- Export selected profiles/groups as reusable pack.
- Import profile pack without overwriting global settings unless selected.

Competitor import:
- Create docs/phase-11/competitor-import-roadmap.md.
- Do not auto-scrape competitor files.
- Implement only a generic user-selected JSON/CSV import if schema is simple and documented.
- Otherwise leave competitor import as future roadmap.

UI:
- Settings -> Import / Export.
- Export Full Settings.
- Export Profile Pack.
- Import Package.
- Dry Run result.
- Backup list.
- Restore Backup.

Diagnostics:
- last export.
- last import dry-run.
- last import result.
- backup count.
- sensitive fields redacted.

Tests:
- export package schema.
- import dry-run.
- conflict detection.
- backup before apply.
- experimental flag safety.
- corrupted import rejection.
- profile pack export/import.

Acceptance criteria:

- User can export/import MenuBarDeclutter config safely.
- Import is dry-run first.
- Backup is created before applying.
- Experimental features are not silently enabled.
- Competitor import is not overpromised.
Task 8 — Profile integration
Extend Profiles with Phase 11 features.

Add to ProfileModel:
- groupVisibilityPreferences
- protectedGroupIDs
- dynamicHotkeyPreferences optional
- layoutModePreference optional
- fullMenuBarModePreference optional
- spacingPresetPreference optional, Labs-gated

Rules:
- Profile apply can show/hide group status items.
- Profile apply can show Second Bar filtered to a group.
- Profile apply can enable/disable spacer visibility.
- Profile apply can enter/exit Full Menu Bar Mode.
- Profile apply cannot silently run icon moves.
- Profile apply cannot bypass Private Access.
- Profile apply cannot silently apply spacing labs unless explicit and Labs-enabled.

Dry-run:
- Must show group changes.
- Must show protected actions.
- Must show Labs changes.
- Must show blocked actions due to locks/permissions.

Tests:
- profile dry-run includes group changes.
- private access blocks protected profile actions.
- spacing labs blocked unless enabled.
- no icon moves executed silently.

Acceptance criteria:

- Profiles understand groups/layout.
- Existing conservative safety policy remains intact.
Task 9 — Settings reorganization for Phase 11
Update Settings UI.

Recommended Settings sections after Phase 11:
- General
- Behavior
- Layout
- Privacy
- Private Access
- Search
- Second Bar
- Groups
- Hotkeys
- Profiles
- Automation / Shortcuts
- Import / Export
- Diagnostics
- Advanced / Labs

Requirements:
- Do not make settings overwhelming.
- Use requirement rows:
  - Requires Pro Mode.
  - Requires Accessibility.
  - Requires Private Access.
  - Requires Labs.
- Use consistent labels:
  - Basic Mode
  - Pro Mode
  - Groups
  - Private Access
  - Full Menu Bar Mode
  - App Shortcuts
  - Labs
- Keep icon moving warning visible in Advanced/Labs.

Acceptance criteria:
- Settings remain navigable.
- New features are discoverable.
- Experimental features are not hidden but clearly labeled.
Task 10 — Diagnostics, Health, and Safe Mode
Extend Diagnostics:
- group count.
- protected group count.
- group status item count.
- dynamic hotkey count.
- dynamic hotkey conflicts.
- private access enabled.
- unlock session active.
- last auth status.
- last App Intent.
- last import/export.
- last profile pack action.
- redaction status.

Extend Health checks:
- corrupted group store.
- duplicate group names.
- invalid group item refs.
- missing group status item.
- protected access misconfiguration.
- stale unlock session.
- dynamic hotkey conflicts.
- corrupted hotkey binding store.
- corrupted import backup.
- App Intent disabled/misconfigured state.
- profile references missing group.

Recovery:
- backup and reset group store.
- disable group status items.
- clear unlock session.
- disable dynamic hotkeys.
- disable App Intent risky actions.
- reset import temp state.
- do not remove user groups unless corrupted and backed up.

Safe Mode:
- disables dynamic hotkeys.
- disables group status items.
- disables protected action prompts except Settings/Diagnostics recovery.
- disables App Intents except safe commands if necessary.
- disables imports.
- preserves access to Settings, Diagnostics, Reset Basic Mode, Disable Pro Mode, Disable Private Access.

Diagnostics export privacy:
- protected group names redacted by default.
- hotkey key combos can be exported, but protected target identity redacted.
- import/export file paths should be app-support-relative or redacted.

Acceptance criteria:

- Phase 11 data cannot trap the user.
- Safe Mode can recover from corrupted groups/hotkeys/private access config.
- Diagnostics export remains privacy-safe.
Task 11 — Tests
Add tests:

Groups:
- IconGroupStoreTests
- IconGroupMatcherTests
- IconGroupValidationTests
- IconGroupPanelActivationTests
- IconGroupImportExportTests

Private Access:
- ProtectedActionGateTests
- UnlockSessionTests
- MockAuthenticationServiceTests
- PrivateAccessSettingsTests
- PrivateAccessDiagnosticsRedactionTests

Hotkeys:
- HotkeyBindingStoreTests
- HotkeyConflictDetectorTests
- DynamicHotkeyRegistrationServiceTests
- HotkeyProtectedActionTests

App Intents:
- AppIntentExecutionServiceTests
- AppIntentResultMapperTests
- AppIntentSafeModeTests
- AppIntentPrivateAccessTests
- AppIntentAutomationPauseTests

Migration:
- SettingsExportPackageTests
- SettingsImportDryRunTests
- ImportBackupServiceTests
- ProfilePackTests
- ExperimentalFlagImportSafetyTests

Profiles integration:
- ProfileGroupIntegrationTests
- ProfilePrivateAccessGateTests
- ProfileLayoutPreferenceTests

Health:
- Phase11HealthTests
- SafeModePhase11Tests

Do not:
- require real Touch ID in unit tests.
- require Accessibility permission.
- require Screen Recording.
- require Shortcuts app automation in unit tests.
- write outside temporary test directories.

Acceptance criteria:

- All unit tests pass.
- No real biometric prompt appears in tests.
- No real system hotkeys are registered in tests unless mocked.
Task 12 — Manual QA
Create/update:
- docs/testing/phase-11-private-access-qa.md
- docs/testing/phase-11-groups-qa.md
- docs/testing/phase-11-hotkeys-qa.md
- docs/testing/phase-11-app-intents-qa.md
- docs/testing/phase-11-import-export-qa.md
- docs/phase-11/known-limitations.md
- docs/release/phase-11-release-notes.md

Manual QA:

Groups:
1. Create group manually by bundle ID.
2. Create group from AX snapshot picker.
3. Add/remove items.
4. Reorder groups.
5. Show group in Second Bar.
6. Open group panel.
7. Enable optional group status item.
8. Command-drag group status item.
9. Delete group.
10. Import/export group.

Private Access:
1. Enable Private Access.
2. Protect Always Hidden.
3. Protect Second Bar.
4. Protect a group.
5. Try action, approve Touch ID/password.
6. Try action, cancel auth.
7. Confirm action blocked after cancel.
8. Confirm unlock session timeout.
9. Clear unlock session.
10. Safe Mode recovery.
11. Disable Private Access.

Dynamic hotkeys:
1. Add group hotkey.
2. Add item hotkey.
3. Trigger hotkey.
4. Conflict detection.
5. Delete binding.
6. Disable all dynamic hotkeys.
7. Protected hotkey prompts auth or blocks.

App Intents:
1. Confirm actions show in Shortcuts if available.
2. Expand.
3. Collapse.
4. Reveal All.
5. Show Second Bar.
6. Apply Profile.
7. Pause Automation.
8. Resume Automation.
9. Protected action does not bypass lock.
10. Safe Mode blocks risky intents.

Import/export:
1. Export full settings.
2. Import dry-run.
3. Confirm backup created.
4. Import package.
5. Restore backup.
6. Import profile pack.
7. Try corrupted package.
8. Try package with experimental flags.
9. Confirm experimental flags not silently enabled.

Privacy:
1. Run privacy verification.
2. Confirm no Screen Recording prompt.
3. Confirm no Apple Events prompt.
4. Confirm no network.
5. Confirm diagnostics redaction.

Acceptance criteria:

- Manual QA covers all Phase 11 features.
- Known limitations are honest.
Task 13 — Phase 11 docs and release notes
Create/update:
- docs/phase-11/README.md
- docs/phase-11/private-access-plan.md
- docs/phase-11/app-intents-plan.md
- docs/phase-11/import-export-format.md
- docs/phase-11/group-schema.md
- docs/phase-11/hotkey-schema.md
- docs/phase-11/privacy-boundary.md
- docs/phase-11/known-limitations.md
- docs/status/phase-11-final-report.md
- docs/release/phase-11-release-notes.md

Known limitations:
- Private Access gates UI actions; it is not encryption.
- Touch ID availability depends on device/system configuration.
- Protected groups can still be visible in the real macOS menu bar if the original third-party item is visible outside the app’s UI.
- App Intents cannot bypass protected actions.
- Some shortcuts may require the app to be running.
- Group matching depends on bundle IDs/AX metadata and may be stale.
- No competitor config auto-import.
- No ScreenCaptureKit visual icon capture.

Acceptance criteria:

- Docs explain limitations clearly.

Task 14 — Final validation commands
Run and record:

1. xcodebuild -list
2. xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'
3. xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
4. scripts/verify_privacy_boundary.sh
5. scripts/qa_preflight.sh
6. scripts/verify_release_artifact.sh build/DerivedData/Build/Products/Release/MenuBarDeclutter.app if available
7. scripts/qa_network_watch.sh --installed or --pid if available, non-interactive only

Create/update:
- docs/status/phase-11-final-report.md

Final report must include:
- features implemented.
- tests run.
- privacy verification result.
- manual QA blockers.
- known limitations.

Acceptance criteria:

- Build passes.
- Tests pass.
- Privacy verification passes.
- No ScreenCaptureKit/Screen Recording/Apple Events/Input Monitoring/network/telemetry/cloud sync is introduced.