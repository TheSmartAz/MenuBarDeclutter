# Phase 23 - v0.1.10 Release Hardening

## Summary

v0.1.10 is a release-confidence phase, not a feature phase. It takes the v0.1.9 source and documentation checkpoint and turns it into an internal/local ship candidate by verifying release identity, manual QA evidence, privacy boundaries, release dry-run packaging, and installed-app checks.

## Scope

- Bump app identity to `MARKETING_VERSION = 0.1.10` and `CURRENT_PROJECT_VERSION = 11`.
- Update current-facing release docs, support docs, tooling copy, and user-facing release links from v0.1.9 to v0.1.10.
- Create v0.1.10 release notes, checklist, known limitations, release runbook, local dry-run record, notarization status, privacy claims, feature status audit, and manual QA result docs.
- Execute and record automated build/test/privacy/release gates.
- Record manual QA status for Basic Mode, Workspaces, Function Bar, Info Strip, Set Builder, Find & Rescue, Recovery/Safe Mode, privacy prompts, diagnostics export, and display/notch coverage.
- Fix only release-blocking regressions found by those gates.

## Explicitly Out Of Scope

- Stable physical Workspace switching.
- Bulk icon moving.
- New sensitive permissions.
- New command routes or persisted schema changes.
- New automation surfaces.
- v0.2 shipped claims.
- Developer ID distribution or notarization, unless explicitly reopened with real credentials.

## Feature Boundaries

- Stable: Basic Mode hiding/reveal, Launch at Login, privacy-safe diagnostics, recovery/Safe Mode, Guided Manual Arrange, and Pro gating/degraded states.
- Preview: Workspaces, Function Bar, Info Strip, Set Builder, Workspace Integration, Find Icon, Second Bar, Placement Planner, New Item Inbox, Crowded Reveal Rescue, Profiles, Smart Triggers, Dynamic Hotkeys, Private Access, App Intents automation, URL automation, and broader import/export migration assistant workflows.
- Labs: Menu Bar Spacing Labs.
- Experimental: Assisted Move / Icon Moving.
- Deferred: ScreenCaptureKit visual capture, Screen Recording, Apple Events scripting/control, Input Monitoring, network/cloud sync, telemetry, and stable automated physical menu bar item moving.

## Required Gates

- `xcodebuild -list`
- `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build`
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'`
- `scripts/verify_privacy_boundary.sh`
- `scripts/build_release.sh --dry-run`
- `scripts/build_release.sh --dry-run --install --verify-installed`
- Targeted source/docs searches for v0.2 overclaims and forbidden capability additions.

## Definition Of Done

- v0.1.10 identity is active in code, tests, and release tooling.
- Current-facing docs point at v0.1.10 and keep v0.2 draft-only.
- Manual QA matrices record PASS, FAIL, BLOCKED, or PARTIAL with date, environment, app build, and notes.
- Release dry-run and installed-app verification are recorded.
- Privacy boundary verification passes or any blocker is fixed.
- No Phase 23 change expands feature scope beyond release hardening.
