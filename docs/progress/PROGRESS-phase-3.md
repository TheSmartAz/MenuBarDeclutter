# Progress: Phase 3

Status: implemented.

## Tech Stack

- Swift 6 (`SWIFT_VERSION = 6.0`) with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` on the app target and `SWIFT_APPROACHABLE_CONCURRENCY = YES` across all targets.
- Native macOS 26.0+ target.
- AppKit for `NSStatusItem`, the Settings and Onboarding windows (`NSWindowController` + `NSHostingController`), and `NSSavePanel`.
- SwiftUI for Settings tabs, Onboarding paged flow, and the Diagnostics live UI.
- `ServiceManagement` (`SMAppService.mainApp`) for Launch at Login — sandbox-compatible, no Accessibility required.
- Observation framework (`@Observable` / `@Bindable`) for `LaunchAtLoginService` and `LiveDiagnosticsStatus`.
- Swift Testing for new unit tests; XCTest continues to back UI tests.

## Added

- `Core/LaunchAtLoginService.swift`: wraps `SMAppService.mainApp`. `register()`/`unregister()` are only called on explicit user opt-in; failures persisted in `lastRegistrationResult` and logged to Diagnostics. Exposes `apply(enabled:)` (compares against live status to avoid spurious calls), `refreshStatus()`, and a unit-testable `static describe(_:)` helper.
- `Core/DiagnosticsExporter.swift`: builds a privacy-safe diagnostics snapshot (app version, marketing version, build number, bundle id, macOS version, machine architecture, screen count and screen frames only, current settings, recent log events) and serializes it to `.txt` or `.json`. Excludes screenshots, screen contents, personal file paths, and network data; the diagnostics directory path is only emitted when the caller explicitly sets `includeAppSupportPath`. Providers are injectable for unit tests.
- `Onboarding/OnboardingStep.swift`: pure value type with the six first-run steps (intro, Command-drag, hidden vs always-hidden, hotkey & auto-rehide, privacy, macOS 26 note) and a Static ordered list.
- `Onboarding/OnboardingRootView.swift`: SwiftUI paged `TabView` flow with `OnboardingNavigationModel` (`@Observable`), Back/Continue/Get Started controls, page indicator, and an `onComplete` closure.
- `Onboarding/OnboardingWindowController.swift`: AppKit `NSWindowController` hosting the SwiftUI onboarding view; `showIfNeeded()` and `show()`; marks `hasCompletedOnboarding` true on completion; close-via-traffic-light does not mark completion.
- `Settings/AdvancedSettingsView.swift`: new Settings tab — separator geometry (expanded length, custom collapsed length + reset), Application Support discovery and "Reveal Diagnostics Folder in Finder", and read-only build/diagnostics metadata.
- `MenuBar-ManagerTests/AppSupportPathsTests.swift`: 4 tests for path nesting, lazy directory creation, idempotency, and export URL resolution.
- `MenuBar-ManagerTests/DiagnosticsExportTests.swift`: 6 tests for JSON shape, TXT readability, exclusion of the App Support path by default, current-settings reflection, screen snapshot content, and architecture helper.
- `MenuBar-ManagerTests/LaunchAtLoginServiceTests.swift`: 3 tests for `RegistrationResult.isFailure`, the `describe(_:)` error-description fallback, and a fresh service flagging no result and unregistered.
- `MenuBar-ManagerTests/OnboardingStepTests.swift`: tests for step ordering/uniqueness, the macOS 26 callout, the privacy-step content, and onboarding/defaults wording.
- `scripts/notarize_template.sh`: notarize+staple template using `xcrun notarytool submit --wait` and `xcrun stapler`; refuses to run without configured API key/identity.

## Modified

- `App/AppConstants.swift`: added `marketingVersion` and `buildNumber` accessors alongside the existing combined `appVersion`.
- `App/AppEnvironment.swift`: owns `LaunchAtLoginService` and `DiagnosticsExporter`; honors `startCollapsed` before `HidingService` reads `isCollapsed`; ensures App Support directories exist on launch; registers Launch at Login only when previously enabled; presents onboarding on first launch; exposes `resetAppLayout()`, `resetAllSettings()`, and `showOnboarding()`.
- `Core/AppSupportPaths.swift`: added lower-case `diagnosticsDirectory`, `profilesDirectory`, `backupsDirectory`, `ensureDirectoriesExist()`, `diagnosticsExportURL(filename:)`, and an injectable `baseURL` for tests.
- `Core/SettingsStore.swift`: added `startCollapsed` property with UserDefaults persistence, registered default, and `restoreDefaults()` reset.
- `Settings/SettingsRootView.swift`: added the `.advanced` section and new wiring for `launchAtLoginService`, `appSupportPaths`, `diagnosticsExporter`, `onResetLayout`, `onResetAllSettings`, `onShowOnboarding`.
- `Settings/SettingsWindowController.swift`: constructor accepts the new Phase 3 dependencies and the reset/onboarding closures.
- `Settings/GeneralSettingsView.swift`: Phase 3 layout — Launch at Login toggle (wired to `LaunchAtLoginService.apply`), failure banner, Start collapsed toggle, Reset App Layout, Reset All Settings (with destructive confirmation), Show Onboarding Again, and App version/build number section.
- `Settings/DiagnosticsSettingsView.swift`: export format picker (`TXT`/`JSON`), "Export…" button driving an `NSSavePanel`, success/error banners, current screen frames, and live UI surfaces plumbs `appSupportPaths`, `exporter`, `settingsStore`.
- `Settings/PrivacySettingsView.swift`: Basic Mode clarifying note, Pro Mode opt-in note, and Diagnostics Export privacy note.
- `MenuBar-ManagerTests/SettingsStoreTests.swift`: added tests for `startCollapsed`, `hasCompletedOnboarding` persistence, and `restoreDefaults()` resetting Phase 3 fields.
- `docs/release-checklist.md`: expanded Build/Privacy/App Behavior/Distribution/macOS 26 matrix sections reflecting Phase 3 surfaces (Launch at Login, onboarding, diagnostics export, reset actions) and the notarize template.
- `docs/architecture/architecture-overview.md`: documented `AppSupportPaths`, `LaunchAtLoginService`, `DiagnosticsExporter`; the Advanced Settings tab; Onboarding; macOS 26 styling notes; Phase 3 status; the Basic Mode architecture boundary; and the "why we do not request permissions yet" rationale.
- `docs/PLAN.md`: split future phases into Phase 1/2/3 implemented summaries and clarified the Phase 4 Pro Mode opt-in boundary.
- `docs/project-summary.md`: added Phase 2 and Phase 3 summary sections and affirmed the unchanged privacy boundary.
- `docs/testing/manual-qa.md`: added the full Phase 3 manual QA checklist (onboarding, settings, launch at login, diagnostics export, reset, quit/relaunch, restart, transparent menu bar, increase contrast, reduce transparency, external display).

## Removed

- None.

## Privacy And Permissions

- Basic Mode remains the only implemented mode.
- Launch at Login uses the public `SMAppService.mainApp` API; it works inside the App Sandbox and does not require Accessibility, Apple Events, Input Monitoring, or Screen Recording.
- Launch at Login is only ever enabled when the user toggles the Settings control. The app never auto-registers a login item, including after "Reset All Settings" (which leaves it disabled).
- Diagnostics export is on-demand and written to a user-chosen path through an `NSSavePanel`. The bundle contains only metadata, screen frames (not contents, no screenshots), current settings, and recent log messages. Personal file paths are excluded by default; the diagnostics directory path is not emitted unless the caller explicitly requests it.
- No network calls were added in Phase 3. No Accessibility, Screen Recording, Apple Events, or Input Monitoring prompts surface from any Phase 3 user path.

## Verification

- `scripts/build_debug.sh` (`xcodebuild -scheme MenuBar-Manager -destination 'platform=macOS' -configuration Debug build`)
  - Result: `BUILD SUCCEEDED` (one harmless `appintentsmetadataprocessor` warning from no AppIntents dependency — unaffected).
- `scripts/build_release.sh` (`xcodebuild -scheme MenuBar-Manager -destination 'platform=macOS' -configuration Release build`)
  - Result: `BUILD SUCCEEDED` (one harmless `appintentsmetadataprocessor` warning from no AppIntents dependency — unaffected).
- `scripts/test.sh` (`xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'`)
  - Result: `TEST SUCCEEDED`.
  - Swift Testing unit tests and XCTest UI launch tests passed.
  - New passing tests include:
    - `SettingsStoreTests/startCollapsedDefaultsFalseAndPersists()`
    - `SettingsStoreTests/onboardingFlagPersists()`
    - `SettingsStoreTests/restoreDefaultsResetsPhase3Fields()`
    - `AppSupportPathsTests/pathsAreNestedUnderDisplayName()`
    - `AppSupportPathsTests/ensureDirectoriesExistCreatesAllKnownSubdirectories()`
    - `AppSupportPathsTests/ensureDirectoriesExistIsIdempotent()`
    - `AppSupportPathsTests/diagnosticsExportURLResolvesInsideDiagnosticsDirectory()`
    - `DiagnosticsExportTests/jsonExportContainsExpectedSections()`
    - `DiagnosticsExportTests/txtExportIsHumanReadableAndExcludesByDesign()`
    - `DiagnosticsExportTests/neverIncludesAppSupportPathByDefault()`
    - `DiagnosticsExportTests/snapshotReflectsCurrentSettings()`
    - `DiagnosticsExportTests/excludesNetworkDataAndScreenshotsFromSettings()`
    - `DiagnosticsExportTests/currentArchitectureReportsKnownValue()`
    - `LaunchAtLoginServiceTests/registrationResultFailureFlag()`
    - `LaunchAtLoginServiceTests/describeFallsBackToLocalizedDescriptionForNonSMAppServiceErrors()`
    - `LaunchAtLoginServiceTests/freshServiceHasNoResultAndFlagsUnregistered()`
    - `OnboardingStepTests/allStepsAreUniqueAndOrdered()`
    - `OnboardingStepTests/macos26StepCarriesCallout()`
    - `OnboardingStepTests/privacyStepMentionsNoSensitivePermissions()`
    - `OnboardingStepTests/behaviorStepMatchesCurrentDefaults()`
  - Existing unit tests and UI launch tests continue to pass.

## Notes

- The Xcode project uses `PBXFileSystemSynchronizedRootGroup`, so every new Swift file in `MenuBar-Manager/` is automatically included in the app target and every new Swift file in `MenuBar-ManagerTests/` is automatically included in the unit-test target. No `project.pbxproj` edits were required.
- The app target has `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; new test suites that touch app types are marked `@MainActor` to match (`AppSupportPathsTests` only touches non-MainActor `AppConstants`/Foundation symbols and intentionally is not).
- `SMAppServiceError` was intentionally not referenced by name in `LaunchAtLoginService.describe(_:)` to remain resilient across SDK availability; the fallback covers both non-`SMAppService` errors and any `SMAppServiceError` via `LocalizedError`/`NSError(domain:code:)`.
- Out of scope for Phase 3 (per `docs/plans/PHASE-3.md`): Accessibility scanning, search, second bar, icon moving — these remain for Phase 4+.
