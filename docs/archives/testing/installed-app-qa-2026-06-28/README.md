# Installed-App QA - 2026-06-28

Installed app: `/Applications/MenuBarDeclutter.app`

This run covers the non-mutating installed-app checks from `docs/testing/installed-app-qa.md`. Checks that change macOS Login Items, privacy grants, or login session state were left unexecuted so they can be run only with explicit action-time confirmation.

## Summary

| Area | Result | Notes |
| --- | --- | --- |
| Installed bundle identity | PASS | Bundle ID `Yongjun-Zhang.MenuBarDeclutter`, version `0.1.0 (1)`, `LSUIElement = true`, `LSMinimumSystemVersion = 26.0`. |
| Launch from `/Applications` | PASS | App launched from `/Applications/MenuBarDeclutter.app`; General and Diagnostics both report the installed path. |
| Menu bar items | PASS | Accessibility query found `MenuBarDeclutter control` and `Hidden items separator`. |
| Settings pages | PASS | General, Behavior, Search, Second Bar, Profiles, Privacy, Diagnostics, and Advanced were opened and screenshotted. |
| Basic Mode privacy boundary | PASS | Privacy page shows sensitive permissions as not requested/not used; verification script passed. |
| Collapse/expand | PASS | Status item toggle changed Diagnostics from collapsed to expanded and was restored to collapsed. |
| URL automation | PASS | While automation was paused, `menubardeclutter://expand` left state collapsed as expected. After temporarily resuming automation, `expand` changed state to expanded and `collapse` restored collapsed. Automation was restored to paused. |
| Network watch | PASS | `lsof` and `scripts/qa_network_watch.sh --installed` observed no network sockets for PID `26594`. |
| Launch at Login status read | PASS | General showed Launch at Login off and `SMAppService Status: Not Found`; refresh kept the same state. |
| Pro/Accessibility degraded state | PASS | Search and Second Bar remain disabled/degraded with Pro Mode off and Accessibility permission not requested. |

## Commands

| Command | Result |
| --- | --- |
| `plutil -p /Applications/MenuBarDeclutter.app/Contents/Info.plist` | PASS. Verified bundle identifier, display name, version/build, URL scheme, `LSUIElement`, and macOS 26 minimum. |
| `codesign -dv --verbose=4 /Applications/MenuBarDeclutter.app` | PASS. App is signed by Apple Development identity `emailyongjunzhang@gmail.com (834922P6J6)`, Team `LT2MVX436A`. |
| `scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app` | PASS. Expected warnings only: `spctl` rejection and no stapled ticket for a non-notarized dry-run artifact. |
| `open /Applications/MenuBarDeclutter.app` | PASS. Running PID was `26594`. |
| `osascript ... description of every menu bar item of menu bar 2` | PASS. Returned `MenuBarDeclutter control, Hidden items separator`. |
| `lsof -Pan -p 26594 -i` | PASS. No output, meaning no network sockets. |
| `scripts/qa_network_watch.sh --installed` | PASS. Reported `No network sockets observed for PID 26594.` |
| `open -b Yongjun-Zhang.MenuBarDeclutter 'menubardeclutter://expand'` | PASS after resuming automation. Diagnostics showed `Visibility State expanded`, `Primary Separator Length 20`. |
| `open -b Yongjun-Zhang.MenuBarDeclutter 'menubardeclutter://collapse'` | PASS. Diagnostics showed `Visibility State collapsed`, `Primary Separator Length 3,456`. |
| `defaults read Yongjun-Zhang.MenuBarDeclutter automationPaused` | PASS after restore. Returned `1`. |
| `defaults read Yongjun-Zhang.MenuBarDeclutter isCollapsed` | PASS after restore. Returned `1`. |
| `defaults read Yongjun-Zhang.MenuBarDeclutter launchAtLoginEnabled` | PASS after restore. Returned `0`. |
| `defaults read Yongjun-Zhang.MenuBarDeclutter proModeEnabled` | PASS after restore. Returned `0`. |
| `defaults read Yongjun-Zhang.MenuBarDeclutter accessibilityDiscoveryEnabled` | PASS after restore. Returned `0`. |

## Screenshots

| File | Evidence |
| --- | --- |
| `screenshots/01-installed-settings-general.png` | General page, installed path, version/build, Launch at Login off. |
| `screenshots/02-installed-menu-bar-items.png` | Menu bar items visible on installed app. |
| `screenshots/03-installed-privacy-basic-boundary.png` | Basic Mode sensitive permissions not requested/not used. |
| `screenshots/04-installed-launch-login-status-refreshed.png` | Launch at Login status after refresh. |
| `screenshots/05-installed-diagnostics-collapsed-live-status.png` | Initial collapsed Diagnostics state. |
| `screenshots/06-installed-diagnostics-expanded-after-toggle.png` | Expanded state after status item toggle. |
| `screenshots/07-installed-diagnostics-restored-collapsed.png` | Collapsed state restored after toggle. |
| `screenshots/08-installed-url-expand-remained-collapsed.png` | URL expand while automation paused left state collapsed. |
| `screenshots/09-installed-url-expand-success.png` | URL expand success with automation resumed. |
| `screenshots/10-installed-url-collapse-success.png` | URL collapse success. |
| `screenshots/11-installed-advanced-automation-restored-paused.png` | Advanced page showing automation paused restored. |
| `screenshots/12-installed-settings-behavior.png` | Behavior page. |
| `screenshots/13-installed-settings-search.png` | Search page degraded safely in Basic Mode. |
| `screenshots/14-installed-settings-second-bar.png` | Second Bar page degraded safely in Basic Mode. |
| `screenshots/15-installed-settings-profiles.png` | Profiles page with automation paused restored. |

## Not Executed

These require explicit action-time confirmation or hardware/session conditions outside this non-mutating pass:

| Scenario | Reason |
| --- | --- |
| Enable Launch at Login | Changes macOS Login Items through UI/system service. |
| Disable Launch at Login after enabling | Depends on the prior system-setting change. |
| Logout/login or restart validation | Changes the user's live login session. |
| Request Accessibility permission | Opens/modifies macOS privacy flow and may require a grant. |
| Revoke Accessibility permission | Changes macOS privacy settings. |
| Real Pro Mode AX scan with granted permission | Depends on the Accessibility grant above. |
| External display, notch, Spaces, sleep/wake checks | Requires hardware/session state changes. |
| Real third-party icon moving | Experimental Pro behavior with live menu bar side effects. |

## Outcome

No blocking issue was found in the installed-app non-mutating pass. The only nuance was URL automation: it correctly did nothing while `automationPaused` was on, then worked when automation was temporarily resumed. The app was restored to collapsed Basic Mode with automation paused, Launch at Login off, Pro Mode off, and Accessibility discovery off.
