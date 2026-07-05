# Phase 12 v0.1.1 Release Confidence Progress

Date started: 2026-06-29
Last updated: 2026-06-29

## Summary

Phase 12 implementation has started on the `v0.1.1` release line. This phase is not `v0.2`.

Completed in this pass:

- Moved active release identity to `0.1.1 (2)`.
- Added Developer ID export configuration without secrets.
- Hardened release packaging, artifact verification, installed-app verification, and notarization credential handling.
- Added app category metadata for the utility category.
- Repaired legacy `showPrimarySeparator = false` state so the primary Basic Mode separator remains required and recoverable.
- Removed `showPrimarySeparator` from real diagnostics/settings migration snapshots to avoid false configurability.
- Added native cleanup onboarding as a real first-run step with a best-effort System Settings opener and fallback.
- Added/updated v0.1.1 release, support, privacy, feature-gate, onboarding, and manual QA docs.
- Extended privacy boundary verification to catch direct network APIs and analytics SDK names in app code.
- Corrected Automation Settings action labels so gated shortcuts no longer overclaim availability.
- Added a central `FeatureStatus` vocabulary and wired Settings headers/notices for Stable, Preview, Labs, Experimental, Unavailable, and Deferred states.
- Tightened status and inline notice layout/copy so long release-state notes stay readable in the installed Settings window.
- Replaced placeholder settings migration export values with real privacy-safe local values plus schema/redaction/omission metadata.
- Kept Import/Export Preview dry-run only, with backups and explicit omission of volatile/private local state.
- Expanded the manual QA matrix, results template, dogfood script, acceptable-risks list, and release checklist links into a tester-ready v0.1.1 evidence pack.
- Tightened README, release notes, troubleshooting, permissions, Safe Mode, and uninstall docs so user-facing guidance matches v0.1.1 gates and recovery/privacy behavior.
- Ran installed-app and current debug-build UI checks through Codex Computer Use and recorded the scoped results.
- Installed the current dry-run artifact on macOS 26.1, verified the `/Applications` bundle directly, ran safe installed-app UI checks through Codex Computer Use, and recorded the dated system QA pass/blocker matrix.
- Extended the installed-app Computer Use QA through diagnostics export, settings package export/import dry-run, Safe Mode crash-marker recovery, URL automation pause/acceptance gates, and auto-rehide timing with Settings closed.
- Fixed the installed-app auto-rehide countdown so URL-driven expand returns to collapsed state after the configured delay while Settings is closed.
- Re-ran targeted `RehideController` tests, release dry-run install/verification, and focused installed-app Computer Use diagnostics for the auto-rehide fix.
- Converted the v0.1.1 release checklist from placeholder rows to PASS/PARTIAL/BLOCKED evidence tied to the Phase 12 validation record.
- Tightened the App Intents QA wording so Preview automation gates are not described as stable.
- Hardened the async `RehideController` runtime regression test so the full suite waits for the task-backed countdown instead of depending on a fixed scheduling slice.
- Re-ran the final release-candidate gate set: scheme/version checks, full test suite, preflight, dogfood preflight, dry-run release install verification, artifact verification, installed-app privacy boundary, notarization dry-run, and missing-credential failure path.

Not completed in this pass:

- Future feature surfaces still need to adopt the same status vocabulary as they are added.
- Full hands-on manual QA across notch, external display, sleep/wake, Private Access biometric states, login/logout, and real Shortcuts surfaces remains tester work.
- Hover-only reveal remains blocked in Codex Computer Use because the current tool does not expose a controllable hover-only pointer pass over the menu bar band.

## Baseline Results

| Command | Result | Notes |
| --- | --- | --- |
| `git status --short` | PASS | Existing untracked plan files: `docs/plans/PHASE-12.md`, `docs/plans/PHASE-13.md`. |
| `xcodebuild -list -project MenuBar-Manager.xcodeproj` | PASS | Canonical `MenuBarDeclutter` scheme is present. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS | Baseline run passed with 310 unit tests and 7 UI tests. |
| `scripts/qa_preflight.sh` | FAIL at baseline | Baseline UI failure in `testSecondBarSettingsShowsRequirementsWithoutProMode`: expected static text `Accessibility Permission` was not visible after scripted scroll. A direct `xcodebuild test` run passed immediately before this. Final preflight passed. |
| `scripts/verify_privacy_boundary.sh` | PASS | Source/config privacy checks passed; built-app checks skipped because `APP_PATH` was not set. |
| `scripts/qa_dogfood_preflight.sh` | PASS | Main app build, targeted dogfood/privacy tests, and privacy boundary checks passed; release artifact verification skipped because no release app bundle was present. |

