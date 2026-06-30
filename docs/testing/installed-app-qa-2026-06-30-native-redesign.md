# Installed App QA - Native Redesign

Date: 2026-06-30
Tester: Codex
Build: `0.1.1 (2)`
Source commits covered: `ca20f3e` through `4de5517`
Artifact type: dry-run local release archive/export, Apple Development signed, not notarized
Installed app: `/Applications/MenuBarDeclutter.app`
macOS: `26.1 (25B78)`

This run covers the installed-app acceptance pass after the native macOS Settings redesign. It focuses on the real installed app, Basic Mode privacy boundaries, native Settings surfaces, diagnostics export, and release-script verification.

## Summary

| Area | Result | Notes |
| --- | --- | --- |
| Release archive/export/package/install | PASS | `scripts/build_release.sh --dry-run --install --verify-installed` completed after the diagnostics export fix. |
| Installed app verification | PASS | Bundle ID, versions, `LSUIElement`, URL scheme, sandbox, hardened runtime, no network entitlements, and no ScreenCaptureKit linkage verified. |
| Privacy boundary | PASS | Source and built app contain no Screen Recording, Apple Events, Input Monitoring, direct network client APIs, analytics SDKs, network entitlements, or ScreenCaptureKit linkage. |
| Native Settings page pass | PASS | General, Menu Bar Items, Behavior, Layout, Search, Second Bar, Groups, Hotkeys, Profiles, Automation, Privacy, Private Access, Import / Export, Diagnostics, and Advanced inspected in the installed app. |
| Health report export | PASS after fix | Initial installed app exposed an AppKit/SwiftUI save-panel crash. Patched and reverified with the installed app. |
| URL scheme smoke | PASS | `menubardeclutter://expand` did not launch a stale duplicate; process remained `/Applications/MenuBarDeclutter.app`. Automation stayed paused and Diagnostics remained healthy. |
| Network watch | PASS | `scripts/qa_network_watch.sh --installed` observed no sockets for the installed process. |
| Clean crash-marker recovery | PASS | Clean quit removed `running.marker`; relaunch returned Diagnostics to `Health: OK` without previous-crash badge. |
| Launch at Login toggle | PASS | Enabled from the installed app, observed `Login Item Enabled`, then disabled and refreshed back to `Not Registered`; app defaults restored to `launchAtLoginEnabled = 0`. |
| Developer ID export | BLOCKED | Real export probe failed with `No signing certificate "Developer ID Application" found`; only an Apple Development identity is installed. |
| Gatekeeper notarization validation | EXPECTED FAIL | Dry-run app passes strict codesign verification, but `spctl` rejects it and `stapler` reports no ticket until Developer ID notarization is available. |

## Installed UI Pass

| Page | Result | Observations |
| --- | --- | --- |
| General | PASS | Shows `MenuBarDeclutter 0.1.1 (2) - Basic Mode`, installed location `/Applications/MenuBarDeclutter.app`, Launch at Login off, and Basic Mode privacy copy. |
| Menu Bar Items | PASS | Basic Mode Pro discovery is off; Refresh is gated; copy states discovery is opt-in Pro and Basic Mode does not request Accessibility. |
| Behavior | PASS | Auto-rehide, hover reveal, hidden zone, and shortcut controls degrade clearly while disabled. |
| Layout | PASS | Capacity/suggestions/full menu bar/spacer state shown; approximate geometry fallback is explicit without an Accessibility snapshot. |
| Search | PASS | Find Icon is gated by Pro Mode, not Safe Mode, after clean relaunch. |
| Second Bar | PASS | Second Bar and Icon Panel are gated by Pro Mode; copy states no Screen Recording or captured pixels. |
| Groups | PASS | Basic preview state is visible with empty-state messaging. |
| Hotkeys | PASS | Dynamic hotkeys are preview/off with no bindings. |
| Profiles | PASS | Profiles and triggers show empty preview state; automation remains paused. |
| Automation | PASS | App Intents are visible; gated actions remain blocked while automation is paused. |
| Privacy | PASS | Basic Mode reports Screen Recording, Apple Events, Input Monitoring, and network as not requested/not used. |
| Private Access | PASS | Private Access is off; authentication test remains disabled until enabled. |
| Import / Export | PASS | Export/import assistant surfaces local JSON workflow and privacy exclusions. |
| Diagnostics | PASS | Health controls, screens, dogfood, and live status are visible; health export works after patch. |
| Advanced | PASS | Separator geometry, diagnostics paths, automation pause, and Labs controls are visible and native-feeling. |

## Export Crash Found And Fixed

Initial installed-app acceptance found a real crash when activating **Export Health Report** through Accessibility/Computer Use:

- Crash reports:
  - `/Users/thesmartaz/Library/Logs/DiagnosticReports/MenuBarDeclutter-2026-06-30-095651.ips`
  - `/Users/thesmartaz/Library/Logs/DiagnosticReports/MenuBarDeclutter-2026-06-30-095926.ips`
