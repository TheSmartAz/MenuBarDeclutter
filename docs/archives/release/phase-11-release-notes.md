# Phase 11 Release Notes

Phase 11 adds Private Access and power-user organization features while
preserving the Basic Mode privacy boundary.

## New

- Icon Groups with editor, picker, previews, import/export, and optional
  app-owned group status items.
- Group Panel with SwiftUI browsing, keyboard navigation, search, and
  conservative activation.
- Private Access settings backed by LocalAuthentication and timed unlock
  sessions.
- Dynamic hotkey settings and registration service with conflict handling.
- App Intents settings for Shortcuts, profile apply, Labs access, and
  automation controls.
- Import/Export assistant with dry-run and backup flow.
- Profile integration for groups, dynamic hotkeys, layout preferences, and
  protected actions.
- Health and Safe Mode checks for dynamic hotkeys, group status items, Private
  Access sessions, and layout automation.

## Privacy

- No Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring,
  network access, telemetry, or cloud sync.
- Private Access stores no biometric data.
- Diagnostics redact protected group names and protected hotkey targets.

## Verification

- `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build`
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'`
- `scripts/verify_privacy_boundary.sh`
