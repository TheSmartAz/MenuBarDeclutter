# Health, Recovery, And Safe Mode

Health and recovery features keep the Basic Mode control reachable and provide targeted repair options when runtime state looks unhealthy.

## What It Does

- Runs health checks at startup and from Diagnostics.
- Detects missing status items, invalid separator lengths, invalid screen geometry, corrupted settings, hotkey drift, stuck rehide/hover state, Pro permission mismatches, repeated AX failures, and stale Pro scans.
- Maps issues to targeted recovery actions.
- Offers Fix Automatically, Reset Basic Mode, Disable Pro Mode, Export Health Report, and Safe Mode Next Launch.
- Writes a crash marker on launch and clears it on clean termination.
- Enters Safe Mode after an unclean previous launch, an Option-key launch, or a one-shot Safe Mode flag.
- Starts expanded/reveal-all when Safe Mode or startup recovery requires it.
- Suppresses auto-rehide, hover reveal, Pro scans, icon moving, hotkeys, and smart triggers in Safe Mode while preserving visible Basic controls.
- Recovers after display/wake/Space changes by cancelling rehide, recalculating geometry, refreshing Second Bar placement, optionally rescanning Pro snapshots, and logging health.

## User Flow

1. Open Settings -> Diagnostics.
2. Review Health status and issue rows.
3. Click Fix Automatically for targeted repair.
4. Use Reset Basic Mode or Disable Pro Mode if a broader recovery is needed.
5. Export Health Report for local support.
6. Use Safe Mode Next Launch or hold Option at launch to start with risky runtime behaviors suppressed.

## Privacy And Permissions

Health reports, Safe Mode flags, and crash markers are local files. Health checks refresh Accessibility status without prompting. Safe Mode and recovery do not request Screen Recording, Apple Events, Input Monitoring, or network access.

## Implementation

- `MenuBar-Manager/Health/HealthService.swift`
- `MenuBar-Manager/Health/HealthIssue.swift`
- `MenuBar-Manager/Health/HealthReport.swift`
- `MenuBar-Manager/Health/RecoveryService.swift`
- `MenuBar-Manager/Health/SafeModeService.swift`
- `MenuBar-Manager/Health/AppHealthCoordinator.swift`
- `MenuBar-Manager/App/AppEnvironmentSystemRecoveryCoordinator.swift`

## Verification

- `MenuBar-ManagerTests/HealthServiceTests.swift`
- `MenuBar-ManagerTests/HealthIssuePresentationTests.swift`
- `MenuBar-ManagerTests/HealthReportTests.swift`
- `MenuBar-ManagerTests/RecoveryServiceTests.swift`
- `MenuBar-ManagerTests/SafeModeServiceTests.swift`
- Manual QA: `docs/testing/manual-qa.md`

## Known Limitations

- Real crash-marker, Option-key launch, sleep/wake, display disconnect, external display, notch, and Spaces behavior require hands-on QA.
- Safe Mode suppresses optional runtime services for one launch but does not remove user data.
