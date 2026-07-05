Implement New Phase 10 — Capacity & Layout Pack.

Context:
MenuBarDeclutter is a native macOS 26.0+ Swift/AppKit/SwiftUI LSUIElement menu bar utility.

Current app state:
- Phases 0–9.1 are implemented.
- Basic Mode is permission-free and uses NSStatusItem separator-based hiding.
- Pro Mode is opt-in and Accessibility-only.
- Find Icon, Second Bar, experimental icon moving, profiles/triggers, URL automation, health/recovery, Safe Mode, diagnostics, privacy verification, and Alpha RC hardening are already implemented.
- Phase 10 ScreenCaptureKit visual icon capture has not been implemented and remains intentionally deferred.

Phase 10 goal:
Add layout/capacity features that help the user fit and access more menu bar items without Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring, network access, telemetry, or cloud sync.

Hard constraints:
1. Do not implement ScreenCaptureKit.
2. Do not request Screen Recording.
3. Do not add Apple Events.
4. Do not add Input Monitoring.
5. Do not add network access.
6. Do not add telemetry.
7. Do not add cloud sync.
8. Do not use private APIs.
9. Do not copy GPL/source-available competitor code.
10. Keep Basic Mode fully usable without Accessibility.
11. Keep Pro Mode opt-in.
12. Keep icon moving disabled by default and experimental.
13. Any global menu bar spacing mutation must be Labs/Experimental, explicit, reversible, backed up, and never automatic.
14. All new features must degrade gracefully if Pro Mode/Accessibility is unavailable.
15. Do not break existing privacy verification scripts.
Task 0 — Phase 10 audit and plan docs
Create:
- docs/phase-10/README.md
- docs/phase-10/layout-capacity-plan.md
- docs/phase-10/privacy-boundary.md
- docs/phase-10/risk-register.md
- docs/phase-10/manual-qa.md
- docs/status/phase-10-starting-audit.md

Run:
- xcodebuild -list
- xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'
- xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
- scripts/verify_privacy_boundary.sh
- scripts/qa_preflight.sh

Audit:
1. Existing StatusBar module.
2. Existing Hiding module.
3. Existing ScreenGeometryService.
4. Existing SecondBarPositioningService.
5. Existing SettingsStore fields.
6. Existing diagnostics categories.
7. Existing Safe Mode behavior.
8. Existing privacy verification script.
9. Existing manual QA docs.
10. Existing Health checks.

Document Phase 10 non-goals:
- no ScreenCaptureKit.
- no visual pixel capture.
- no Screen Recording permission.
- no Apple Events.
- no Input Monitoring.
- no network.
- no telemetry.
- no automatic icon moving.

Acceptance criteria:

- Phase 10 docs exist.
- Starting test/build/privacy status is recorded.
- Risks are explicitly documented before implementation.
Task 1 — Layout module skeleton
Create new module directory:
- Layout/

Create files:
- Layout/LayoutCoordinator.swift
- Layout/LayoutSettings.swift
- Layout/LayoutMode.swift
- Layout/LayoutCapacityEstimate.swift
- Layout/LayoutCapacityService.swift
- Layout/LayoutSuggestion.swift
- Layout/LayoutSuggestionService.swift
- Layout/FullMenuBarModeService.swift
- Layout/CrowdedRevealRescueService.swift
- Layout/MenuBarSpacingService.swift
- Layout/MenuBarSpacingPreset.swift
- Layout/MenuBarSpacingBackup.swift
- Layout/SpacerItemModel.swift
- Layout/SpacerItemStore.swift
- Layout/SpacerStatusItemController.swift
- Layout/SpacerStatusItemFactory.swift

Responsibilities:

LayoutCoordinator:
- Main entry point for Phase 10.
- Owns FullMenuBarModeService, LayoutCapacityService, LayoutSuggestionService, CrowdedRevealRescueService, SpacerStatusItemController, and MenuBarSpacingService.
- Receives references to SettingsStore, DiagnosticsLogger, HidingService, ScreenGeometryService, StatusBarController, SecondBarCoordinator, and MenuBarScanCoordinator where available.
- Must be @MainActor unless doing pure calculations.

LayoutSettings:
- Value type snapshot derived from SettingsStore.
- Avoid passing SettingsStore deep into pure logic.

