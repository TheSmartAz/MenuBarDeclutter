# Manual QA Results - v0.1.10

Status: recorded. Automated/source/privacy/release gates passed; physical hardware-only checks are partial or blocked where unavailable. A 2026-07-06 continuation refreshed the dry-run installed app after the Pro Second Bar setup work and reran installed-app smoke successfully. Local Workspaces panel UI execution remains blocked by Xcode UI-runner startup failures before assertions.

Run date: 2026-07-03; continuations 2026-07-04 and 2026-07-06

App build: v0.1.10 build 11

## Environment

- Hardware: MacBook Pro, Mac16,7, Apple M4 Pro, 48 GB memory.
- macOS: 26.1 build 25B78.
- Build source: local repository dry-run build.
- Installed app: `/Applications/MenuBarDeclutter.app`.

## Result Summary

| Gate | Result | Notes |
| --- | --- | --- |
| Basic Mode | PASS | Split build/test/privacy/release gates passed; Basic Mode remains permission-free. |
| Workspaces | PASS | Workspaces Settings visual smoke and unit/source privacy boundary checks passed. |
| Function Bar | PARTIAL / BLOCKED-INFRA | Unit/source coverage passed. Focused UI coverage for showing Function Bar from Workspaces settings was added and compiled, but local UI-test execution was blocked before assertions by an Xcode runner LaunchServices failure. Hands-on live panel toggle from Workspaces was not performed. |
| Info Strip | PARTIAL / BLOCKED-INFRA | Unit/source coverage passed. Focused UI coverage for showing Info Strip from Workspaces settings was added and compiled, but local UI-test execution was blocked before assertions by an Xcode runner LaunchServices failure. Hands-on live panel toggle from Workspaces was not performed. |
| Set Builder | PASS | Set Builder/Workspace preview unit and source gates passed with no schema or permission expansion. |
| Find & Rescue | PASS | UI tests passed for Find & Rescue primary actions, Search unavailable state, floating Find Icon, and Escape dismissal. |
| Recovery/Safe Mode | PARTIAL | Recovery UI workflow passed; Safe Mode source/unit coverage passed. The 2026-07-04 installed smoke verified one-shot Safe Mode flag consumption and normal relaunch. Option-launch hands-on Safe Mode was not performed. |
| Privacy prompts | PASS | Privacy UI test and installed-bundle privacy verification passed after the final installed app rerun. Pro Second Bar runtime permission prompts remain hands-on manual QA. |
| Diagnostics export | PASS | Diagnostics exporter tests and privacy verifier passed; manual file export was not separately performed. |
| Display/notch coverage | PARTIAL | UI screenshots used the built-in display and modeled notch avoidance tests passed; hands-on notch edge placement was not performed. External display coverage is blocked. |

## Evidence

- Pre-Phase-23 visual review screenshots: `docs/testing/current-ui-review-2026-07-03/`.
- Focused UI optimization screenshots: `docs/testing/ui-optimization-2026-07-03/`.
- Direct latest `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` attempts were blocked by an Xcode LaunchServices assertion before meaningful test execution: `IDELaunchServicesLauncher.m:413`, `childPID > 0`, exit 134.
- Latest split unit result bundle: `Test-MenuBarDeclutter-2026.07.03_04-44-54--0700.xcresult` with 564 tests in 77 suites passed.
- Latest split UI result bundle: `Test-MenuBarDeclutter-2026.07.03_04-32-46--0700.xcresult` with 17 UI tests passed.
- Final installed focused screenshot QA contact sheet: `/tmp/MenuBarDeclutter-installed-focused-qa-after-polish-2026-07-03/contact-sheet.png`.
- Release artifact refreshed at 2026-07-03 04:41 PDT: `build/Dist/MenuBarDeclutter-v0.1.10-alpha.zip`. The default dry-run packaging flow does not create `build/Dist/MenuBarDeclutter-v0.1.10.zip` unless explicitly requested.

## 2026-07-04 Continuation Evidence

- `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO`: PASS, `** BUILD SUCCEEDED **`.
- `xcodebuild test -scheme MenuBarDeclutterLogicTests -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData/logic-xcodebuild-test`: PASS, 36 tests in 7 suites passed.
- `xcodebuild build-for-testing -scheme MenuBarDeclutter -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData/ui-build-for-testing CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO`: PASS, `** TEST BUILD SUCCEEDED **`; the new Workspaces panel UI tests compile.
- Focused Workspaces panel UI execution with `testWorkspacesCanShowFunctionBarFromSettings` and `testWorkspacesCanShowInfoStripFromSettings`: BLOCKED-INFRA. One run reached `MenuBarDeclutterUITests-Runner` but timed out enabling automation mode; a follow-up after terminating the installed app returned to `IDELaunchServicesLauncher - Failed to Launch (Failed to send resume to target process...)` before app assertions ran.
- `scripts/build_release.sh --dry-run --install --verify-installed`: PASS, refreshed `/Applications/MenuBarDeclutter.app` and `build/Dist/MenuBarDeclutter-v0.1.10-alpha.zip`.
- `APP_PATH=/Applications/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh`: PASS, including installed-bundle privacy and entitlement checks.
- `scripts/qa_installed_app_smoke.sh --app-path /Applications/MenuBarDeclutter.app`: PASS. Installed app launched, URL scheme commands reused the installed PID, installed privacy verification passed, no network sockets were observed, the one-shot Safe Mode flag was consumed, and normal relaunch succeeded.
- `spctl --assess --type execute -vvv /Applications/MenuBarDeclutter.app`: BLOCKED-INFRA / expected dry-run instability. It still reports `Too many open files`; controlled launch logs showed syspolicyd UNIX error 24 / SecStaticCode failures while the app itself stayed running.
- `system_profiler SPDisplaysDataType`: PARTIAL display coverage, built-in Liquid Retina XDR display only; no external display attached.

