Implement Phase 9.5 — v0.1 Basic Stable Freeze.

Context:
Phase 9.4 fixed dogfood and installed-app bugs. Now freeze the v0.1 scope and make the app safe, clear, and stable for a first stable release.

Phase goal:
Freeze v0.1 defaults, feature gates, settings, docs, known limitations, migration behavior, versioning, and release readiness.

Hard constraints:
1. Do not add Phase 10.
2. Do not add ScreenCaptureKit.
3. Do not add Screen Recording permission.
4. Do not add Apple Events.
5. Do not add Input Monitoring.
6. Do not add network access.
7. Do not add telemetry.
8. Do not add new major user-facing features.
9. Basic Mode must be stable and permission-free.
10. Pro Mode must remain opt-in.
11. Experimental features must not be enabled by default.
12. No silent bulk icon moves.
13. Release notes must be honest about limitations.
Task 1 — v0.1 scope freeze
Create:
- docs/release/v0.1-scope-freeze.md

Define v0.1 product promise:
- Permission-free Basic Mode for hiding/revealing menu bar items through separator-based layout.
- Optional always-hidden zone.
- Optional auto-rehide, hover reveal, and hotkey.
- Settings, onboarding, diagnostics, privacy-safe export.
- Launch at Login if installed-app QA passed.
- Health and Safe Mode recovery.
- Optional Pro Mode:
  - Accessibility discovery.
  - Find Icon.
  - Second Bar.
- Experimental/Labs:
  - icon moving.
  - smart triggers.
  - advanced profile zone behavior.
- Excluded:
  - ScreenCaptureKit visual capture.
  - Screen Recording.
  - Apple Events.
  - Input Monitoring.
  - network/telemetry/cloud sync.
  - AppleScript dictionary unless already implemented safely.

Acceptance criteria:
- v0.1 scope is explicit.
- Anything outside scope is moved to docs/roadmap/post-v0.1.md.
Task 2 — v0.1 defaults freeze
Create:
- docs/release/v0.1-defaults.md

Update SettingsStore defaults to match stable release:

Recommended defaults:
- Basic Mode enabled by default.
- Pro Mode disabled by default.
- Accessibility Discovery disabled by default.
- Find Icon disabled until Pro requirements are met.
- Second Bar disabled until Pro requirements are met.
- Icon Moving disabled by default.
- Smart Triggers disabled by default.
- Pause All Automation default true or automation disabled by default.
- Auto-rehide enabled only if dogfood stable; otherwise disabled.
- Hover reveal disabled by default unless dogfood stable.
- Hotkey disabled by default unless conflict handling is strong.
- Always-hidden disabled by default unless onboarding is clear.
- Start collapsed disabled by default for first launch.
- First launch starts expanded.
- Safe Mode available.

Tasks:
1. Audit every default.
2. Align Settings UI copy with defaults.
3. Align onboarding with defaults.
4. Align diagnostics with defaults.
5. Add tests for defaults.
6. Add migration handling for older alpha defaults.

Acceptance criteria:
- Fresh install defaults match v0.1-defaults.md.
- Reset All Settings restores v0.1 defaults.
- Alpha users get safe migration.
Task 3 — Alpha settings migration and reset safety
Implement v0.1 settings migration.

Create:
- Core/SettingsMigrationService.swift
- docs/release/v0.1-settings-migration.md

Migration should handle:
1. Existing Phase 9.x alpha users.
2. Deprecated scheme/app path references.
3. Deprecated compatibility settings if any.
4. Dangerous experimental flags from alpha:
   - icon moving enabled.
   - automation unpaused.
   - smart triggers enabled.
5. Invalid separator lengths.
6. stale Launch at Login cache.
7. stale Accessibility status cache.
8. broken profile/trigger JSON.

Rules:
- Do not delete user profiles unless corrupted and backed up.
- Back up old settings to Application Support/Backups/.
- Reset experimental flags to safe defaults if migration version is older than v0.1.
- Log migration result.
- Show one-time “Updated to v0.1 safe defaults” notice if needed.

Acceptance criteria:
- Fresh install works.
- Existing alpha settings migrate safely.
- Reset All Settings uses v0.1 defaults.
- Corrupted settings do not crash app.
Task 4 — v0.1 UX clarity pass
Perform a copy and UI clarity pass.

Focus areas:
1. Onboarding.
2. Drag hint.
3. Basic Mode explanation.
4. Always-hidden explanation.
5. Auto-rehide explanation.
6. Hover reveal explanation.
7. Pro Mode permission explanation.
8. Accessibility grant/revoke troubleshooting.
9. Icon Moving experimental warning.
10. Pause Automation.
11. Safe Mode.
12. Launch at Login installed-app note.
13. Diagnostics export privacy.

Tasks:
- Create docs/release/v0.1-copy-review.md.
- Update confusing UI text.
- Use consistent terms:
  - Basic Mode
  - Pro Mode
  - Find Icon
  - Second Bar
  - Icon Moving
  - Automation
  - Safe Mode
- Avoid implying the app can perfectly control all third-party menu bar icons.
- Avoid implying icon moving always works.
- Avoid implying Screen Recording exists.

