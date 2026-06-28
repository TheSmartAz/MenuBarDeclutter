Implement Phase 4 — Accessibility-Based Icon Discovery.

Context:
Basic Mode is now stable. This phase adds optional Pro Mode item discovery using macOS Accessibility APIs.

Important:
- Pro Mode must be opt-in.
- Basic Mode must remain fully usable without Accessibility permission.
- Do not request Screen Recording.
- Do not simulate clicks or drags yet.

Tasks:

1. Pro Mode setting.
   Extend SettingsStore:
   - proModeEnabled: Bool default false
   - accessibilityDiscoveryEnabled: Bool default false
   - lastAccessibilityPermissionStatus: String?
   - menuBarScanIntervalSeconds: Double default 2.0

2. Permission service.
   Create:
   - Permissions/AccessibilityPermissionService.swift

   Responsibilities:
   - check permission using AXIsProcessTrustedWithOptions.
   - request prompt only when user clicks explicit button.
   - expose status:
     - notRequested
     - denied
     - granted
     - unknown
   - open System Settings privacy pane if possible.
   - log all transitions.

3. Pro Mode onboarding.
   Add to Settings > Privacy:
   - Enable Pro Mode button.
   - Explain what Accessibility is used for:
     - read menu bar item frames and labels.
     - later support search and second bar.
   - Explain what it is not used for:
     - no screen recording.
     - no keylogging.
     - no network.
   - Provide Disable Pro Mode.

4. Accessibility scanner.
   Create:
   - Accessibility/AXMenuBarScanner.swift
   - Accessibility/AXElementReader.swift
   - Accessibility/MenuBarItemSnapshot.swift
   - Accessibility/MenuBarZone.swift
   - Accessibility/MenuBarScanResult.swift

   MenuBarItemSnapshot fields:
   - id: stable generated ID
   - title: String?
   - role: String?
   - subrole: String?
   - frame: CGRect?
   - owningProcessIdentifier: pid_t?
   - owningApplicationName: String?
   - bundleIdentifier: String?
   - zone: MenuBarZone
   - isLikelySystemItem: Bool
   - scanTimestamp: Date

   MenuBarZone:
   - visible
   - hidden
   - alwaysHidden
   - unknown

5. AX scanning behavior.
   - Use AXUIElementCreateSystemWide.
   - Walk accessible menu bar/system menu extras where possible.
   - Read only safe attributes:
     - role
     - subrole
     - title
     - description
     - position
     - size
     - identifier if available
   - Never crash if attribute read fails.
   - Every AX call should return Result or optional with logged failure.

6. Zone classification.
   Use separator frames:
   - If item frame is right of primary separator: visible.
   - If item frame is left of primary separator but right of always-hidden separator: hidden.
   - If item frame is left of always-hidden separator: alwaysHidden.
   - If missing frames: unknown.

7. Scan scheduler.
   Create:
   - Accessibility/MenuBarScanCoordinator.swift

   Behavior:
   - run scan only when Pro Mode enabled and permission granted.
   - throttle scans.
   - scan on:
     - app launch.
     - screen changes.
     - expand/collapse.
     - manual refresh.
   - no aggressive polling by default.

8. Diagnostics UI.
   Add Pro diagnostics:
   - permission status.
   - number of scanned items.
   - visible/hidden/alwaysHidden counts.
   - last scan time.
   - AX failures count.
   - table of scanned snapshots.

9. Tests.
   Unit tests for:
   - MenuBarZone classification using mock frames.
   - MenuBarItemSnapshot stable ID generation.
   - scan result merge/dedup logic.
   - permission status mapping.

   Do not require actual Accessibility permission in automated tests.

10. Manual QA.
   Update:
   - Pro Mode disabled: Basic Mode works.
   - Enable Pro Mode.
   - Request Accessibility permission.
   - Grant permission.
   - Refresh scan.
   - Verify Diagnostics lists items.
   - Revoke permission.
   - Verify graceful degradation.
   - Restart app.

Acceptance criteria:
- Pro Mode is opt-in.
- Accessibility prompt only appears after explicit user action.
- If permission is granted, app can scan accessible menu bar items.
- Diagnostics shows scanned items.
- Missing/failed AX attributes do not crash.
- Basic Mode still works without permission.

Out of scope:
- No search window yet.
- No second bar.
- No clicking/activation.
- No icon moving.
- No ScreenCaptureKit.