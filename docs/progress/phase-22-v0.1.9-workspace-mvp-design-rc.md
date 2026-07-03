# Phase 22 Progress - v0.1.9 Workspace MVP Design RC

Status: implemented and re-audited.

## Audit Metadata

- Re-audit date: 2026-07-03.
- Current release line during re-audit: v0.1.9 build 10.
- Current worktree baseline: Phase 21 and Phase 22 implementation changes are present and intentionally unstaged.
- Re-audit scope: source/docs/static verification only; manual QA, release dry-run QA, installed-app verification, and notarization execution were skipped per current request.

## Summary

Phase 22 promotes the Workspace MVP to a polished Preview release candidate without shipping v0.2. Workspaces are now a top-level Settings section, onboarding explains Basic Mode, Arrange, Find & Rescue, Workspaces, privacy, and recovery, and the Workspace landing page summarizes Function Bar, Info Strip, Set Builder, New Item, unassigned item, linked group, and profile-binding status.

## Changed Files And Areas

- `Config/Shared.xcconfig`: active release line is `MARKETING_VERSION = 0.1.9`, `CURRENT_PROJECT_VERSION = 10`.
- `MenuBar-Manager/Settings/SettingsRootView.swift`: focused sidebar order is General, Hide & Reveal, Arrange, Find & Rescue, Workspaces, Privacy, Recovery, Advanced.
- `MenuBar-Manager/Onboarding/`: v0.1.9 nine-step onboarding with explicit privacy boundary, recovery step, and optional local sample Workspace action.
- `MenuBar-Manager/Settings/WorkspacePreviewSettingsView.swift`: top-level Workspace landing, quick actions, active Workspace counts, Workspace list, linked groups, Set Builder, Function Bar, Info Strip, and integration diagnostics.
- `MenuBar-Manager/Settings/FindAndRescueSettingsView.swift` and `MenuBar-Manager/Settings/NewItemInboxReviewView.swift`: Workspace-aware New Item review and assignment controls.
- `MenuBar-Manager/Settings/RecoverySettingsView.swift`, `MenuBar-Manager/Settings/SettingsActions.swift`, and `MenuBar-Manager/App/AppEnvironment.swift`: Recovery action for disabling Info Strip Preview in addition to Function Bar and Set Builder.
- `MenuBar-Manager/SetBuilder/`: New Items and Unassigned Items tabs.
- `MenuBar-Manager/FunctionBar/Runtime/FunctionBarItemResolver.swift`: Workspace integration badges for Function Bar items.
- `docs/roadmap/v0.2-draft.md`: draft/future-scope-only v0.2 boundary.
- `MenuBar-ManagerTests/OnboardingStepTests.swift` and `MenuBar-ManagerTests/WorkspacesFunctionBarInfoStripTests.swift`: updated coverage for onboarding, Set Builder integration libraries, and Function Bar badges.

## Test Results

Latest automated verification from the implementation pass; not rerun during the 2026-07-03 no-QA re-audit:

- PASS: `git diff --check`
- PASS: `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/OnboardingStepTests -only-testing:MenuBarDeclutterTests/WorkspaceIntegrationTests -only-testing:MenuBarDeclutterTests/WorkspacesFunctionBarInfoStripTests`
  - Result: 52 Swift Testing tests in the selected suites passed.
- PASS: `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'`
  - Result: full suite passed, including 549 Swift Testing tests and 16 UI tests.

## Manual QA Results

Manual QA was explicitly out of scope for this implementation pass and was not run. Current placeholder/result files remain:

- `docs/testing/manual-v0.1.9-workspaces-qa.md`
- `docs/testing/manual-v0.1.9-panels-display-qa.md`
- `docs/testing/manual-v0.1.9-privacy-qa.md`
- `docs/testing/manual-v0.1.9-system-qa.md`
- `docs/testing/manual-v0.1.9-results.md`

## Release Verification Results

- PASS: `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' -showBuildSettings | rg 'MARKETING_VERSION|CURRENT_PROJECT_VERSION'`
  - Result: `MARKETING_VERSION = 0.1.9`, `CURRENT_PROJECT_VERSION = 10`.
- Release dry-run commands remain documented in `docs/release/v0.1.9-local-dry-run.md`; they were not executed in this no-manual-QA pass.

## Privacy Verification Results

- PASS: source audit for forbidden API and privacy-sensitive terms across Workspace Integration, onboarding, settings, Set Builder, Function Bar, and release/progress docs.
- Matches are limited to user-facing privacy-denial copy. No Screen Recording, ScreenCaptureKit, Apple Events scripting/control, Input Monitoring, network access, telemetry, cloud sync, remote config, private menu bar APIs, or broad automation was added.
- Basic Mode remains permission-free. Preview/Pro surfaces remain gated and degrade when permissions or Pro settings are unavailable.

## Notarization Status

- Developer ID signing and notarization are not configured or required for this implementation pass.
- Current status is documented in `docs/release/v0.1.9-notarization-status.md`.

## v0.2 Draft Readiness

- `docs/roadmap/v0.2-draft.md` starts with `# Draft / Future Scope`.
- v0.2 remains draft-only and is not presented as the current shipped release.

## Known Limitations

- Workspaces, Function Bar, Set Builder, Info Strip, New Items, and unassigned item flows remain Preview where marked.
- Physical Workspace profile binding is dry-run/safe-planning only.
- Assisted Move and Spacing Labs remain experimental/labs and are not promoted as stable Workspace switching.

## Recommended Scope For Phase 23 / Future v0.2

- Stable physical Workspace switching.
- Bulk physical movement.
- Developer ID distribution and notarization.
- Any feature requiring additional sensitive permissions or broader automation.
