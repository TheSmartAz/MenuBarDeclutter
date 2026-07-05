# Launch At Login

Launch at Login is an explicit user opt-in that uses Apple's public ServiceManagement API. It is available from Settings -> General.

## What It Does

- Shows a Launch at Login toggle in General settings.
- Uses `SMAppService.mainApp` to register or unregister the main app.
- Refreshes and displays live `SMAppService` status.
- Records the last registration result.
- Opens Login Items in System Settings.
- Shows the current bundle path and warns when the app is not running from `/Applications`.
- Reconciles the saved user preference at startup.

## User Flow

1. Install the exported app to `/Applications`.
2. Launch `/Applications/MenuBarDeclutter.app`.
3. Open Settings -> General.
4. Toggle Launch at Login on or off.
5. Use Refresh Login Item Status to verify the system state.
6. Use Open Login Items Settings if stale login item entries need cleanup.

## Privacy And Permissions

Launch at Login does not require Accessibility, Apple Events, Input Monitoring, Screen Recording, or network access. It uses the public `SMAppService.mainApp` API inside the app sandbox. Registration occurs only to honor explicit or persisted user opt-in.

## Implementation

- `MenuBar-Manager/Core/LaunchAtLoginService.swift`
- `MenuBar-Manager/Settings/GeneralSettingsView.swift`
- `MenuBar-Manager/App/AppEnvironment.swift`

## Verification

- `MenuBar-ManagerTests/LaunchAtLoginServiceTests.swift`
- Installed-app docs under `docs/testing/installed-app-qa.md`
- Current release workflow docs under `docs/release/v0.1.10-release-runbook.md`

## Known Limitations

- Xcode and DerivedData runs can report misleading `SMAppService` state.
- Restart/login-cycle behavior must be validated manually from an installed app.
- Developer ID signing, notarization, stapling, and public distribution remain out of scope until explicitly requested. Current validation is installed local dry-run behavior.