## 2026-07-06 Continuation Evidence

- `scripts/build_release.sh --dry-run --install --verify-installed`: PASS, refreshed `/Applications/MenuBarDeclutter.app` at 2026-07-06 05:53 PDT after primary-click opt-in, verified `0.1.10` build `11`, and recreated `build/Dist/MenuBarDeclutter-v0.1.10-alpha.zip`.
- `scripts/qa_installed_app_smoke.sh --app-path /Applications/MenuBarDeclutter.app`: PASS. Installed app launched as PID `52086`, URL scheme commands reused the installed PID, installed privacy verification passed, no network sockets were observed, the one-shot Safe Mode flag was consumed, and normal relaunch succeeded as PID `52901`.
- Pro Second Bar App Intent readiness gate: PASS. `xcodebuild build-for-testing -scheme MenuBarDeclutter -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData/secondbar-readiness-app-tests ENABLE_DEBUG_DYLIB=YES -quiet` passed, and direct `xcrun xctest` on `MenuBarDeclutterTests.xctest` passed 575 tests in 76 suites after adding the temporary DerivedData debug-dylib symlink needed by direct bundle execution. Coverage includes `showSecondBarAppIntentUsesFullReadinessGate`.
- Pro Second Bar URL automation readiness gate: PASS. `xcodebuild build-for-testing -scheme MenuBarDeclutter -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData/secondbar-url-readiness-app-tests ENABLE_DEBUG_DYLIB=YES -quiet` passed, and direct `xcrun xctest` on `MenuBarDeclutterTests.xctest` passed 576 tests in 76 suites. Coverage includes `secondBarURLUsesFullReadinessGate`.
- Pro Second Bar direct activation matrix logging: PASS. `xcodebuild build-for-testing -scheme MenuBarDeclutter -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData/secondbar-direct-activation-matrix ENABLE_DEBUG_DYLIB=YES -quiet` passed, and direct `xcrun xctest` on `MenuBarDeclutterTests.xctest` passed 577 tests in 76 suites. Coverage includes `directActivationResultsMapToMatrixOutcomes`.
- Pro Second Bar primary-click opt-in: PASS. `xcodebuild build-for-testing -scheme MenuBarDeclutter -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData/secondbar-primary-click-optin ENABLE_DEBUG_DYLIB=YES -quiet` passed, and direct `xcrun xctest` on `MenuBarDeclutterTests.xctest` passed 577 tests in 76 suites. Coverage includes explicit primary-click opt-in routing, SettingsStore persistence, safe import skip, experimental restore, migration reset, and diagnostics export.
- Pro Second Bar activation failure retry state: PASS. `xcodebuild build-for-testing -scheme MenuBarDeclutter -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData/secondbar-retry-feedback ENABLE_DEBUG_DYLIB=YES -quiet` passed, and direct `xcrun xctest` on `MenuBarDeclutterTests.xctest` passed 578 tests in 76 suites. Coverage includes compact-strip failure feedback retaining the failed target for retry.
- Pro Second Bar Safe Mode primary-click suppression: PASS. `xcodebuild build-for-testing -scheme MenuBarDeclutter -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData/secondbar-safe-mode-primary-click ENABLE_DEBUG_DYLIB=YES -quiet` passed, and direct `xcrun xctest` on `MenuBarDeclutterTests.xctest` passed 579 tests in 76 suites. Coverage includes Safe Mode falling back to inline behavior even when Pro, readiness, and primary-click opt-in are enabled.
- Accurate Icons cache clear and stale fallback: PASS. `xcodebuild build-for-testing -scheme MenuBarDeclutter -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData/secondbar-icon-cache-clear ENABLE_DEBUG_DYLIB=YES -quiet` passed, and direct `xcrun xctest` on `MenuBarDeclutterTests.xctest` passed 580 tests in 77 suites. Coverage includes rendered cache lookup, stale rendered fallback, and cache clear removing both lookup paths.
- Pro Second Bar compact scan state: PASS. `xcodebuild build-for-testing -scheme MenuBarDeclutter -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData/secondbar-compact-scan-state ENABLE_DEBUG_DYLIB=YES -quiet` passed, and direct `xcrun xctest` on `MenuBarDeclutterTests.xctest` passed 582 tests in 77 suites. Coverage includes fresh, no-scan, and stale-scan compact strip planning.
- Canonical app build after the primary-click opt-in update: PASS, `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build -quiet`.
- Focused `xcodebuild test-without-building` for `testCompactSecondBarShowsReadyHiddenItems`: BLOCKED-INFRA. The Xcode UI runner did not materialize workers and surfaced the macOS UI Automation authorization prompt before app assertions.
- Release verification still reports expected dry-run notarization/stapling warnings: `spctl` rejects the non-notarized local app and `stapler` reports no ticket.
- Pro Second Bar hands-on gates remain pending: real Accessibility prompt, real Screen Recording prompt, Accurate Icons warm-up, compact strip notch placement, and third-party direct activation require local user interaction with the system privacy panes and live menu bar items.
