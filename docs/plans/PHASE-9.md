Implement Phase 9 — Health, Recovery, macOS 26+ Hardening.

Context:
The app now has Basic and Pro features. This phase focuses on stability, recovery, and macOS 26-specific hardening.

Tasks:

1. Health module.
   Create:
   - Health/HealthService.swift
   - Health/RecoveryService.swift
   - Health/SafeModeService.swift
   - Health/HealthIssue.swift
   - Health/HealthReport.swift

2. Health checks.
   Implement checks:
   - control item exists.
   - primary separator exists.
   - always-hidden separator exists if enabled.
   - separator lengths are sane.
   - current screen geometry is valid.
   - settings are not corrupted.
   - hotkey status matches settings.
   - auto-rehide timer not stuck.
   - Pro Mode permission status matches features.
   - latest AX scan is not stale if Pro Mode enabled.

3. Recovery actions.
   Implement:
   - recreate missing status items.
   - reset separator lengths.
   - expand all.
   - disable auto-rehide temporarily.
   - disable hover reveal temporarily.
   - reset corrupted settings to defaults.
   - disable Pro Mode if permission repeatedly fails.
   - safe mode launch flag.

4. Safe Mode.
   Add:
   - hold modifier during launch or setting file flag to enter safe mode.
   - safe mode disables:
     - auto-rehide.
     - hover reveal.
     - Pro Mode scans.
     - icon moving.
     - triggers.
   - safe mode keeps a visible control item and reset menu.

5. Startup recovery.
   On launch:
   - initialize status items.
   - run health check.
   - if unhealthy, enter recovery.
   - never start collapsed until status items are verified.
   - if previous crash marker exists, start expanded.

6. Crash marker.
   Create simple marker:
   - write "running" marker on launch.
   - remove on clean termination.
   - if marker exists on next launch, assume previous crash and start safe/expanded.

7. Wake/display recovery.
   Observe:
   - screen parameter changes.
   - workspace wake notification if available.
   - active space/fullscreen changes if available.

   Behavior:
   - pause auto-rehide.
   - recompute geometry.
   - reapply current state.
   - rescan AX if Pro Mode enabled.
   - log health report.

8. macOS 26 visual QA helpers.
   Add manual diagnostics checklist:
   - transparent menu bar.
   - menu bar background enabled.
   - reduce transparency.
   - increase contrast.
   - light/dark/tinted appearance.
   - notch.
   - external display.
   - full-screen app.
   - Stage Manager if relevant.
   - many menu bar controls.

9. Health UI.
   Settings > Diagnostics:
   - Health status: OK / Warning / Critical.
   - List issues.
   - Fix automatically.
   - Reset Basic Mode.
   - Disable Pro Mode.
   - Export health report.
   - Enter Safe Mode on next launch.

10. Tests.
   Add:
   - HealthServiceTests.
   - RecoveryServiceTests.
   - SafeModeServiceTests.

   Test:
   - missing separator detected.
   - corrupted setting detected.
   - previous crash marker triggers safe behavior.
   - recovery resets lengths.
   - Pro Mode failure disables dependent features.

11. Manual QA.
   Add:
   - force quit app while collapsed.
   - relaunch.
   - verify recovery.
   - drag separators to weird positions.
   - reset layout.
   - revoke Accessibility.
   - sleep/wake.
   - plug/unplug display.
   - test with 30+ menu bar icons if possible.
   - test on macOS 26 latest minor release.

Acceptance criteria:
- App can recover if status items/separators are missing or misplaced.
- App starts safely after crash.
- App handles display changes and wake.
- App has visible diagnostics and repair actions.
- Basic Mode remains reliable even when Pro Mode fails.
- macOS 26 visual scenarios are documented and tested.

Out of scope:
- No new user-facing feature beyond health/recovery.
- No ScreenCaptureKit.