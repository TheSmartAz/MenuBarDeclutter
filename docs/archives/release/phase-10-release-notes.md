# Phase 10 Release Notes

Phase 10 adds layout and capacity tools for crowded menu bars while keeping
Basic Mode permission-free.

## New

- Capacity estimator with Basic geometry and optional Pro AX snapshots.
- Full Menu Bar Mode with auto-exit and optional Second Bar support.
- Crowded Reveal Rescue for cases where inline reveal may fail.
- App-owned spacer and divider status items with persistence.
- Layout suggestions in Settings.
- Spacing Labs with backup, restore, presets, and no automatic system process
  restart.

## Privacy

- No Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring,
  network access, telemetry, or cloud sync.
- Diagnostics include layout settings and screen frames only, never screenshots
  or screen contents.

## Verification

- `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build`
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'`
- `scripts/verify_privacy_boundary.sh`
