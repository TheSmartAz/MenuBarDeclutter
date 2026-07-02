# Phase 17 Progress - v0.1.4 Workspaces Foundation

Date: 2026-07-02

Implemented in the current v0.1.7 worktree as the Phase 17 foundation layer.

Evidence:

- `MenuBar-Manager/Workspaces/` contains models, validation, store, backup, switching, and diagnostics.
- `WorkspaceStore` persists `workspaces.json` under Application Support and creates backups for corruption/repair paths.
- `WorkspaceSwitchingService` persists active workspace selection without opening Function Bar, Info Strip, applying physical profiles, or moving icons.
- Advanced settings expose Workspaces Preview as a hidden Advanced route, not a stable top-level sidebar item.
- Import/export now supports an optional `workspaceSnapshot` in the local settings package.

Verification recorded during the Phase 17-20 audit:

- `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build` passed.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests` passed with 522 app-unit tests across 75 suites.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` passed, including 522 app-unit tests and 16 UI tests.
- `APP_PATH=/Users/thesmartaz/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Build/Products/Debug/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` passed.

Follow-up audit on 2026-07-02:

- Reconciled the Phase 17 workspace timing note with the later Phase 20 Info Strip MVP contract: the current v0.1.7 worktree intentionally clamps Info Strip rotation intervals to 3...300 seconds.
- Added privacy-safe workspace group reference resolution so diagnostics can count linked, detached, protected, and missing group references without exporting raw workspace item names, group names, menu bar item identities, live search text, or file paths.
- Aligned the Workspace Application Support directory with the Phase 17 lowercase `workspaces` path.
- Added workspace store and reference health signals to Health/Recovery so corrupted, repaired, failed, or dangling workspace references surface as recoverable warnings while Basic Mode remains usable.
- Added Info Strip command routing through the shared Command Center, Function Bar resolver, Set Builder library, and workspace action references so tiles, command palette actions, and preview surfaces use the same execution path.
- Added targeted Info Strip health and recovery actions for invalid providers, empty selected providers, rotation failures, placement failures, and invalid timing while preserving the Basic Mode permission boundary.
- Updated Settings diagnostics wiring to use the current known group, protected group, and profile IDs instead of stale placeholder references.
- Fixed the privacy workflow UI test to scroll before asserting permission rows that are below the fold.
- `scripts/verify_privacy_boundary.sh` passed source-only checks. `APP_PATH=/Users/thesmartaz/Library/Developer/Xcode/DerivedData/MenuBar-Manager-csxowpoejceahkfttjignkqzaccl/Build/Products/Debug/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` passed built-app checks for `LSUIElement`, URL scheme, sensitive usage strings, network entitlements, and ScreenCaptureKit linkage.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/WorkspacesFunctionBarInfoStripTests -only-testing:MenuBarDeclutterTests/HealthServiceTests -only-testing:MenuBarDeclutterTests/RecoveryServiceTests -only-testing:MenuBarDeclutterTests/HealthIssuePresentationTests -only-testing:MenuBarDeclutterTests/DiagnosticsExportTests -only-testing:MenuBarDeclutterTests/MenuBarCommandRouterTests` passed: 75 tests across 6 suites.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterUITests/MenuBar_ManagerUITests/testPrivacyWorkflowKeepsBasicModePermissionFree` passed: 1 UI test.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests` passed: 522 tests across 75 suites.
- `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build` passed.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` passed: 522 app-unit tests across 75 suites and 16 UI tests.

Second-pass audit on 2026-07-02:

- Re-checked Phase 17 Workspaces Foundation against the current v0.1.7 worktree and kept the shipped project version unchanged; this audit only verifies that the Phase 17 foundation contract still holds after later preview phases.
- Confirmed `WorkspaceValidationConstants.maxRotationIntervalSeconds` follows the Phase 20 Info Strip MVP bound of 300 seconds in the current v0.1.7 worktree.
- Confirmed workspace diagnostics use a deterministic redacted workspace hash and do not export raw workspace IDs.
- Confirmed privacy-safe workspace export strips all item display overrides by default, including command items, not only menu bar item proxy metadata.
- Re-ran targeted source searches for v0.2 claims, stable Function Bar/Info Strip overclaims, workspace physical-apply claims, ScreenCaptureKit, sensitive usage strings, network clients, and analytics SDKs; no current-facing Phase 17 mismatch was found.
- `xcodebuild test -quiet -scheme MenuBarDeclutter -destination 'platform=macOS' -derivedDataPath /tmp/MenuBarDeclutterPhase17Audit2C -only-testing:MenuBarDeclutterTests/WorkspacesFunctionBarInfoStripTests -only-testing:MenuBarDeclutterTests/SettingsExportImportTests` passed: 52 tests.
- `scripts/verify_privacy_boundary.sh` passed source-only privacy checks.
- `APP_PATH=/tmp/MenuBarDeclutterPhase17Audit2C/Build/Products/Debug/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` passed built-app privacy checks.
- `xcodebuild test -quiet -scheme MenuBarDeclutter -destination 'platform=macOS' -derivedDataPath /tmp/MenuBarDeclutterPhase17Audit2FullUnit -only-testing:MenuBarDeclutterTests` passed: 531 app-unit tests.

