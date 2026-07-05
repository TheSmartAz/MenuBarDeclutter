# v0.1.1 Signing And Physical QA Follow-Up

Date: 2026-06-30
Tester: Codex
Branch: `codex/native-macos-redesign`
Installed app: `/Applications/MenuBarDeclutter.app`
Installed PID: `90987`

This follow-up records the Apple distribution credential probe and the non-disruptive physical/system QA checks that can be run from the current desktop session. It does not change macOS Privacy & Security grants, reboot/logout, sleep the machine, install credentials, or transmit Apple account secrets.

## Summary

| Area | Result | Notes |
| --- | --- | --- |
| Developer ID certificate | BLOCKED | `security find-identity -v -p codesigning` reports only `Apple Development: emailyongjunzhang@gmail.com (834922P6J6)`. No `Developer ID Application` identity is installed. |
| Notary profile | BLOCKED | `xcrun notarytool history --keychain-profile MenuBarDeclutterNotary` reports no keychain password item for that profile. |
| Developer ID export | EXPECTED FAIL | `scripts/release_export_app.sh` against `build/Archives/MenuBarDeclutter.xcarchive` failed with `No signing certificate "Developer ID Application" found`, exit `70`. |
| Notarization submit | EXPECTED FAIL | `scripts/release_notarize.sh build/Dist/MenuBarDeclutter-v0.1.1-alpha.zip` failed before submission because credentials are missing, exit `1`. |
| Dry-run Gatekeeper validation | EXPECTED FAIL | Strict `codesign` verification passed; `spctl` rejected and stapler reported no ticket because the artifact is not notarized. |
| Installed app verification | PASS | `scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app` passed with expected non-notarized `spctl` and stapler warnings. |
| Installed privacy boundary | PASS | `APP_PATH=/Applications/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` passed. |
| Runtime network watch | PASS | `scripts/qa_network_watch.sh --installed` observed no sockets for PID `90987`. |
| Basic Mode state | PASS | Defaults remained `appMode = basic`, `proModeEnabled = 0`, `accessibilityDiscoveryEnabled = 0`, `automationPaused = 1`, and `launchAtLoginEnabled = 0`. |
| Settings UI readback | PASS | Computer Use read the installed Settings window. General showed Basic Mode, Login Item Not Registered, installed in Applications, Onboarding Done, and the Basic Mode privacy message. |
| URL automation paused smoke | PASS | `/usr/bin/open -b Yongjun-Zhang.MenuBarDeclutter 'menubardeclutter://expand'` kept a single installed process (`90987`) and left `isCollapsed` unchanged while automation was paused. |
| Crash check | PASS | No new `MenuBarDeclutter` crash reports were created during this pass; only the two older diagnostics-export crash reports from the previously fixed issue remain. |
| Display inventory | PARTIAL | `system_profiler SPDisplaysDataType` shows only the built-in Liquid Retina XDR display. External display QA is unavailable in this session. |
| Shortcuts/App Intents | PARTIAL | `shortcuts list` lists user-created shortcuts only. Real Shortcuts app execution remains hands-on QA. |
| Menu bar status item live interaction | BLOCKED | Computer Use can read the Settings window, but `SystemUIServer` inspection timed out again. Live status item click, command-drag, and hover-only checks remain physical QA. |
| Restart/logout/sleep/wake | BLOCKED | Not run because those actions would disrupt or end this session. |
| Accessibility grant/revoke and Touch ID | BLOCKED | Not run because they require physical user/system permission interaction and may mutate macOS Privacy & Security or authentication state. |

## Commands

| Command | Result |
| --- | --- |
| `security find-identity -v -p codesigning` | BLOCKED for Developer ID release; only Apple Development identity present. |
| `xcrun notarytool history --keychain-profile MenuBarDeclutterNotary` | BLOCKED; profile missing from keychain. |
| `ARCHIVE_PATH="$PWD/build/Archives/MenuBarDeclutter.xcarchive" EXPORT_DIR="$PWD/build/ExportDeveloperIDProbe" APP_PATH="$PWD/build/ExportDeveloperIDProbe/MenuBarDeclutter.app" scripts/release_export_app.sh` | EXPECTED FAIL, exit `70`; no Developer ID Application certificate. |
| `scripts/release_notarize.sh build/Dist/MenuBarDeclutter-v0.1.1-alpha.zip` | EXPECTED FAIL, exit `1`; credentials missing. |
| `scripts/release_validate_gatekeeper.sh build/Export/MenuBarDeclutter.app` | EXPECTED FAIL for dry-run artifact; strict codesign passed, `spctl` and stapler failed. |
| `/usr/bin/open -a /Applications/MenuBarDeclutter.app` | PASS; installed app running as PID `90987`. |
| `scripts/qa_network_watch.sh --installed` | PASS; no sockets observed for PID `90987`. |
| `APP_PATH=/Applications/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh` | PASS. |
| `scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app` | PASS with expected non-notarized warnings. |
| `system_profiler SPDisplaysDataType` | PARTIAL; built-in display only. |
| `shortcuts list` | PARTIAL; user shortcuts listed, no runnable MenuBarDeclutter shortcut execution through CLI. |
| `pmset -g custom` | INFO; power settings recorded without sleeping the machine. |
| `pgrep -ax MenuBarDeclutter && lsof -Pan -p 90987 -i` | PASS; process running and no sockets listed. |

## Remaining Release Gates

1. Install a valid `Developer ID Application` certificate in the login keychain.
2. Store a notary profile such as `MenuBarDeclutterNotary` outside the repo.
3. Run `scripts/build_release.sh --version 0.1.1 --notarize --staple`.
4. Run notarized artifact validation and Gatekeeper validation.
5. Complete physical QA for live menu bar item click, command-drag positioning, hover-only behavior, restart/logout Launch at Login behavior, sleep/wake, external displays, Accessibility grant/revoke, real Shortcuts app execution, and Touch ID/Private Access prompts.
