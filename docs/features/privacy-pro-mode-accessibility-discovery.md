# Privacy, Pro Mode, And Accessibility Discovery

Pro Mode is optional. Basic Mode remains fully usable when Pro Mode is disabled, Accessibility Discovery is disabled, or Accessibility permission is missing.

## What It Does

- Exposes Pro Mode and Accessibility Discovery controls in Settings -> Privacy.
- Checks Accessibility trust without prompting during ordinary refreshes.
- Requests the Accessibility prompt only from the explicit Request Permission button.
- Opens the Accessibility privacy pane when requested.
- Scans menu bar item metadata only when Pro Mode, Accessibility Discovery, and Accessibility permission are all present.
- Reads public Accessibility attributes defensively.
- Classifies scanned items into visible, hidden, always-hidden, or unknown zones.
- Clears or degrades Pro diagnostics when permission is missing or revoked.

## User Flow

1. Open Settings -> Privacy.
2. Enable Pro Mode.
3. Keep Accessibility Discovery enabled if Pro item metadata is needed.
4. Click Request Permission to trigger the system Accessibility prompt.
5. Grant or revoke permission in System Settings.
6. Use Refresh AX Scan in Diagnostics or Pro surfaces to update the local snapshot.

## Privacy And Permissions

Pro Mode discovery requests only Accessibility and only after explicit opt-in plus explicit permission request. Discovery does not request Screen Recording, Apple Events, Input Monitoring, or network access. It does not use ScreenCaptureKit, screenshots, pixel sampling, private APIs, click simulation, or drag simulation.

Accurate Icons is a separate opt-in path that can use Screen Recording and public ScreenCaptureKit visible-region capture for local rendered thumbnails. It is off by default and is documented in `docs/features/rendered-icon-capture.md`.

## Implementation

- `MenuBar-Manager/Settings/PrivacySettingsView.swift`
- `MenuBar-Manager/Permissions/AccessibilityPermissionService.swift`
- `MenuBar-Manager/Accessibility/MenuBarScanCoordinator.swift`
- `MenuBar-Manager/Accessibility/AXMenuBarScanner.swift`
- `MenuBar-Manager/Accessibility/AXElementReader.swift`
- `MenuBar-Manager/Accessibility/MenuBarItemSnapshot.swift`
- `MenuBar-Manager/Accessibility/MenuBarZone.swift`

## Verification

- `MenuBar-ManagerTests/AccessibilityDiscoveryLogicTests.swift`
- `MenuBar-ManagerTests/MenuBarScanCoordinatorTests.swift`
- `MenuBar-ManagerTests/AXMenuBarCandidateCacheTests.swift`
- Privacy QA: `docs/testing/privacy-qa.md`
- Manual QA: `docs/testing/manual-v0.1.3-system-qa.md`

## Known Limitations

- Accessibility metadata can be incomplete, stale, or unavailable for some menu bar items.
- Generated item IDs are deterministic for the same owner/title/frame inputs, but frame changes can change IDs.
- Grant/revoke flows require manual System Settings QA.