Third-pass audit on 2026-07-02:

- Re-checked Phase 17 boundaries for source/module shape, Advanced-only Workspaces Preview navigation, command routing, URL/App Intents exposure, diagnostics/export redaction, import safety, and the Basic Mode permission boundary.
- Re-checked the Info Strip rotation bound after later phases; validation and tests enforce the Phase 20 3...300 second range in the current v0.1.7 worktree.
- Closed a workspace switching robustness gap: create/duplicate now stop at the Phase 17 maximum of 50 workspaces instead of relying on store save/load clamping after reporting success.
- Updated workspace switching persistence to reload the saved snapshot so service state mirrors any store validation repairs.
- Closed an import dry-run gap: workspace package dry-run now validates and reports repair-needed workspace data, and apply sends the repaired workspace snapshot to the import handler.
- Confirmed no public workspace URL route or App Intent is exposed; Workspaces Preview remains reachable through Advanced rather than the main Settings sidebar.
- `xcodebuild test -quiet -scheme MenuBarDeclutter -destination 'platform=macOS' -derivedDataPath /tmp/MenuBarDeclutterPhase17Audit3FocusedFinal -only-testing:MenuBarDeclutterTests/WorkspacesFunctionBarInfoStripTests -only-testing:MenuBarDeclutterTests/SettingsExportImportTests -only-testing:MenuBarDeclutterTests/AutomationURLHandlerTests` passed: 65 tests.
- `scripts/verify_privacy_boundary.sh` passed source-only privacy checks.
- `APP_PATH=/tmp/MenuBarDeclutterPhase17Audit3FocusedFinal/Build/Products/Debug/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` passed built-app privacy checks.
- `xcodebuild test -quiet -scheme MenuBarDeclutter -destination 'platform=macOS' -derivedDataPath /tmp/MenuBarDeclutterPhase17Audit3FullUnitFinal -only-testing:MenuBarDeclutterTests` passed: 534 app-unit tests.

Fourth-pass audit on 2026-07-02:

- Re-checked Phase 17 import/export/backup safety, Advanced-only Workspaces Preview placement, public URL/App Intents exposure, physical profile binding inertness, diagnostics redaction, runtime preview gates, and sensitive API/version overclaim searches.
- Re-checked `WorkspaceValidationConstants.maxRotationIntervalSeconds` after later phases; validation and tests again enforce the Phase 20 3...300 second range in the current v0.1.7 worktree.
- Confirmed workspace import dry-run/apply still routes through validation and repaired snapshots; the Migration Assistant apply path still creates a backup before applying workspace data.
- Confirmed internal Workspace Command Center actions are not exposed through public URL automation or App Intents.
- `xcodebuild test -quiet -scheme MenuBarDeclutter -destination 'platform=macOS' -derivedDataPath /tmp/MenuBarDeclutterPhase17Audit4Focused -only-testing:MenuBarDeclutterTests/WorkspacesFunctionBarInfoStripTests -only-testing:MenuBarDeclutterTests/SettingsExportImportTests -only-testing:MenuBarDeclutterTests/AutomationURLHandlerTests -only-testing:MenuBarDeclutterTests/CommandCenter/MenuBarCommandRouterTests` passed: 68 focused tests.
- `scripts/verify_privacy_boundary.sh` passed source-only privacy checks.
- `APP_PATH=/tmp/MenuBarDeclutterPhase17Audit4Focused/Build/Products/Debug/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` passed built-app privacy checks.
- `xcodebuild test -quiet -scheme MenuBarDeclutter -destination 'platform=macOS' -derivedDataPath /tmp/MenuBarDeclutterPhase17Audit4FullUnit -only-testing:MenuBarDeclutterTests` passed: 538 app-unit tests.