LayoutMode:
- normal
- fullMenuBar
- crowdedRescue
- configuration

Diagnostics:
- Add diagnostics category: layout.
- Log all Phase 10 actions with privacy-safe metadata.

Acceptance criteria:

- Layout module compiles.
- LayoutCoordinator is wired into AppEnvironment.
- No behavior changes yet except diagnostics initialization.
- Tests still pass.
Task 2 — SettingsStore fields for Phase 10
Extend SettingsStore with Phase 10 fields.

Add:

Layout:
- layoutFeaturesEnabled: Bool default true
- fullMenuBarModeEnabled: Bool default true
- crowdedRevealRescueEnabled: Bool default true
- layoutSuggestionsEnabled: Bool default true
- showCapacityWarnings: Bool default true

Full Menu Bar Mode:
- fullMenuBarModeAutoExitEnabled: Bool default true
- fullMenuBarModeAutoExitSeconds: Double default 30
- fullMenuBarModeShowsSecondBar: Bool default false
- fullMenuBarModeSuspendsAutoRehide: Bool default true
- fullMenuBarModeShowsSpacerMarkers: Bool default true

Crowded Reveal Rescue:
- crowdedRevealAutoOpenSecondBar: Bool default true
- crowdedRevealThresholdRatio: Double default 0.85
- crowdedRevealRequireProEstimate: Bool default false

Spacers:
- spacerItemsEnabled: Bool default true
- showSpacerMarkers: Bool default true
- spacerItemsJSONVersion: Int default 1

Menu Bar Spacing Labs:
- menuBarSpacingLabsEnabled: Bool default false
- menuBarSpacingPreset: String default "system"
- menuBarSpacingCustomItemSpacing: Int default 12
- menuBarSpacingCustomSelectionPadding: Int default 8
- menuBarSpacingHasBackup: Bool default false
- menuBarSpacingLastApplyStatus: String?
- menuBarSpacingLastApplyDate: Date?

Clamping:
- fullMenuBarModeAutoExitSeconds: 5...300
- crowdedRevealThresholdRatio: 0.5...1.0
- menuBarSpacingCustomItemSpacing: 2...32
- menuBarSpacingCustomSelectionPadding: 2...32

Update:
- defaults helper.
- restore defaults.
- diagnostics export.
- filtered diagnostics export if needed.
- privacy export redaction if needed.

Acceptance criteria:

- Fresh install defaults are safe.
- Reset All Settings restores Phase 10 defaults.
- Diagnostics export includes safe Phase 10 settings.
- No privacy-sensitive content is exported.
- Unit tests cover defaults/clamping/reset.
Task 3 — Menu Bar Capacity Estimator
Implement LayoutCapacityService.

Goal:
Estimate how crowded the user’s menu bar is and whether normal inline reveal is likely to fail.

Inputs:
- NSScreen frames from ScreenGeometryService.
- Primary separator frame if available.
- Always-hidden separator frame if available.
- Known AX snapshots if Pro Mode + Accessibility Discovery are available.
- Second Bar settings.
- Current HidingVisibilityState.
- Approximate item width fallback when AX is unavailable.

Create:
- LayoutCapacityEstimate
- LayoutCapacitySource
- LayoutCapacityWarning
- LayoutCapacityService

LayoutCapacityEstimate fields:
- screenID: String
- screenFrame: CGRect
- visibleFrame: CGRect
- estimatedMenuBarWidth: Double
- estimatedUsableRightSideWidth: Double
- knownItemCount: Int
- knownVisibleItemCount: Int
- knownHiddenItemCount: Int
- knownAlwaysHiddenItemCount: Int
- estimatedItemSlots: Int
- estimatedUsedSlots: Int
- usedCapacityRatio: Double
- isLikelyCrowded: Bool
- isLikelyNotchConstrained: Bool
- source: basicGeometryOnly | proAXSnapshot | mixed
- warnings: [LayoutCapacityWarning]
- generatedAt: Date

Fallback estimation:
- If no AX snapshots:
  - estimate item slots from usable width / average menu bar item width.
  - use conservative average width, e.g. 28–32pt.
  - mark estimate as approximate.
- If AX snapshots exist:
  - count known items by zone.
  - use frames to calculate occupied width.
  - mark stale snapshots as warning.

