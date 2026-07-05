# Settings, Onboarding, And Resets

The Settings and onboarding surfaces are the main SwiftUI user interface for configuring the app. They are local-only and do not request sensitive permissions on their own.

## What It Does

- Presents Settings in a SwiftUI `NavigationSplitView`.
- Provides the current seven visible sections: General, Hide & Reveal, Arrange, Find & Rescue, Privacy, Recovery, and Advanced.
- Keeps legacy or power-user detail pages reachable from Advanced or contextual page actions instead of top-level sidebar entries.
- Runs first-launch onboarding until `hasCompletedOnboarding` is true.
- Lets users replay onboarding from Settings -> General.
- Shows app name, marketing version, build number, app version, and bundle identifier.
- Offers Reset App Layout for separator geometry.
- Offers Reset All Settings for restoring registered defaults.
- Runs v0.1 settings migration for older alpha preferences.
- Creates Application Support directories lazily.

## User Flow

1. Open Settings from the status menu.
2. Use the sidebar to navigate to the relevant section.
3. Complete first-run onboarding or replay it later from General.
4. Use Reset App Layout when separator placement or lengths look wrong.
5. Use Reset All Settings when the app should return to v0.1 safe defaults.
6. Use Recovery when icons look missing, status items need repair, or Safe Mode is needed.

## Storage

Settings are backed by UserDefaults. Application Support directories are managed by `AppSupportPaths`:

- `Application Support/MenuBarDeclutter/diagnostics/`
- `Application Support/MenuBarDeclutter/profiles/`
- `Application Support/MenuBarDeclutter/backups/`
- `Application Support/MenuBarDeclutter/Dogfood/runs/`
- `Application Support/MenuBarDeclutter/Dogfood/exports/`

`SettingsMigrationService` backs up older alpha settings under `backups/`, resets risky flags to v0.1 safe defaults, repairs unsafe values, and leaves local profile JSON in place.

## Privacy And Permissions

Settings, onboarding, resets, migration, and Application Support directory creation do not request Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.

## Implementation

- `MenuBar-Manager/Settings/SettingsRootView.swift`
- `MenuBar-Manager/Settings/SettingsWindowController.swift`
- `MenuBar-Manager/Settings/GeneralSettingsView.swift`
- `MenuBar-Manager/Onboarding/OnboardingRootView.swift`
- `MenuBar-Manager/Onboarding/OnboardingStep.swift`
- `MenuBar-Manager/Onboarding/OnboardingWindowController.swift`
- `MenuBar-Manager/Core/SettingsStore.swift`
- `MenuBar-Manager/Core/SettingsMigrationService.swift`
- `MenuBar-Manager/Core/AppSupportPaths.swift`

## Verification

- `MenuBar-ManagerTests/SettingsStoreTests.swift`
- `MenuBar-ManagerTests/SettingsMigrationServiceTests.swift`
- `MenuBar-ManagerTests/OnboardingStepTests.swift`
- `MenuBar-ManagerTests/AppSupportPathsTests.swift`
- UI tests in `MenuBarDeclutterUITests/`
- Manual QA: `docs/testing/manual-qa.md`

## Known Limitations

- Some Settings controls are configuration surfaces for optional Pro or experimental features and do not guarantee those features are available without their gates.
- Launch at Login validation is reliable only from an installed app, documented separately.
- Manual QA remains required for first-run onboarding on a clean user profile.
