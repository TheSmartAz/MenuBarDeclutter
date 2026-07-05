# Phase 11 Privacy Boundary

## No New Permissions Required

Phase 11 does not request:
- Screen Recording
- ScreenCaptureKit
- Apple Events
- Input Monitoring
- Network access
- Telemetry
- Cloud sync

## Private Access
- Uses `LocalAuthentication` framework only (Touch ID / device password).
- No biometric data is stored.
- Only success/failure/cancel status is logged.
- Protected group names are redacted in diagnostics exports.
- Private Access is off by default.

## App Intents
- Uses App Intents framework only.
- Does not add Apple Events or AppleScript dictionary.
- Intents respect Safe Mode, Pause Automation, Private Access locks,
  Pro Mode requirements, and Labs requirements.
- Protected actions are not bypassed.
- Results are short and privacy-safe.

## Import / Export
- User-selected files only; no automatic scraping.
- Dry-run before applying.
- Backup created before import.
- Experimental features are not silently enabled.
- No icon moves executed during import.

## Groups
- Groups are stored locally in Application Support.
- Group matching uses bundle IDs and AX metadata (Pro Mode optional).
- Manual bundle-id groups work without Pro Mode.

## Hotkeys
- Dynamic hotkeys are disabled by default.
- No real system hotkeys are registered in tests unless mocked.
- Protected hotkey targets are redacted in diagnostics.