- First stack: `DiagnosticsSettingsView.exportHealthReport()` -> `NSSavePanel.runModal()`.
- Second stack after the first attempt at sheet conversion: `DiagnosticsSettingsView.presentSavePanel(_:completion:)` -> `NSSavePanel.beginSheetModal`.
- Root cause observed: presenting the save panel synchronously from a SwiftUI accessibility button action could hit AppKit layout re-entrancy.
- Fix: `DiagnosticsSettingsView` now presents diagnostics save panels asynchronously after a short main-run-loop delay and uses native sheet presentation/completion handlers.
- Retest: the **Export Health Report** sheet appeared, Save completed, the success banner displayed, and no new crash report was created.

Exported file:

`/Users/thesmartaz/Documents/MenuBarDeclutter-health-2026-06-30_170110.txt`

Verified content:

```text
MenuBarDeclutter Health Report
Generated: 2026-06-30T17:00:52Z
Status: OK

No health issues detected.
```

Privacy scan of the exported report found no screenshot text, screen-content text, network terms, ScreenCaptureKit terms, Apple Events terms, Input Monitoring terms, or personal paths.

## Commands

| Command | Result |
| --- | --- |
| `xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build` | PASS |
| `scripts/build_release.sh --dry-run --install --verify-installed` | PASS after diagnostics export fix |
| `scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app` | PASS with expected non-notarized `spctl`/stapler warnings |
| `scripts/verify_privacy_boundary.sh build/Export/MenuBarDeclutter.app` | PASS |
| `scripts/qa_network_watch.sh --installed` | PASS, no sockets observed for PID `69431` |
| `/usr/bin/open -b Yongjun-Zhang.MenuBarDeclutter 'menubardeclutter://expand'` | PASS, single installed process stayed active |
| `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` | PASS, 410 Swift tests and 11 UI tests |
| `git diff --check` | PASS |
| `for key in launchAtLoginEnabled appMode startCollapsed proModeEnabled accessibilityDiscoveryEnabled automationPaused; do printf '%s=' "$key"; defaults read Yongjun-Zhang.MenuBarDeclutter "$key" 2>/dev/null || printf '<unset>\n'; done` | PASS, restored state was Launch at Login off, `appMode = basic`, Pro Mode off, Accessibility Discovery off, automation paused |
| `lsof -Pan -p 1082 -i` | PASS, no network sockets for the running installed app |
| `sudo -n nettop -P -L 1 -p 1082` | BLOCKED, passwordless sudo is unavailable in this session |
| `security find-identity -v -p codesigning` | BLOCKED for release signing, only `Apple Development: emailyongjunzhang@gmail.com (834922P6J6)` is installed |
| `ARCHIVE_PATH="$PWD/build/Archives/MenuBarDeclutter.xcarchive" EXPORT_DIR="$PWD/build/ExportDeveloperIDProbe" APP_PATH="$PWD/build/ExportDeveloperIDProbe/MenuBarDeclutter.app" scripts/release_export_app.sh` | EXPECTED FAIL, `No signing certificate "Developer ID Application" found` |
| `scripts/release_validate_gatekeeper.sh build/Export/MenuBarDeclutter.app` | EXPECTED FAIL for dry-run build: codesign strict verification PASS; `spctl` rejected; stapler ticket missing |

## Follow-Up System-State Gates

Launch at Login was exercised through the installed app after the initial non-mutating pass:

1. Started with General showing `Launch at Login` off, status `Not Registered`, installed path `/Applications/MenuBarDeclutter.app`, and Basic Mode privacy copy.
2. Enabled `Launch at Login`; the UI reported `Login Item Enabled`, `Login Item Status Enabled`, and `Last Login Item Action Registered`.
3. Disabled `Launch at Login` again; after refresh, the UI reported `Login Item Not Registered`, `Login Item Status Not Registered`, and `Last Login Item Action Unregistered`.
4. Verified persisted app state from defaults: `launchAtLoginEnabled = 0`, `appMode = basic`, `startCollapsed = 0`, `proModeEnabled = 0`, `accessibilityDiscoveryEnabled = 0`, and `automationPaused = 1`.

Developer ID release gates were also probed without disturbing the verified dry-run export:

1. Codesigning identities contain only an Apple Development certificate.
2. Real `xcodebuild -exportArchive` to `build/ExportDeveloperIDProbe` failed because no Developer ID Application certificate is installed.
3. Gatekeeper validation against the dry-run exported app passed strict codesign verification and failed `spctl`/stapler as expected for a non-notarized local artifact.

## Deferred System-State Checks

These remain intentionally untested because they require disruptive OS changes, external credentials, hardware, or user-login session control:

- Logout/login or restart validation of Launch at Login behavior.
- Changing macOS Privacy & Security grants, including Accessibility grant/revoke behavior. Accessibility is currently granted on this Mac, but Pro Mode and Accessibility Discovery were restored off.
- Interactive `sudo nettop` observation with an administrator password.
- Restart/logout/login acceptance.
- Real Developer ID notarization/stapling with external Apple credentials.

## Notes

- Dry-run artifacts are not notarized. `spctl` rejection and missing stapler ticket remain expected until Developer ID signing and notarization are available.
- Accessibility permission is currently granted on this Mac, but Pro Mode and discovery stayed off during this pass.
- The installed app was cleanly quit before the final full test run to avoid bundle-ID conflicts with UI tests.
