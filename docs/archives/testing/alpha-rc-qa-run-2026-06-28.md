# Alpha RC QA Run

Date: 2026-06-28
Tester: Codex automated preflight; hands-on QA pending
Machine: My Mac
macOS version: 26.1 (25B78)
Architecture: arm64
Xcode: 26.3 (17C529)
Build: local Release app at `build/DerivedData/Build/Products/Release/MenuBarDeclutter.app`
Bundle identifier: `Yongjun-Zhang.MenuBarDeclutter`
Executable: `MenuBarDeclutter`
Validated code commit: `a30414e`

Allowed results: PASS, FAIL, BLOCKED, NOT TESTED.

## Preflight

| Check | Result | Notes |
| --- | --- | --- |
| `xcodebuild -list` | PASS | Targets: `MenuBarDeclutter`, `MenuBarDeclutterTests`, `MenuBarDeclutterUITests`; schemes: `MenuBarDeclutter`, `MenuBar-Manager`. |
| `scripts/verify_privacy_boundary.sh` | PASS | Source/project privacy checks passed. |
| `scripts/qa_preflight.sh` | PASS | Ran canonical tests and privacy verification. Result bundle: `Test-MenuBarDeclutter-2026.06.28_11-44-30--0700.xcresult`. |
| `APP_PATH=build/DerivedData/Build/Products/Release/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` | PASS | Built app has LSUIElement, `menubardeclutter://` URL scheme, and no network entitlements. |
| Working tree | PASS | Automation started from a clean tree; this document records the validation results. |

## Automated Test Coverage

| Check | Result | Notes |
| --- | --- | --- |
| `xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS | Canonical Debug build succeeded. |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS | Full canonical scheme passed: 203 unit tests + 7 UI executions. Result bundle: `/tmp/MenuBarDeclutter-AlphaRCFull.xcresult`. |
| `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'` | PASS | Deprecated compatibility scheme still resolves renamed targets and passed: 203 unit tests + 7 UI executions. Result bundle: `/tmp/MenuBarDeclutter-CompatFull.xcresult`. |
| `scripts/qa_preflight.sh` test pass | PASS | Scripted preflight test run passed and then reran source privacy verification. |

## Release Artifact

| Check | Result | Notes |
| --- | --- | --- |
| Release build | PASS | `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' -configuration Release -derivedDataPath build/DerivedData build -quiet` succeeded. |
| Local app bundle | PASS | Built at `build/DerivedData/Build/Products/Release/MenuBarDeclutter.app`; bundle ID `Yongjun-Zhang.MenuBarDeclutter`, marketing version `1.0`, build `1`. |
| `scripts/verify_release_artifact.sh build/DerivedData/Build/Products/Release/MenuBarDeclutter.app` | PASS | Bundle exists, LSUIElement enabled, URL scheme present, codesign valid, no network entitlements, hardened-runtime metadata present, and no ScreenCaptureKit linkage. |
| Notarization | NOT TESTED | No Developer ID notarized distribution artifact was produced in this pass. |
| Installed app Launch at Login | NOT TESTED | Requires installed signed app validation through System Settings. |

## Network Watch

| Check | Result | Notes |
| --- | --- | --- |
| `scripts/qa_network_watch.sh MenuBarDeclutter` | PASS | Helper printed local `pgrep`, `lsof`, and `nettop` commands only; it does not open network connections. |
| Basic runtime process probe | PASS | Launched the Release app, confirmed `pgrep -fl MenuBarDeclutter` saw the process, and `lsof -nP -i -a -c MenuBarDeclutter` produced no network connections. App quit cleanly afterward. |
| Interactive `sudo nettop` | NOT TESTED | Requires hands-on runtime observation while exercising Basic and Pro surfaces. |

## Basic Mode

| Scenario | Result | Notes |
| --- | --- | --- |
| First launch | NOT TESTED | Requires hands-on run from clean user defaults. |
| Onboarding | NOT TESTED | Requires hands-on first-launch flow. |
| Command-drag separator placement | NOT TESTED | Requires manual menu bar drag. |
| Collapse/expand/reveal all | NOT TESTED | Covered indirectly by unit/UI tests; real menu bar behavior still needs manual QA. |
| Auto-rehide / hover reveal / hotkey | NOT TESTED | Pure logic covered by tests; runtime menu bar behavior still needs manual QA. |
| Reset separator length / app layout / all settings | NOT TESTED | Requires hands-on Settings and menu bar validation. |

## Pro Mode

| Scenario | Result | Notes |
| --- | --- | --- |
| Pro Mode disabled unavailable states | PASS | UI tests verified Privacy, Find Icon unavailable state, and Second Bar requirement states. |
| Enable Pro Mode | NOT TESTED | Requires hands-on Settings flow. |
| Request/grant/revoke Accessibility | NOT TESTED | Requires System Settings interaction. |
| Manual AX scan refresh / diagnostics table | NOT TESTED | Requires Accessibility permission and live menu bar state. |
| Real third-party icon moving | NOT TESTED | Requires hands-on test with third-party menu bar items. |
| Icon moving disabled by default and warning before enablement | NOT TESTED | Implemented and covered by settings flow review; manual confirmation still pending. |

