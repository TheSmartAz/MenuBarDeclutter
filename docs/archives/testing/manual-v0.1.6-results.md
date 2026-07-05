# Manual QA Results - v0.1.6

Date: 2026-07-02

Automated evidence in the current worktree:

- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/WorkspacesFunctionBarInfoStripTests -only-testing:MenuBarDeclutterTests/HealthServiceTests -only-testing:MenuBarDeclutterTests/RecoveryServiceTests -only-testing:MenuBarDeclutterTests/HealthIssuePresentationTests -only-testing:MenuBarDeclutterTests/DiagnosticsExportTests -only-testing:MenuBarDeclutterTests/MenuBarCommandRouterTests` passed with 75 focused audit tests across 6 suites.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests` passed with 522 app-unit tests across 75 suites.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` passed with 522 app-unit tests across 75 suites and 16 UI tests.

Manual QA still required before a release cut:

- Linked vs detached behavior with real user-created Groups.
- Missing Group reference visual review.
- Set Builder layout on narrow Settings windows.
