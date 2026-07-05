# Phase 21 Progress - v0.1.8 Workspace Integration

Status: implemented and re-audited during the v0.1.9 Design RC pass.

## Audit Metadata

- Re-audit date: 2026-07-03.
- Current release line during re-audit: v0.1.9 build 10, which supersedes the original v0.1.8 build 9 target after Phase 22.
- Current worktree baseline: Phase 21 and Phase 22 implementation changes are present and intentionally unstaged.
- Re-audit scope: source/docs/static verification only; manual QA, release dry-run QA, installed-app verification, and notarization execution were skipped per current request.

## Summary

Phase 21 added the local-only Workspace Integration layer that connects discovered items, New Item Inbox rows, Workspace usage, groups, placement recommendations, crowded rescue fallback, diagnostics, and physical profile preview planning. The integration remains app-owned state only: it does not move real macOS menu bar icons.

## Changed Files And Areas

- `MenuBar-Manager/WorkspaceIntegration/`: usage indexing, assignment, recommendations, diagnostics, recovery, and physical-profile planning.
- `MenuBar-Manager/Settings/FindAndRescueSettingsView.swift` and `MenuBar-Manager/Settings/NewItemInboxReviewView.swift`: New Item assignment actions for current Workspace, specific Workspace, existing Group, and new Group.
- `MenuBar-Manager/Settings/WorkspacePreviewSettingsView.swift`: Workspace Integration counts, New Item and unassigned item status, crowded fallback status, and active Workspace landing details.
- `MenuBar-Manager/SetBuilder/`: New Items and Unassigned Items library feeds.
- `MenuBar-Manager/FunctionBar/Runtime/FunctionBarItemResolver.swift`: Workspace-aware badges for linked/detached groups, new/menu bar item proxies, missing references, and permission-gated states.
- `MenuBar-ManagerTests/WorkspaceIntegrationTests.swift` and `MenuBar-ManagerTests/WorkspacesFunctionBarInfoStripTests.swift`: pure logic coverage for indexing, assignment, search filters/badges, placement adaptation, physical-profile dry-run planning, Set Builder libraries, and Function Bar badges.

## Test Results

Latest automated verification from the implementation pass; not rerun during the 2026-07-03 no-QA re-audit:

- PASS: `git diff --check`
- PASS: `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/OnboardingStepTests -only-testing:MenuBarDeclutterTests/WorkspaceIntegrationTests -only-testing:MenuBarDeclutterTests/WorkspacesFunctionBarInfoStripTests`
  - Result: 52 Swift Testing tests in the selected suites passed.
- PASS: `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'`
  - Result: full suite passed, including 549 Swift Testing tests and 16 UI tests.

## Release Verification Results

- PASS: `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' -showBuildSettings | rg 'MARKETING_VERSION|CURRENT_PROJECT_VERSION'`
  - Result: `MARKETING_VERSION = 0.1.9`, `CURRENT_PROJECT_VERSION = 10`.
- Manual installed-app dry-run verification was not run in this implementation pass because manual QA was explicitly out of scope for the current request. Existing result placeholder: `docs/testing/manual-v0.1.8-results.md`.

## Privacy Verification Results

- PASS: source audit for forbidden API and privacy-sensitive terms across Workspace Integration, onboarding, settings, Set Builder, Function Bar, and release/progress docs.
- Matches are limited to user-facing privacy-denial copy such as “does not use Screen Recording,” “no telemetry,” or “not used.” No Screen Recording, ScreenCaptureKit, Apple Events scripting/control, Input Monitoring, network access, telemetry, cloud sync, remote config, private menu bar APIs, or physical icon movement was added.

## Manual QA Status

Manual QA was not executed by request. Manual QA templates/results placeholders remain under `docs/testing/`, including:

- `docs/testing/manual-v0.1.8-workspace-integration-qa.md`
- `docs/testing/manual-v0.1.8-new-item-assignment-qa.md`
- `docs/testing/manual-v0.1.8-crowded-function-bar-fallback-qa.md`
- `docs/testing/manual-v0.1.8-results.md`

## Known Limitations

- Physical profile binding remains dry-run/safe-planning only and never applies real menu bar item movement.
- Workspace assignment stores local app-owned proxy references; it does not control, reorder, or script third-party menu bar extras.
- Pro Discovery-dependent counts and unassigned item libraries degrade when Pro Mode, Accessibility Discovery, or Accessibility permission is unavailable.

## Deferred Work For v0.1.9

- Final top-level Workspaces information architecture and Design RC docs were deferred to v0.1.9 and are now covered by Phase 22.
- Stable physical Workspace switching and bulk physical movement remain future scope.
- Developer ID signing and notarization remain out of scope until explicitly requested.