Notch model:
- Use existing screen geometry and SecondBar notch avoidance model.
- Do not attempt hardware model detection if not already available.
- Use conservative warning:
  “This display may have a notch or constrained center area; Second Bar is recommended if inline reveal fails.”

Diagnostics:
- show latest capacity estimate.
- show source: Basic estimate vs Pro AX estimate.
- show warnings.

Settings UI:
- Add Settings -> Layout -> Capacity section.
- Display:
  - capacity ratio.
  - estimated slots.
  - known items.
  - warnings.
  - recommended action.

Acceptance criteria:

- Capacity estimate works without Accessibility.
- Pro estimate improves when AX snapshots are available.
- Missing/stale AX snapshots do not crash.
- Unit tests cover Basic-only estimate and Pro AX estimate.
Task 4 — Layout Suggestions
Implement LayoutSuggestionService.

Goal:
Translate capacity estimates and current settings into useful, non-invasive suggestions.

Suggestion types:
- enableSecondBar
- useFullMenuBarMode
- addAlwaysHiddenZone
- reduceAutoRehideAggressiveness
- addSpacerDivider
- compactSpacingLabs
- disableHoverIfFlickering
- resetSeparatorLength
- enableProForBetterEstimate
- runManualQAForDisplay

LayoutSuggestion fields:
- id
- title
- message
- severity: info | warning | critical
- actionKind
- isExperimental
- requiresProMode
- requiresAccessibility
- requiresManualAction
- createdAt

Rules:
- If capacity ratio > crowdedRevealThresholdRatio:
  suggest Second Bar or Full Menu Bar Mode.
- If no Pro Mode:
  suggest enabling Pro only for more accurate estimates, but do not nag.
- If revealAll fails or hidden items remain unreachable:
  suggest Crowded Reveal Rescue.
- If separator lengths are extreme:
  suggest Reset Separator Length.
- If user has many known hidden items:
  suggest Groups in future Phase 11, but mark as roadmap until implemented.

UI:
- Settings -> Layout -> Suggestions.
- Diagnostics -> Layout.
- Optional status menu item:
  “Layout Suggestions…”

Actions:
- Some suggestions can invoke safe actions:
  - open Second Bar.
  - enable Full Menu Bar Mode.
  - reset separator length.
  - open Layout settings.
- Experimental suggestions must not auto-apply.

Acceptance criteria:

- Suggestions are useful and non-invasive.
- No suggestion silently enables Pro Mode.
- No suggestion silently changes global spacing.
- Unit tests cover suggestion generation.
Task 5 — Full Menu Bar Mode
Implement FullMenuBarModeService.

Goal:
Create a temporary configuration/reveal mode that makes all currently manageable items easier to access.

Behavior:
When enabled:
1. Save previous HidingVisibilityState.
2. Reveal all sections.
3. Suspend auto-rehide if setting enabled.
4. Suspend hover collapse behavior if needed.
5. Show spacer markers if setting enabled.
6. Optionally open Second Bar if setting enabled and available.
7. Add visible diagnostics event.
8. Optionally auto-exit after configured timeout.
9. Restore previous visibility state on exit unless user changed it manually.

Entry points:
- Status menu:
  - Enter Full Menu Bar Mode
  - Exit Full Menu Bar Mode
- Settings -> Layout.
- URL automation in Phase 10:
  - menubardeclutter://full-menu-bar
  - menubardeclutter://exit-full-menu-bar
- Later Phase 11 App Intent.

Edge cases:
- Safe Mode should disable auto-enter behavior but allow manual reset.
- If Pro Mode is missing, Full Menu Bar Mode still works with Basic reveal-all.
- If Second Bar unavailable, show non-blocking message.
- If app is force-quit while in Full Menu Bar Mode, next launch should start safe/expanded through existing crash marker logic.

Diagnostics:
- current full mode state.
- enteredAt.
- autoExitAt.
- previous state.
- exit reason.

Tests:
- enter saves previous state.
- exit restores previous state.
- auto-exit uses injectable clock/timer.
- manual user state change prevents unwanted restore if necessary.

Acceptance criteria:

- Full Menu Bar Mode can be entered/exited.
- It does not trap the user.
- Auto-rehide is suspended while active.
- It works without Accessibility.
- Tests cover pure state behavior.
Task 6 — Crowded Reveal Rescue
Implement CrowdedRevealRescueService.