## Changed Files

- `CHANGELOG.md`
- `README.md`
- `Config/Shared.xcconfig`
- `Config/MenuBarDeclutter-Info.plist`
- `Config/ExportOptions.plist`
- `MenuBar-Manager/Core/DiagnosticsExporter.swift`
- `MenuBar-Manager/Core/SettingsMigrationService.swift`
- `MenuBar-Manager/Core/SettingsStore.swift`
- `MenuBar-Manager/DesignSystem/Badges.swift`
- `MenuBar-Manager/Groups/IconGroupsSettingsView.swift`
- `MenuBar-Manager/Hiding/RehideController.swift`
- `MenuBar-Manager/Hotkeys/DynamicHotkeysSettingsView.swift`
- `MenuBar-Manager/Migration/MigrationAssistantRootView.swift`
- `MenuBar-Manager/Migration/ImportBackupService.swift`
- `MenuBar-Manager/Migration/SettingsExportPackage.swift`
- `MenuBar-Manager/Migration/SettingsExportService.swift`
- `MenuBar-Manager/Migration/SettingsImportService.swift`
- `MenuBar-Manager/Onboarding/OnboardingRootView.swift`
- `MenuBar-Manager/Onboarding/OnboardingStep.swift`
- `MenuBar-Manager/Onboarding/OnboardingSystemSettingsOpener.swift`
- `MenuBar-Manager/PrivateAccess/PrivateAccessSettingsView.swift`
- `MenuBar-Manager/Profiles/ProfileListView.swift`
- `MenuBar-Manager/Settings/AdvancedSettingsView.swift`
- `MenuBar-Manager/Settings/BehaviorSettingsView.swift`
- `MenuBar-Manager/Settings/GeneralSettingsView.swift`
- `MenuBar-Manager/Settings/LayoutSettingsView.swift`
- `MenuBar-Manager/Settings/PrivacySettingsView.swift`
- `MenuBar-Manager/Settings/SearchSettingsView.swift`
- `MenuBar-Manager/Settings/SecondBarSettingsView.swift`
- `MenuBar-Manager/Settings/SettingsRootView.swift`
- `MenuBar-Manager/Shortcuts/AutomationSettingsView.swift`
- `MenuBar-Manager/StatusBar/SeparatorController.swift`
- `MenuBar-ManagerTests/AppIntentExecutionServiceTests.swift`
- `MenuBar-ManagerTests/DesignSystem/DesignSystemSemanticsTests.swift`
- `MenuBar-ManagerTests/DiagnosticsExportTests.swift`
- `MenuBar-ManagerTests/OnboardingStepTests.swift`
- `MenuBar-ManagerTests/RehideControllerTests.swift`
- `MenuBar-ManagerTests/SettingsExportImportTests.swift`
- `MenuBar-ManagerTests/SettingsStoreTests.swift`
- `scripts/build_release.sh`
- `scripts/release_export_app.sh`
- `scripts/release_package_zip.sh`
- `scripts/release_notarize.sh`
- `scripts/verify_release_artifact.sh`
- `scripts/verify_installed_app.sh`
- `scripts/verify_privacy_boundary.sh`
- `docs/project-summary.md`
- `docs/roadmap/post-v0.1.md`
- `docs/release/notarization-runbook.md`
- `docs/release/notarization-setup.md`
- `docs/release/v0.1.1-release-notes.md`
- `docs/release/v0.1.1-known-limitations.md`
- `docs/release/v0.1.1-feature-gates.md`
- `docs/release/v0.1.1-public-claims.md`
- `docs/release/v0.1.1-release-runbook.md`
- `docs/release/v0.1.1-release-checklist.md`
- `docs/release/v0.1.1-local-dry-run.md`
- `docs/privacy/v0.1.1-privacy-claims.md`
- `docs/features/basic-mode-v0.1.1-contract.md`
- `docs/features/pro-mode-v0.1.1-boundary.md`
- `docs/support/troubleshooting.md`
- `docs/support/uninstall.md`
- `docs/support/permissions.md`
- `docs/support/safe-mode.md`
- `docs/testing/manual-qa.md`
- `docs/testing/manual-v0.1.1-system-qa.md`
- `docs/testing/manual-v0.1.1-results-template.md`
- `docs/testing/manual-v0.1.1-results-2026-06-29-computer-use.md`
- `docs/testing/manual-v0.1.1-results-2026-06-29-system-qa.md`
- `docs/testing/manual-v0.1.1-known-acceptable-risks.md`
- `docs/testing/manual-v0.1.1-dogfood-script.md`
- `docs/onboarding/native-cleanup.md`
- `docs/progress/phase-12-v0.1.1-release-confidence.md`

