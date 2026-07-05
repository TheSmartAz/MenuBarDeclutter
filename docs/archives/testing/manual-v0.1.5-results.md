# Manual QA Results - v0.1.5 Function Bar

Date: 2026-07-02

Automated evidence in the current worktree:

- `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build` passed.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests` passed with 522 app-unit tests across 75 suites.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` passed with 522 app-unit tests across 75 suites and 16 UI tests.

Manual QA still required before a release cut:

- Function Bar panel behavior across multiple displays.
- Safe Mode visual confirmation.
- Proxy degraded-state review with Pro Mode disabled and Accessibility unavailable.