Acceptance criteria:
- UX copy is honest.
- Experimental features are visibly experimental.
- Permission prompts are not surprising.
Task 5 — v0.1 release docs
Create:
- docs/release/v0.1-release-notes.md
- docs/release/v0.1-known-limitations.md
- docs/release/v0.1-privacy.md
- docs/release/v0.1-installation.md
- docs/release/v0.1-uninstall.md
- docs/release/v0.1-troubleshooting.md
- docs/release/v0.1-faq.md
- docs/roadmap/post-v0.1.md

Known limitations must include:
1. Phase 10 visual icon capture is not implemented.
2. Second Bar uses app/bundle icons and AX metadata, not captured menu bar pixels.
3. Some menu bar items may not expose complete Accessibility metadata.
4. Some menu bar items may not be movable.
5. Icon Moving is experimental/disabled by default.
6. Profiles do not silently run bulk icon moves.
7. Smart triggers are conservative and disabled by default if not fully dogfooded.
8. Focus/Wi-Fi providers remain inactive unless implemented safely.
9. Notch/external display behavior depends on real layout and may need manual adjustment.
10. Basic Mode uses separator-based hiding, not private Apple menu bar APIs.

Privacy doc must clearly state:
- No Screen Recording.
- No ScreenCaptureKit.
- No Apple Events.
- No Input Monitoring.
- No network.
- No telemetry.
- No cloud sync.
- Basic Mode requires no Accessibility.
- Pro Mode requires Accessibility only after explicit opt-in.
- Diagnostics exports are privacy-safe.

Acceptance criteria:
- User-facing release docs are complete.
- Known limitations are honest.
- Privacy claims match verification script.
Task 6 — v0.1 versioning and build metadata
Update versioning for v0.1.

Tasks:
1. Set MARKETING_VERSION to 0.1.0.
2. Set CURRENT_PROJECT_VERSION to appropriate build number.
3. Ensure Settings displays v0.1.0.
4. Ensure diagnostics export includes v0.1.0.
5. Ensure health report includes v0.1.0.
6. Ensure release artifact names include v0.1.0.
7. Ensure docs reference v0.1.0.
8. Create CHANGELOG.md if not already present.
9. Add v0.1.0 changelog section.

Artifact names:
- MenuBarDeclutter-v0.1.0.app
- MenuBarDeclutter-v0.1.0.zip
- MenuBarDeclutter-v0.1.0.dmg if DMG is implemented.

Acceptance criteria:
- Version is consistent everywhere.
- Release artifact names include version.
- Changelog exists.
Task 7 — v0.1 regression suite
Create v0.1 regression suite docs and test grouping.

Create:
- docs/testing/v0.1-regression-suite.md
- docs/testing/v0.1-regression-run-template.md

Regression suite:
1. Fresh install.
2. First launch.
3. Basic collapse/expand.
4. Real Command-drag placement.
5. Always-hidden if enabled.
6. Auto-rehide if enabled.
7. Hover reveal if enabled.
8. Hotkey if enabled.
9. Settings persistence.
10. Reset layout.
11. Reset all settings.
12. Launch at Login.
13. Diagnostics export.
14. Safe Mode.
15. Crash recovery.
16. Sleep/wake.
17. Display changes.
18. External display.
19. Notch if available.
20. Pro disabled state.
21. Pro enable + Accessibility grant.
22. Accessibility revoke.
23. Find Icon unavailable/available.
24. Second Bar unavailable/available.
25. Icon Moving disabled default.
26. Privacy verification.
27. Network observation.
28. Gatekeeper validation.
29. Notarization validation.
30. Uninstall.

Acceptance criteria:
- v0.1 regression suite exists.
- Release cannot be marked stable unless the suite is run or exceptions are documented.
Task 8 — v0.1 release blocker review
Create:
- docs/release/v0.1-release-blockers.md

Review all open issues from:
- phase-9.4-triage.md
- phase-9.4-bug-index.md
- phase-9.4-risk-board.md
- manual QA docs.
- installed-app QA.
- dogfood docs.

Classify:
- must fix before v0.1
- acceptable known limitation
- experimental feature issue
- post-v0.1

Blocking criteria:
- Any Basic Mode S0/S1 issue blocks v0.1.
- Any privacy-boundary regression blocks v0.1.
- Any app-trapping or unrecoverable state blocks v0.1.
- Any installed-app launch failure blocks v0.1 if Launch at Login is advertised.
- Any Safe Mode failure blocks v0.1.
- Icon Moving issues do not block v0.1 if feature remains experimental/disabled and failure is safe.

Acceptance criteria:
- v0.1 blockers are explicit.
- No hidden release blockers remain.
Task 9 — Final validation commands
Run and record:

1. xcodebuild -list
2. xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'
3. xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
4. scripts/verify_privacy_boundary.sh
5. scripts/qa_preflight.sh
6. scripts/release_clean.sh
7. scripts/release_archive.sh
8. scripts/release_export_app.sh
9. scripts/verify_release_artifact.sh build/Export/MenuBarDeclutter.app
10. scripts/release_package_zip.sh
11. scripts/release_validate_gatekeeper.sh build/Export/MenuBarDeclutter.app
12. scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app if installed

Create:
- docs/status/phase-9.5-final-report.md

Final report:
- v0.1 scope.
- v0.1 defaults.
- migration status.
- release blocker status.
- test results.
- privacy verification result.
- installed-app status.
- notarization status.
- recommendation: ready/not ready for Stable Release v0.1.

Acceptance criteria:
- Phase 9.5 final report exists.
- It clearly says whether v0.1 stable release may proceed.