## Final Validation Results

| Command | Result | Notes |
| --- | --- | --- |
| `bash -n scripts/build_release.sh scripts/release_export_app.sh scripts/release_package_zip.sh scripts/release_notarize.sh scripts/verify_release_artifact.sh scripts/verify_installed_app.sh scripts/verify_privacy_boundary.sh` | PASS | Edited shell scripts parse. |
| `plutil -lint Config/ExportOptions.plist Config/MenuBarDeclutter-Info.plist` | PASS | Both plists are valid. |
| `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' -showBuildSettings` | PASS | Reported `MARKETING_VERSION = 0.1.1` and `CURRENT_PROJECT_VERSION = 2`. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/OnboardingStepTests` | PASS | 7 onboarding tests passed, including native cleanup step and opener fallback coverage. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS | Final run passed after the import/export safety patch and shared row layout fix with 320 Swift Testing tests and 7 UI tests. |
| `scripts/qa_preflight.sh` | PASS | Re-run after manual QA doc expansion. 320 Swift Testing tests and 7 UI tests passed; source privacy boundary passed. |
| `scripts/verify_privacy_boundary.sh` | PASS | Source/config privacy checks passed; built-app checks skipped because `APP_PATH` was not set. |
| `APP_PATH=build/Export/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` | PASS | Exported app has `LSUIElement`, local URL scheme, no sensitive usage strings, no network entitlements, and no ScreenCaptureKit linkage. |
| `scripts/qa_dogfood_preflight.sh` | PASS | Re-run after manual QA doc expansion. Main app build, 47 targeted dogfood/privacy tests, and privacy boundary passed. Release artifact verification skipped because `build/Release/MenuBarDeclutter.app` is not present. |
| `scripts/build_release.sh --dry-run` | PASS | Re-run after the import/export safety patch and shared row layout fix. Archive/export/package/verify completed and created `build/Dist/MenuBarDeclutter-v0.1.1-alpha.zip` plus `build/Dist/MenuBarDeclutter-v0.1.1.zip`. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/AppIntentExecutionServiceTests` | PASS | 10 App Intent execution and Settings label gate tests passed. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/DesignSystemSemanticsTests` | PASS | 8 design-system semantic tests passed, including `FeatureStatus` and Clear Glass badge mappings. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/SettingsExportImportTests` | PASS | 7 import/export tests passed, including real-value export, legacy package decode defaults, omission metadata, dry-run, conflict, and backup coverage. |
| `scripts/build_release.sh --dry-run --install --verify-installed` | PASS | Re-run after Automation Settings label fix. Installed `/Applications/MenuBarDeclutter.app`, launched it, and verified version/build/category/privacy strings/codesign/sandbox/hardened runtime/ScreenCaptureKit absence. |
| `scripts/build_release.sh --dry-run --install --verify-installed` | PARTIAL | Later re-run after UI copy/layout fixes archived/exported/packaged/verified/installed the app but `open` returned LaunchServices error `-600` before installed-app verification. |
| `scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app` | PASS | Direct verification passed after manually copying the fresh dry-run export into `/Applications`; `open -na /Applications/MenuBarDeclutter.app` then launched cleanly. |
| `scripts/build_release.sh --dry-run --install --verify-installed` | PARTIAL | Current system-QA run visibly archived, exported, packaged, release-verified, installed, and launched `/Applications/MenuBarDeclutter.app`; the terminal session was unavailable after compaction before final script status could be captured. Direct installed-app verification below is the authoritative bundle check for this run. |
| `scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app` | PASS | Current system-QA direct verification passed on macOS 26.1. Expected dry-run warnings remain: `spctl` rejected the non-notarized artifact and `stapler` found no ticket. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/RehideControllerTests` | PASS | 10 Swift Testing rehide tests passed, including the task-backed runtime countdown test for firing without manual ticks. |
| `scripts/build_release.sh --dry-run --install --verify-installed` | PASS | Re-run after the auto-rehide countdown fix. Archive/export/package/release verification/install/installed-app verification completed; expected dry-run warnings remain for non-notarized `spctl` and missing stapler ticket. |
| `defaults read Yongjun-Zhang.MenuBarDeclutter isCollapsed` | PASS | Returned `1` after the installed app ran the URL-driven collapse/expand scenario with auto-rehide enabled at 5s and Settings closed. Codex Computer Use Diagnostics corroborated `Visibility collapsed`, `Accessibility Not Requested`, and `Automation Ready`. |
| `git diff --check` | PASS | No whitespace errors after the system QA result/progress updates. |
| `scripts/verify_privacy_boundary.sh` | PASS | Source/config privacy checks passed after the system QA documentation updates; built-app checks skipped because `APP_PATH` was not set. |
| `APP_PATH=/Applications/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` | PASS | Installed app bundle privacy checks passed: `LSUIElement`, URL scheme, missing sensitive usage strings, no network entitlements, and no ScreenCaptureKit linkage. |
| `rg -n "placeholder\|TODO\|FIXME\|stub\|scaffold" MenuBar-Manager/Migration MenuBar-Manager/Shortcuts MenuBar-Manager/Layout docs/release docs/features` | PASS | Only current hit remains `docs/features/smart-triggers.md`, documenting Focus/Wi-Fi rules as model placeholders until safe runtime providers are added. |
| `env -u NOTARYTOOL_KEYCHAIN_PROFILE -u NOTARYTOOL_APPLE_ID -u NOTARYTOOL_TEAM_ID -u NOTARYTOOL_PASSWORD -u APPLE_ID -u TEAM_ID -u APP_SPECIFIC_PASSWORD scripts/release_notarize.sh --dry-run build/Dist/MenuBarDeclutter-v0.1.1-alpha.zip` | PASS | Dry-run notarization path exits 0 without upload. |
| `env -u NOTARYTOOL_KEYCHAIN_PROFILE -u NOTARYTOOL_APPLE_ID -u NOTARYTOOL_TEAM_ID -u NOTARYTOOL_PASSWORD -u APPLE_ID -u TEAM_ID -u APP_SPECIFIC_PASSWORD scripts/release_notarize.sh build/Dist/MenuBarDeclutter-v0.1.1-alpha.zip` | EXPECTED FAIL | Exited 1 before upload with a clear missing-credentials message. |
| `rg -n "\bPending\b|\bTBD\b|\bTODO\b|FIXME" docs/release docs/testing docs/progress README.md CHANGELOG.md` | PASS | Release checklist no longer has placeholder status rows; remaining hits are this audit row and historical progress rows that quote the placeholder search audit. |
| `rg -n "auto-rehide.*(did not|does not|needs follow-up|FAIL)|Current blocker|FAIL / BLOCKED|scheduled after URL-driven expand" README.md docs MenuBar-Manager scripts Config` | PASS | Hits are resolved-history notes, the manual QA matrix, or source comments. No current release blocker language remains for auto-rehide. |
| `rg -n "v0\.2|0\.2\.0" README.md docs MenuBar-Manager scripts Config` | PASS | Hits are explicit guardrails/refusal text or plan docs; no current artifact, UI, or release claim names this release `v0.2`. |
| `rg -n "(Import/Export|App Intents|Smart Triggers|Icon Moving|Spacing Labs|Private Access|URL automation).*(Stable|stable)|Stable.*(Import/Export|App Intents|Smart Triggers|Icon Moving|Spacing Labs|Private Access|URL automation)" README.md docs MenuBar-Manager` | PASS | Hits are guardrails, negative claims, or QA language after tightening App Intents wording. No Preview/Labs/Experimental surface is claimed Stable. |
| `xcodebuild -list -project MenuBar-Manager.xcodeproj` | PASS | Canonical `MenuBarDeclutter` scheme remains present. |
| `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' -showBuildSettings \| rg 'MARKETING_VERSION\|CURRENT_PROJECT_VERSION'` | PASS | Reported `MARKETING_VERSION = 0.1.1` and `CURRENT_PROJECT_VERSION = 2`. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | FAIL then fixed | Initial final run exposed a flaky fixed-sleep assertion in the new task-backed `runtimeTaskFiresWithoutManualTick` test under full-suite main-actor contention; the test was updated to wait/yield for the runtime condition. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS' -only-testing:MenuBarDeclutterTests/RehideControllerTests` | PASS | 10 `RehideController` tests passed after the wait/yield hardening. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS | Final retry passed with 321 Swift Testing tests and 7 UI tests. |
| `scripts/qa_preflight.sh` | PASS | Final preflight passed; result bundle written to `build/TestResults/qa-preflight.xcresult`, with 321 Swift Testing tests, 7 UI tests, and privacy boundary passing. |
| `scripts/qa_dogfood_preflight.sh` | PASS | Main app build, 47 targeted dogfood/privacy tests, source privacy boundary, and fixture cleanup passed. Release artifact verification skipped there because `build/Release/MenuBarDeclutter.app` is not present. |
| `scripts/build_release.sh --dry-run --install --verify-installed` | PASS | Final dry-run release archived, exported, packaged, verified, installed `/Applications/MenuBarDeclutter.app`, launched it, and passed installed-app verification. Expected non-notarized `spctl`/stapler warnings remain. |
| `scripts/verify_release_artifact.sh build/Export/MenuBarDeclutter.app --expected-version 0.1.1 --expected-build 2` | PASS | Direct artifact verification passed for bundle ID, version/build, category, LSUIElement, URL scheme, code signature, sandbox, hardened runtime, ScreenCaptureKit absence, and sensitive usage-string absence. |
| `APP_PATH=/Applications/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` | PASS | Installed app privacy boundary passed after the final install. |
| `env -u NOTARYTOOL_KEYCHAIN_PROFILE -u NOTARYTOOL_APPLE_ID -u NOTARYTOOL_TEAM_ID -u NOTARYTOOL_PASSWORD -u APPLE_ID -u TEAM_ID -u APP_SPECIFIC_PASSWORD scripts/release_notarize.sh --dry-run build/Dist/MenuBarDeclutter-v0.1.1-alpha.zip` | PASS | Final notarization dry-run exits 0 without upload. |
| `env -u NOTARYTOOL_KEYCHAIN_PROFILE -u NOTARYTOOL_APPLE_ID -u NOTARYTOOL_TEAM_ID -u NOTARYTOOL_PASSWORD -u APPLE_ID -u TEAM_ID -u APP_SPECIFIC_PASSWORD scripts/release_notarize.sh build/Dist/MenuBarDeclutter-v0.1.1-alpha.zip` | EXPECTED FAIL | Final real submission path exits 1 before upload with the expected missing-credentials message. |

Expected release-verification warnings:

- `spctl` rejects non-notarized dry-run artifacts.
- `stapler validate` reports no ticket until notarization succeeds.

## Installed-App Computer Use QA

Result file: `docs/testing/manual-v0.1.1-results-2026-06-29-computer-use.md`

System QA result file: `docs/testing/manual-v0.1.1-results-2026-06-29-system-qa.md`

Codex Computer Use verified:

- Installed app identity and version metadata from `/Applications/MenuBarDeclutter.app`.
- Seven-step onboarding replay, including the native cleanup page and best-effort System Settings Menu Bar deep link.
- Basic Mode privacy boundary and Pro Mode no-prompt behavior.
- Search and Second Bar degraded states when Accessibility is not granted.
- Automation Settings labels for `Ready`, `Profile Gate`, `Labs Gate`, `Requires Labs`, and `Disabled` states.
- Feature-status badges/notices for General, Private Access, Automation, Import/Export, Search, Second Bar, Layout Labs, Groups, Hotkeys, Profiles, Privacy, and Advanced settings. Final spot checks confirmed Private Access, Automation, and Import/Export notice text fits; the latest debug-build Import/Export check also confirmed full `Export` and `Choose File` button labels after the shared row layout fix.
- Current installed-app system QA on macOS 26.1 confirmed General installed metadata, Basic Mode, Privacy no-prompt status, Search/Second Bar fail-closed states, Automation preview gates, Advanced Labs/Experimental disabled state, Diagnostics Privacy Safe state, and Import/Export Preview copy.
- Expanded system QA exported diagnostics through the installed app UI and verified default redaction, exported a settings package and imported it back through dry-run only with backup creation, confirmed paused URL automation rejects local commands, confirmed unpaused URL automation accepts collapse/expand/reveal-all commands, and confirmed crash-marker Safe Mode starts expanded/reveal-all with optional services suppressed.
- Initial blocker found by Computer Use QA: auto-rehide scheduled after URL-driven expand with Settings closed but did not fire within the configured 5-second delay; evidence is in `~/Documents/MenuBarDeclutter-diagnostics-2026-06-29_180720.txt`.
- Follow-up after the task-backed countdown fix: targeted tests passed, the dry-run artifact was reinstalled and verified, the focused URL-driven installed-app scenario returned `isCollapsed = 1`, and Codex Computer Use Diagnostics reported `Visibility collapsed`, `Accessibility Not Requested`, and `Automation Ready`.
- Final installed-app spot check after release install: Codex Computer Use saw `/Applications/MenuBarDeclutter.app` running in Basic Mode with version `0.1.1 (2)`, Launch at Login off, and no OS permission or Login Items mutation performed.

Computer Use did not perform OS-setting changes, permission grants, Login Items changes, real Shortcuts execution, sleep/wake, external display checks, or hands-on command-drag menu bar interactions. `SystemUIServer` inspection timed out in the current system-QA run, so live status item behavior remains a physical QA gate.

## Targeted Search Audit

| Search | Result | Inspection |
| --- | --- | --- |
| `rg -n "v0\.2|0\.2\.0" README.md docs MenuBar-Manager scripts Config || true` | Hits inspected | Hits are explicit guardrails/refusal language or untracked plan docs. No UI/current release artifact names use `v0.2`. |
| `rg -n "ScreenCaptureKit|NSScreenCaptureUsageDescription|NSAppleEventsUsageDescription|URLSession|NWConnection|analytics|telemetry|Sentry|Firebase" MenuBar-Manager Config scripts docs || true` | Hits inspected | App-code hit for `telemetry` is only in dogfood export `excludedByDesign`. Direct app-code API scan for `URLSession`, `NWConnection`, `import Network`, and analytics SDK names returned no hits. Other hits are verifier checks, privacy exclusions, or historical docs. |
| `rg -n "placeholder|TODO|FIXME|stub|scaffold" MenuBar-Manager/Migration MenuBar-Manager/Shortcuts MenuBar-Manager/Layout docs/release docs/features || true` | Hits inspected | Only current hit is `docs/features/smart-triggers.md`, documenting Focus/Wi-Fi rules as model placeholders until safe runtime providers are added. No app-code placeholder export path was found by this search. |

## Known Limitations

- `v0.1.1` artifacts from `--dry-run` are development-signed and not notarized.
- Real Developer ID export/notarization still requires local credentials or a keychain profile.
- Manual QA for physical system behaviors remains required before calling a public release candidate done.
- Hover-only reveal and direct live status item interactions remain physical QA items because Codex Computer Use could not inspect `SystemUIServer` reliably or perform a hover-only menu bar pass.
- Spacing Labs, Icon Moving, Private Access, Smart Triggers, App Intents, URL automation, and Import/Export remain gated as documented; this pass did not convert all Preview/Labs/Experimental surfaces to Stable.
- Import/Export Preview does not apply selected packages in `v0.1.1`; it exports real privacy-safe values and reports dry-run results only.

## Deferred Work For Phase 13

- Continued adoption of the `FeatureStatus` vocabulary for new Phase 13 surfaces.
- Completion of profile, automation, App Intent, and Private Access workflows planned in Phase 13.
- Hands-on QA matrix execution with real crowded menu bars, notch hardware, external displays, sleep/wake, login/logout, and permission grant/revoke flows.
- Real Developer ID notarization run once credentials are available.
