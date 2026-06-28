# Phase 9.1 Final Report

Date: 2026-06-28

## Completed Tasks

- Repository/build audit documented in `docs/status/phase-9.1-audit.md`.
- Temporary app identity renamed to `MenuBarDeclutter` for the app target, built wrapper/executable, bundle identifier, unit test target, and UI test target.
- Canonical shared scheme `MenuBarDeclutter` added.
- Deprecated compatibility scheme `MenuBar-Manager` retained.
- Scripts updated/added for Alpha RC validation:
  - `scripts/build_debug.sh`, `scripts/build_release.sh`, and `scripts/test.sh` already prefer `MenuBarDeclutter`.
  - `scripts/verify_privacy_boundary.sh`
  - `scripts/qa_preflight.sh`
  - `scripts/qa_collect_artifacts.sh`
  - `scripts/qa_network_watch.sh`
  - `scripts/verify_release_artifact.sh`
- Risky Pro features marked experimental in Settings -> Advanced.
- Icon moving remains disabled by default and now warns before enablement.
- Global Pause All Automation added in Advanced, Profiles, and the status menu.
- Smart triggers stop/evaluate-skipped while automation is paused.
- Diagnostics events now include category, severity, message, timestamp, and optional privacy-safe metadata.
- Diagnostics UI supports warnings/errors filtering, category filtering, Copy Selected, and Export Filtered.
- Diagnostics shows experimental icon moving, smart triggers, automation pause, and Launch at Login status.
- Launch at Login settings show `SMAppService` status, last registration result, status refresh, and Open Login Items Settings.
- Privacy, QA, known-risk, release checklist, release notes, architecture, progress, and project summary docs updated.

## Skipped Or Deferred

- Full final-name filesystem/project package rename was deferred. `MenuBarDeclutter` is temporary; the `.xcodeproj` package and source/test folders still use `MenuBar-Manager` until the final product name is chosen.
- Phase 10 visual capture was not implemented.
- No ScreenCaptureKit, Screen Recording permission, Apple Events, Input Monitoring, or network access was added.
- Release artifact verification was run against a local Apple Development signed Release app. A notarized Developer ID distribution artifact was not produced in this pass.

## Validation Results

1. `xcodebuild -list`
   - Result: succeeded.
   - Targets listed: `MenuBarDeclutter`, `MenuBarDeclutterTests`, `MenuBarDeclutterUITests`.
   - Schemes listed: `MenuBar-Manager`, `MenuBarDeclutter`.

2. `xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'`
   - Result: `BUILD SUCCEEDED`.
   - Note: Xcode emitted the existing duplicate matching macOS destinations warning.

3. `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'`
   - Result: `TEST SUCCEEDED`.
   - Swift Testing: 131 tests in 25 suites passed.
   - UI tests: 7 tests passed.
   - Result bundle: `Test-MenuBarDeclutter-2026.06.28_07-05-23--0700.xcresult`.

4. `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'`
   - Result: `TEST SUCCEEDED`.
   - Swift Testing: 131 tests in 25 suites passed.
   - UI tests: 7 tests passed.
   - Result bundle: `Test-MenuBar-Manager-2026.06.28_07-09-28--0700.xcresult`.

5. `scripts/verify_privacy_boundary.sh`
   - Result: passed.
   - Confirmed no network entitlements in app project/source, no ScreenCaptureKit imports, no Screen Recording / Apple Events / Input Monitoring usage strings, expected Accessibility references for opt-in Pro discovery, local URL scheme, local App Support paths, and diagnostics privacy exclusions.

6. `scripts/qa_preflight.sh`
   - Result: passed.
   - System context: macOS 26.1 (25B78), arm64, Xcode 26.3 (17C529).
   - Ran canonical tests and privacy verification successfully.
   - Result bundle: `Test-MenuBarDeclutter-2026.06.28_07-07-33--0700.xcresult`.

7. `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' -configuration Release -derivedDataPath build/DerivedData build`
   - Result: `BUILD SUCCEEDED`.
   - Local Release app: `build/DerivedData/Build/Products/Release/MenuBarDeclutter.app`.
   - Copied local QA artifact: `build/MenuBarDeclutter.app`.

8. `scripts/verify_release_artifact.sh build/MenuBarDeclutter.app`
   - Result: passed.
   - Confirmed bundle exists, LSUIElement enabled, `menubardeclutter` URL scheme, valid codesign, readable entitlements, no network entitlements, runtime metadata, and no ScreenCaptureKit linkage.

9. `APP_PATH=build/DerivedData/Build/Products/Release/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh`
   - Result: passed.
   - Confirmed source/project privacy boundary plus built app LSUIElement, URL scheme, and no network entitlements.

10. `scripts/qa_network_watch.sh MenuBarDeclutter`
   - Result: passed as a helper.
   - Note: exact `pgrep -x MenuBarDeclutter` and `lsof -nP -i -a -c MenuBarDeclutter` produced no output because the app was not running after automated tests. Interactive runtime `nettop` remains manual QA.

## Remaining Manual QA Blockers

- Real Command-drag separator placement.
- Real third-party menu bar icon moving.
- External display and external-primary-display behavior.
- Notch display behavior.
- Sleep/wake and display-disconnect recovery while collapsed.
- Launch at Login from an installed signed app.
- Real Accessibility grant/revoke flow through System Settings.
- Interactive runtime network-watch check with `sudo nettop`.
- Release archive, notarization, and install-from-artifact validation.

## Alpha RC Recommendation

Code-level Phase 9.1 hardening is ready for Alpha RC manual QA. Do not publish the Alpha RC until the manual blockers above are completed or explicitly marked not tested in the QA run template, and until the temporary `MenuBarDeclutter` identity is accepted for alpha.