Goal:
When normal inline reveal is likely to be ineffective because the menu bar is crowded, open or suggest Second Bar instead of forcing a bad inline reveal.

Behavior:
- Hook into reveal-all / hidden-item activation paths.
- Before inline reveal:
  1. Ask LayoutCapacityService for current estimate.
  2. If capacity ratio exceeds threshold or estimate warns of notch/crowding:
     - If Second Bar is enabled/available:
       open Second Bar.
       show non-intrusive banner/toast/diagnostic:
       “Opened Second Bar because the menu bar appears crowded.”
     - If Second Bar is unavailable:
       enter Full Menu Bar Mode or show suggestion.
  3. If not crowded:
     proceed with normal reveal.

Important:
- Do not prevent normal reveal if user explicitly chooses “Reveal Inline Anyway.”
- Do not require Pro Mode.
- Do not move icons.
- Do not use screen capture.
- Do not hide app menus through private APIs.

Add setting:
- crowdedRevealAutoOpenSecondBar
- crowdedRevealThresholdRatio
- revealInlineAnyway menu action.

Integrations:
- Find Icon activation path.
- Second Bar activation path.
- Reveal All action.
- Status menu.
- Diagnostics.

Tests:
- crowded estimate opens Second Bar when enabled.
- crowded estimate falls back to Full Menu Bar Mode when Second Bar unavailable.
- non-crowded estimate proceeds inline.
- explicit inline override is respected.

Acceptance criteria:

- Crowded Reveal Rescue is conservative.
- User can override it.
- It improves notch/crowded menu bar behavior without new permissions.
Task 7 — Spacer and Divider Items
Implement user-created spacer/divider status items.

Goal:
Let users visually organize their menu bar with safe, app-owned NSStatusItem spacer/divider items.

Spacer types:
- divider
- thinSpacer
- wideSpacer
- label
- icon
- invisible

Create:
- SpacerItemModel
- SpacerItemStore
- SpacerStatusItemController
- SpacerStatusItemFactory
- SpacerItemEditorView
- SpacerItemListView

SpacerItemModel fields:
- id
- type
- title
- systemImageName
- length
- isVisible
- showMarker
- sortOrder
- createdAt
- updatedAt

Behavior:
- App owns these status items.
- User can Command-drag them like other menu bar items.
- They can be shown/hidden through Settings.
- They are not used to hide third-party icons unless user positions them manually.
- Reset Spacers removes/recreates only app-owned spacer items.
- Safe Mode should keep control item visible and may hide optional spacers.

Settings -> Layout -> Spacers:
- Enable Spacer Items.
- Add Divider.
- Add Thin Spacer.
- Add Wide Spacer.
- Add Label Spacer.
- Add Icon Spacer.
- Hide All Spacer Markers.
- Reset Spacers.

Status menu:
- Add Divider
- Add Spacer
- Toggle Spacer Markers

Persistence:
- Store local JSON in Application Support/MenuBarDeclutter/Layout/spacers.json or UserDefaults if simpler.
- If corrupted, back up and reset.

Diagnostics:
- spacer count.
- visible spacer count.
- corrupted spacer store warning.
- last spacer action.

Tests:
- store save/load.
- corrupted JSON recovery.
- length clamping.
- factory model mapping.
- reset behavior.

Acceptance criteria:

- User can add app-owned dividers/spacers.
- Spacers persist after relaunch.
- Corrupted spacer store does not crash.
- Safe Mode remains recoverable.
Task 8 — Experimental Menu Bar Spacing Manager
Implement Labs-only Menu Bar Spacing Manager.

Goal:
Offer an explicit, reversible experimental way to adjust global macOS menu bar item spacing.

Important:
This is experimental because it may rely on user defaults behavior that can vary by macOS release and system configuration. It must be explicit, reversible, and never automatic.

Create:
- MenuBarSpacingService
- MenuBarSpacingPreset
- MenuBarSpacingBackup
- MenuBarSpacingApplyResult
- MenuBarSpacingCommandRunner protocol
- DefaultMenuBarSpacingCommandRunner
- MockMenuBarSpacingCommandRunner for tests

Presets:
- system
- compact
- dense
- custom