## Visual And Display

| Scenario | Result | Notes |
| --- | --- | --- |
| Light/dark launch screenshots | PASS | UI launch tests captured light and dark launch screenshots. |
| Transparent menu bar / Reduce Transparency / Increase Contrast | NOT TESTED | Requires hands-on appearance/accessibility setting changes. |
| External display / external primary | NOT TESTED | Requires hardware setup. |
| Notch display behavior | NOT TESTED | Requires notch display. |
| Sleep/wake and display disconnect | NOT TESTED | Requires hands-on system-state testing. |
| Full-screen app / Space switch | NOT TESTED | Requires hands-on Space switching. |

## Find Icon And Second Bar

| Scenario | Result | Notes |
| --- | --- | --- |
| Find Icon unavailable state | PASS | UI tests verified the Pro Mode required state. |
| Find Icon search and keyboard navigation | NOT TESTED | Requires Pro Mode/Accessibility state with live snapshots. |
| Find Icon visible/hidden/always-hidden activation | NOT TESTED | Requires real menu bar state. |
| Highlight overlay | NOT TESTED | Requires hands-on UI verification. |
| Second Bar unavailable state | PASS | UI tests verified requirements and privacy copy. |
| Second Bar placements/search/keyboard/auto-close | NOT TESTED | Requires hands-on UI verification. |
| External display/notch Second Bar behavior | NOT TESTED | Requires hardware setup. |

## Icon Moving

| Scenario | Result | Notes |
| --- | --- | --- |
| Disabled by default | NOT TESTED | Requires hands-on Settings verification. |
| Experimental warning before enablement | NOT TESTED | Requires hands-on Settings verification. |
| Move third-party item to Hidden/Visible/Always Hidden | NOT TESTED | Requires third-party menu bar items and Accessibility permission. |
| Move Left / Move Right | NOT TESTED | Requires third-party menu bar items and Accessibility permission. |
| Reject own app/system items | NOT TESTED | Requires real menu bar state. |
| Permission revoke/display change during move | NOT TESTED | Requires live system-state testing. |

## Profiles, Triggers, Health

| Scenario | Result | Notes |
| --- | --- | --- |
| Profile create/duplicate/delete/export/import | NOT TESTED | Requires hands-on profile UI flow. |
| Dry run and Basic-only apply | NOT TESTED | Requires hands-on profile UI flow. |
| Pro moves are report-only on profile apply | NOT TESTED | Requires hands-on profile UI flow. |
| Display/app/time triggers | NOT TESTED | Requires live system events. |
| Pause all automation | NOT TESTED | Requires hands-on Settings validation. |
| Crash marker Safe Mode | NOT TESTED | Requires controlled crash-marker setup. |
| Option-key Safe Mode | NOT TESTED | Requires hands-on launch modifier testing. |
| Safe Mode next launch flag | NOT TESTED | Requires hands-on relaunch validation. |
| Fix Automatically | NOT TESTED | Requires hands-on Diagnostics recovery flow. |
| Export Health Report | NOT TESTED | Requires hands-on save-panel flow. |

## Release Install

| Scenario | Result | Notes |
| --- | --- | --- |
| Archive | NOT TESTED | No archived distribution artifact was produced in this pass. |
| Codesign verification | PASS | Local Release app passed `codesign --verify --strict --verbose=2`. |
| Notarization or skip reason | NOT TESTED | Skipped because no Developer ID notarized distribution artifact was produced. |
| Installed app launch | NOT TESTED | Requires copying/installing signed app outside DerivedData. |
| Launch at Login from installed signed app | NOT TESTED | Requires installed signed app validation through System Settings. |
| Network watch | PASS | Non-interactive Release-app `lsof` probe showed no network connections; interactive `sudo nettop` remains manual. |

## Summary

Blocking automated issues: none.

Known manual blockers:

- Real first-launch/onboarding flow from clean user defaults.
- Real Command-drag separator placement.
- Basic Mode runtime collapse/expand/reveal all, auto-rehide, hover reveal, and hotkey behavior.
- Real Accessibility grant/revoke flow through System Settings.
- Real third-party menu bar icon moving.
- External display and external-primary-display behavior.
- Notch display behavior.
- Sleep/wake, display disconnect, full-screen app, and Space-switch recovery.
- Profile/trigger/Safe Mode hands-on flows.
- Launch at Login from an installed signed app.
- Runtime interactive network watch with `sudo nettop`.
- Archive/notarized distribution artifact verification.

Alpha RC recommendation: automated preflight and local Release artifact verification passed. Continue with hands-on QA before publishing an Alpha RC.
