# Alpha RC QA Run

Date: 2026-06-28
Tester: Codex automated preflight; hands-on QA pending
Machine: My Mac
macOS version: 26.1 (25B78)
Architecture: arm64
Xcode: 26.3 (17C529)
Build: local Release app at `build/MenuBarDeclutter.app`
Bundle identifier: `Yongjun-Zhang.MenuBarDeclutter`
Executable: `MenuBarDeclutter`
Git commit: pending local checkpoint; pre-checkpoint base `f9c5ab8`

Allowed results: PASS, FAIL, BLOCKED, NOT TESTED.

## Preflight

| Check | Result | Notes |
| --- | --- | --- |
| `xcodebuild -list` | PASS | Targets: `MenuBarDeclutter`, `MenuBarDeclutterTests`, `MenuBarDeclutterUITests`; schemes: `MenuBarDeclutter`, `MenuBar-Manager`. |
| `scripts/qa_preflight.sh` | PASS | Ran canonical tests and privacy verification. |
| `scripts/verify_privacy_boundary.sh` | PASS | Source/project privacy checks passed. |
| `APP_PATH=build/DerivedData/Build/Products/Release/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` | PASS | Built app LSUIElement, URL scheme, and no network entitlements verified. |
| Documented diff | PASS | Phase 9.1 hardening plus temporary `MenuBarDeclutter` identity rename; checkpoint commit to follow. |

## Automated Test Coverage

| Check | Result | Notes |
| --- | --- | --- |
| `xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS | `BUILD SUCCEEDED`. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS | `TEST SUCCEEDED`; 131 Swift tests and 7 UI tests passed. Result bundle: `Test-MenuBarDeclutter-2026.06.28_07-05-23--0700.xcresult`. |
| `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'` | PASS | Deprecated compatibility scheme still resolves renamed targets; 131 Swift tests and 7 UI tests passed. Result bundle: `Test-MenuBar-Manager-2026.06.28_07-09-28--0700.xcresult`. |
| `scripts/qa_preflight.sh` test pass | PASS | `TEST SUCCEEDED`; 131 Swift tests and 7 UI tests passed. Result bundle: `Test-MenuBarDeclutter-2026.06.28_07-07-33--0700.xcresult`. |

## Release Artifact

| Check | Result | Notes |
| --- | --- | --- |
| Release build | PASS | `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' -configuration Release -derivedDataPath build/DerivedData build` succeeded. |
| Local app bundle copied | PASS | Copied to `build/MenuBarDeclutter.app`; bundle ID `Yongjun-Zhang.MenuBarDeclutter`, executable `MenuBarDeclutter`. |
| `scripts/verify_release_artifact.sh build/MenuBarDeclutter.app` | PASS | Bundle exists, LSUIElement enabled, URL scheme present, codesign valid, no network entitlements, runtime metadata present, no ScreenCaptureKit linkage. |
| Notarization | NOT TESTED | No Developer ID notarized distribution artifact was produced in this pass. |
| Installed app Launch at Login | NOT TESTED | Requires installed signed app validation through System Settings. |

## Network Watch

| Check | Result | Notes |
| --- | --- | --- |
| `scripts/qa_network_watch.sh MenuBarDeclutter` | PASS | Helper printed local `pgrep`, `lsof`, and `nettop` commands only; it does not open network connections. |
| Exact non-interactive process probe | NOT TESTED | `pgrep -x MenuBarDeclutter` and `lsof -nP -i -a -c MenuBarDeclutter` produced no output because the app was not running after automated tests. Runtime `nettop` while manually using the app remains pending. |

## Basic Mode

| Scenario | Result | Notes |
| --- | --- | --- |
| First launch | NOT TESTED | Requires hands-on run from clean user defaults. |
| Onboarding | NOT TESTED | Requires hands-on first-launch flow. |
| Command-drag separator placement | NOT TESTED | Requires manual menu bar drag. |
| Collapse/expand/reveal all | NOT TESTED | Covered indirectly by unit/UI tests; real menu bar behavior still needs manual QA. |
| Auto-rehide / hover reveal / hotkey | NOT TESTED | Pure logic covered by tests; runtime menu bar behavior still needs manual QA. |

## Pro Mode

| Scenario | Result | Notes |
| --- | --- | --- |
| Pro Mode disabled unavailable states | PASS | UI tests verified Privacy, Find Icon unavailable state, and Second Bar requirement states. |
| Request/grant/revoke Accessibility | NOT TESTED | Requires System Settings interaction. |
| Real third-party icon moving | NOT TESTED | Requires hands-on test with third-party menu bar items. |
| Icon moving disabled by default and warning before enablement | NOT TESTED | Implemented and covered by settings flow review; manual confirmation still pending. |

## Visual And Display

| Scenario | Result | Notes |
| --- | --- | --- |
| Light/dark launch screenshots | PASS | UI launch tests captured light and dark launch screenshots. |
| External display / external primary | NOT TESTED | Requires hardware setup. |
| Notch display behavior | NOT TESTED | Requires notch display. |
| Sleep/wake and display disconnect | NOT TESTED | Requires hands-on system-state testing. |

## Summary

Blocking automated issues: none.

Known manual blockers:

- Real Command-drag separator placement.
- Real third-party menu bar icon moving.
- External display and external-primary-display behavior.
- Notch display behavior.
- Sleep/wake and display-disconnect recovery while collapsed.
- Launch at Login from an installed signed app.
- Real Accessibility grant/revoke flow through System Settings.
- Runtime interactive network watch with `sudo nettop`.
- Notarized distribution artifact verification.

Alpha RC recommendation: automated preflight and local Release artifact verification passed. Continue with hands-on QA before publishing an Alpha RC.