Suggested values:
- system: delete custom values
- compact: item spacing 8, selection padding 6
- dense: item spacing 4, selection padding 4
- custom: user-provided clamped values

Implementation approach:
1. First check if the app can safely read/write the relevant user defaults.
2. Back up existing values before first apply.
3. Apply selected preset only after user confirms.
4. Provide Restore Previous.
5. Provide Reset to System Default.
6. Do not kill SystemUIServer/ControlCenter automatically.
7. Show instructions that menu bar apps, SystemUIServer, ControlCenter, logout, or reboot may be needed for full effect.
8. If sandbox/system restrictions prevent writing, show “Not available in this build/configuration” and log diagnostics.
9. If Codex cannot safely verify the defaults keys in the current repository context, implement the UI/service/dry-run/backup flow but leave actual apply behind a feature flag named enableUndocumentedSpacingDefaults.

Possible defaults keys to isolate behind service:
- NSStatusItemSpacing
- NSStatusItemSelectionPadding

Do not scatter these strings through the codebase.
Put them in one internal constants file:
- Layout/MenuBarSpacingDefaultsKeys.swift

Settings -> Layout -> Menu Bar Spacing Labs:
- Labs warning.
- Current preset.
- Compact / Dense / Custom / System Default.
- Backup status.
- Apply.
- Restore Previous.
- Reset to System Default.
- Help text.

Diagnostics:
- labs enabled.
- current selected preset.
- backup exists.
- last apply status.
- last apply error.
- whether apply is dry-run.

Tests:
- backup creation.
- restore previous.
- reset to system.
- custom value clamping.
- command runner dry-run.
- unavailable environment behavior.

Acceptance criteria:

- Spacing Manager is Labs-only.
- It is off by default.
- It backs up before applying.
- It can restore previous values.
- It can reset to system default.
- It never restarts system processes automatically.
- It does not break privacy verification.
Task 9 — Layout Settings UI
Add a new Settings tab or section:
- Settings -> Layout

Views:
- LayoutSettingsView
- LayoutCapacityView
- LayoutSuggestionsView
- FullMenuBarModeSettingsView
- CrowdedRevealSettingsView
- SpacerItemsSettingsView
- MenuBarSpacingLabsView

Requirements:
- Use macOS 26-friendly SwiftUI styling.
- Respect light/dark.
- Respect Reduce Transparency.
- Respect Increase Contrast.
- Do not use custom glass effects.
- Use “Experimental” labels for spacing labs.
- Use “Requires Pro for better estimate” labels when needed.
- Keep controls disabled with explanatory rows when requirements are missing.

Navigation:
- Add Settings sidebar/tab item: Layout.
- Add Diagnostics link to Layout.
- Add Status menu item: Layout Suggestions.

Acceptance criteria:

- Layout UI is discoverable.
- Experimental spacing is clearly marked.
- Missing Pro/AX states are explained.
Task 10 — Status menu and URL automation updates
Update StatusBarMenuBuilder.

Add menu items:
- Enter Full Menu Bar Mode
- Exit Full Menu Bar Mode
- Layout Suggestions…
- Add Divider
- Add Spacer
- Toggle Spacer Markers
- Open Layout Settings
- Reveal Inline Anyway, only when rescue intercepted last reveal

Update URL automation:
- menubardeclutter://full-menu-bar
- menubardeclutter://exit-full-menu-bar
- menubardeclutter://layout-suggestions
- menubardeclutter://second-bar?reason=crowded-reveal if existing URL handler supports query safely

Security:
- Keep URL commands local and command-limited.
- Throttle URL commands using existing URL automation safety.
- Do not add arbitrary command execution.
- Do not add file path parameters.

Acceptance criteria:

- Status menu exposes safe Phase 10 actions.
- URL automation remains local and limited.
- Existing URL commands still work.
Task 11 — Health and Safe Mode integration
Extend HealthService and RecoveryService.

New health checks:
- corrupted spacer store.
- invalid spacer lengths.
- missing app-owned spacer status items.
- invalid full menu bar mode state.
- stuck full menu bar mode auto-exit.
- spacing backup missing while custom spacing says applied.
- spacing apply failure.
- layout capacity stale if Pro scan stale.
- crowded rescue repeated too often.

Recovery:
- reset spacer store after backup.
- hide optional spacer items.
- exit Full Menu Bar Mode.
- reset crowded rescue last state.
- reset menu bar spacing settings to safe app defaults, but do not mutate global system defaults automatically during health repair.
- recommend Restore Previous if global spacing was changed.

Safe Mode:
- disables auto-enter full menu mode.
- disables crowded rescue automation.
- hides optional spacer status items unless needed for reset.
- disables spacing apply UI.
- keeps Reset Layout and Diagnostics visible.

Diagnostics:
- layout health section.
- Phase 10 issues in health report.

Acceptance criteria:

- Safe Mode remains reliable.
- Health repair never silently changes global spacing.
- Corrupted Phase 10 data cannot crash launch.
Task 12 — Tests
Add/extend tests:

New test files:
- LayoutCapacityServiceTests.swift
- LayoutSuggestionServiceTests.swift
- FullMenuBarModeServiceTests.swift
- CrowdedRevealRescueServiceTests.swift
- SpacerItemStoreTests.swift
- SpacerStatusItemModelTests.swift
- MenuBarSpacingServiceTests.swift
- LayoutSettingsDefaultsTests.swift
- LayoutHealthTests.swift
- LayoutURLAutomationTests.swift

Test coverage:
1. Capacity estimate without AX.
2. Capacity estimate with mock AX snapshots.
3. Crowded threshold detection.
4. Suggestion generation.
5. Full Menu Bar Mode enter/exit.
6. Full Menu Bar Mode auto-exit using injectable clock.
7. Rescue opens Second Bar when crowded.
8. Rescue respects inline override.
9. Spacer JSON save/load.
10. Spacer corrupted JSON backup/reset.
11. Spacer length clamping.
12. Spacing backup/restore/reset using mock command runner.
13. Spacing apply unavailable behavior.
14. Settings defaults/clamping.
15. Health detects corrupted Phase 10 state.
16. URL automation throttling remains active.

Do not:
- write real global defaults in unit tests.
- require Accessibility.
- require Screen Recording.
- require external display.

Acceptance criteria:

- xcodebuild test passes.
- New tests do not depend on system permissions.
- Existing 203+ tests remain passing.
Task 13 — Docs and QA
Create/update:
- docs/phase-10/README.md
- docs/phase-10/manual-qa.md
- docs/phase-10/known-limitations.md
- docs/phase-10/privacy-boundary.md
- docs/testing/phase-10-layout-qa.md
- docs/testing/phase-10-spacing-labs-qa.md
- docs/release/phase-10-release-notes.md
- docs/status/phase-10-final-report.md

Manual QA:
Basic:
1. Start app.
2. Add divider.
3. Add thin spacer.
4. Add wide spacer.
5. Command-drag spacers.
6. Hide/show spacer markers.
7. Reset spacers.
8. Enter Full Menu Bar Mode.
9. Exit Full Menu Bar Mode.
10. Confirm auto-rehide is suspended while full mode is active.
11. Confirm Safe Mode disables layout automation.

Capacity:
1. Check capacity estimate without Pro Mode.
2. Enable Pro Mode and grant Accessibility.
3. Refresh AX scan.
4. Check improved estimate.
5. Trigger crowded estimate with fixture app if available.

Crowded rescue:
1. Make menu bar crowded using fixture app.
2. Activate hidden item from Find Icon.
3. Confirm Second Bar opens instead of unreachable inline reveal.
4. Use Reveal Inline Anyway.

Spacing Labs:
1. Confirm feature is off by default.
2. Enable Labs.
3. Back up current values.
4. Apply Compact.
5. Restore Previous.
6. Reset System Default.
7. Confirm no automatic SystemUIServer/ControlCenter restart.
8. Confirm diagnostics log every action.

Privacy:
1. Run scripts/verify_privacy_boundary.sh.
2. Confirm no Screen Recording prompt.
3. Confirm no network.

Acceptance criteria:

- Phase 10 docs are complete.
- Manual QA checklist covers real behavior.
- Known limitations are honest.
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
- docs/status/phase-10-final-report.md

Final report must include:
- features implemented.
- features intentionally not implemented.
- tests run.
- privacy verification result.
- manual QA blockers.
- spacing labs status.
- recommendation for Phase 11.

Acceptance criteria:

- Build passes.
- Tests pass.
- Privacy verification passes.