# Manual v0.1.2 System QA

Use this matrix for hands-on system behavior that cannot be fully verified by unit tests.

Record every result in `docs/testing/manual-v0.1.2-results.md` as `PASS`, `FAIL`, `PARTIAL-PHYSICAL`, `BLOCKED-PHYSICAL`, `BLOCKED-HARDWARE`, `BLOCKED-INFRA`, or `DEFERRED`. Any `FAIL` for an intended stable Basic Mode claim must be fixed, downgraded, or explicitly deferred before release.

## Setup

1. Build and install the current dry-run artifact:

   ```sh
   bash scripts/build_release.sh --dry-run --install --verify-installed
   ```

2. Confirm `/Applications/MenuBarDeclutter.app` reports `0.1.2 (3)`.
3. Keep Console or `log stream` available if a launch or permission state is unclear.
4. Before each manual section, clear only script-controlled markers if needed:

   ```sh
   rm -f "$HOME/Library/Containers/Yongjun-Zhang.MenuBarDeclutter/Data/Library/Application Support/MenuBarDeclutter/running.marker"
   rm -f "$HOME/Library/Containers/Yongjun-Zhang.MenuBarDeclutter/Data/Library/Application Support/MenuBarDeclutter/safe-mode-next-launch.flag"
   ```

## Basic Live Menu Bar

| Check | Exact Steps | Expected Result | Evidence To Record |
| --- | --- | --- | --- |
| URL expand/collapse/reveal-all | Run `bash scripts/qa_installed_app_smoke.sh`, or open `menubardeclutter://expand`, `menubardeclutter://collapse`, and `menubardeclutter://reveal-all` against the installed app | URL commands reuse the installed app process with no sensitive permission prompts or network access | Log path and PID reuse |
| Status menu opens | Launch installed app, locate MenuBarDeclutter status item, click or right-click it | Everyday menu opens and includes Hide, Show, Reveal All, Arrange Items, Find Icon, Show Second Bar, Full Menu Bar Mode, Settings, Recovery, Diagnostics, Quit | Screenshot path |
| Control Command-drag | Hold Command and drag the MenuBarDeclutter control item to a visible reachable spot | Control moves using normal macOS menu bar behavior and remains reachable after relaunch | Screenshot before/after, pass/fail note |
| Separator Command-drag | Hold Command and drag the primary separator to the intended hidden boundary | Separator moves and the hidden side is understandable | Screenshot before/after |
| Collapse/expand | Use status menu or control click to Collapse, then Expand | Items on hidden side hide and return; control remains reachable | Screenshot or short screen recording |
| Reveal All | Collapse, then choose Reveal All or use the URL command | Hidden and always-hidden regions become reachable without sensitive permission prompts | Screenshot |
| Always-hidden reveal | Configure an always-hidden region, place at least one item there, collapse, then use Reveal All and normal expand/collapse | Always-hidden behavior is understandable and the item can be recovered | Screenshot and notes |
| Reset layout | Use Recovery or Arrange Reset Layout after moving control/separator | App-owned status items return to a usable layout | Screenshot and notes |
| Stable global hotkey | Enable the Basic global visibility hotkey, press it outside Settings, and repeat while another app is active | Hotkey toggles visibility without Input Monitoring permission | Key combo, app focus, result |
| Auto-rehide timing | Enable auto-rehide with a short delay, expand, wait, then interact near the menu bar before the delay expires | Delayed rehide happens at the configured time and does not feel flickery or trap items | Timing notes |
| Hover reveal | Enable hover reveal, collapse, move pointer into and out of the menu bar band | Hover reveal expands predictably without event taps or permission prompts | Timing/flicker notes |

## Arrange

| Check | Exact Steps | Expected Result | Evidence To Record |
| --- | --- | --- | --- |
| Open from Settings | Open Settings -> Arrange | Page opens without Pro Mode, Accessibility, Screen Recording, Apple Events, Input Monitoring, or network prompts | Screenshot |
| Open from status menu | Choose Arrange Items from the status menu | Arrange page opens from the everyday menu route | Screenshot or note |
| Guided steps readable | Read each guided step on the page, including hidden and optional always-hidden placement guidance | Copy and diagrams are readable at current display size | Screenshot |
| Placement buttons | Press Expand, Collapse, Reveal All, Reset Layout, and Show Drag Hint | Buttons affect only app-owned Basic controls and do not request sensitive permissions | Notes and screenshot |
| Real placement pass | Command-drag control and separator, then run Collapse, Expand, Reveal All, and Reset Layout | Manual Command-drag flow is usable as the intended stable path | Before/after screenshots |

## Find & Rescue

| Check | Exact Steps | Expected Result | Evidence To Record |
| --- | --- | --- | --- |
| Pro off | Open Find & Rescue with Pro Mode off | Find Icon, Second Bar, New Items, and crowded fallback explain unavailable states without prompting | Screenshot |
| Pro on, Discovery off | Enable Pro Mode only, return to Find & Rescue | Discovery remains off and Pro surfaces stay degraded with clear next steps | Screenshot |
| Discovery on, permission missing | Enable Accessibility Discovery without granting Accessibility | Request Permission remains explicit; no automatic prompt appears | Screenshot |
| Permission granted metadata | Grant Accessibility, rescan, then open Find Icon and Second Bar | Metadata surfaces become available or clearly explain missing third-party metadata | Screenshot and item count if visible |
| New Item Inbox with fixture | Run or launch the fixture app with deterministic items, rescan, and open New Items | New Item Inbox detects or explains new discovered items without leaking raw private identifiers | Screenshot |
| Crowded fallback | Create a crowded menu bar with many items or long menus, then trigger crowded reveal paths | Inline reveal, Second Bar, Full Menu Bar Mode, or layout suggestion fallback is understandable | Screenshot and notes |

## Pro Permission

| Check | Exact Steps | Expected Result | Evidence To Record |
| --- | --- | --- | --- |
| Pro off default | Fresh launch, open Privacy | Basic Mode is usable and Pro controls are inactive without prompts | Screenshot |
| Enable Pro only | Press Enable Pro Mode | Accessibility Discovery remains separate and off; no system prompt appears | Screenshot |
| Enable Discovery | Toggle Accessibility Discovery | Permission row explains that Request Permission is explicit | Screenshot |
| Request permission | Press Request Permission | macOS Accessibility prompt opens only from this explicit action | Screenshot or note |
| Grant Accessibility | Grant MenuBarDeclutter in System Settings -> Privacy & Security -> Accessibility, then return and rescan | Permission state updates and Pro metadata features can refresh | Screenshot |
| Revoke Accessibility | Revoke Accessibility, restart app, and reopen Privacy, Find Icon, and Second Bar | Pro features degrade gracefully; Basic Mode still works | Screenshot |

## Notch And Crowded Layout

| Check | Exact Steps | Expected Result | Evidence To Record |
| --- | --- | --- | --- |
| Notch MacBook | On a notch MacBook, place control/separator near both sides of the notch and test Collapse/Expand/Reveal All | Status items stay reachable and do not disappear behind the notch | Screenshot |
| Many menu items | Launch enough menu bar apps or fixture items to crowd the bar | Crowding does not trap the control or separator | Screenshot |
| Long app menus | Use an app with long menu titles/menus active, then test reveal/collapse | Layout remains understandable with long app menus | Screenshot |
| Second Bar fallback | With Pro gates satisfied, trigger Second Bar fallback from a crowded state | Second Bar is available or clearly unavailable with recovery guidance | Screenshot |

## External Displays

| Check | Exact Steps | Expected Result | Evidence To Record |
| --- | --- | --- | --- |
| Attach display | Attach an external display while the app is running | Status items remain reachable or Recovery restores layout | Display topology and screenshot |
| Detach display | Detach the external display | App recomputes layout and does not trap items | Display topology and screenshot |
| Switch main display | Change the main display in System Settings | Status items remain reachable on the active menu bar | Screenshot |
| Mirror mode | Enable mirror mode and test Collapse/Expand/Reveal All | Behavior is understandable and reversible | Screenshot |
| Sleep/wake | Sleep and wake after a display change | Status items recover or Recovery actions work | Notes |

## Launch At Login

| Check | Exact Steps | Expected Result | Evidence To Record |
| --- | --- | --- | --- |
| Default state | Install app and inspect Launch at Login setting | Default is off unless previously enabled by the user | Defaults or screenshot |
| Enable | Enable Launch at Login from Settings | Login item is registered through public `SMAppService.mainApp` | Screenshot and any Background Task Management evidence |
| Logout/login | Log out and back in | App launches as expected and status item is reachable | Time, screenshot, process PID |
| Restart | Restart if available | App launches as expected and does not enter false Safe Mode | Time, screenshot, process PID |
| Disable | Disable Launch at Login, then repeat login transition if possible | App no longer auto-launches | Screenshot and notes |

## Recovery

| Check | Exact Steps | Expected Result | Evidence To Record |
| --- | --- | --- | --- |
| Option-launch Safe Mode | Quit app, hold Option while launching `/Applications/MenuBarDeclutter.app` | Safe Mode starts expanded and suppresses optional surfaces | Screenshot |
| One-shot Safe Mode flag | Run `bash scripts/qa_installed_app_smoke.sh` or write the sandbox-aware flag path and launch | Exact flag is consumed once, then normal relaunch works | Log path |
| Crash-marker recovery | Create a synthetic previous-launch marker or use the existing script evidence | Safe Mode menu appears, then normal menu returns after marker clear | Screenshot/log |
| Reset layout | From Recovery, run Reset Layout and Recreate Status Items if needed | App-owned items return to a usable layout | Screenshot |
| Guide fallback | Open the "I can't find my icons" guide from Recovery | Bundled or Application Support fallback guide opens locally | Screenshot |

## Diagnostics And Installed App

| Check | Exact Steps | Expected Result | Evidence To Record |
| --- | --- | --- | --- |
| Dry-run release | Run `bash scripts/build_release.sh --dry-run --install --verify-installed` | Archive/export/package/install/open/verify passes as `0.1.2 (3)` with expected non-notarized dry-run warnings only | Log path |
| Installed verification | Run `bash scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app` | Bundle identity, version/build, sandbox, LSUIElement, URL scheme, privacy keys, codesign, hardened runtime, and ScreenCaptureKit linkage checks pass | Log path |
| No-network watch | Run `bash scripts/qa_network_watch.sh --installed` while app is running | No network sockets are observed | Log path |
| Diagnostics export | Export diagnostics from Settings or Recovery and inspect the saved file | Export is explicit, local, and privacy-redacted | Screenshot, file path, privacy spot-check notes |
| Uninstall support | Read `docs/support/uninstall.md` and optionally run dry-run uninstall flow if available | User data and sandbox container paths are documented clearly | Notes |

## Completion Rule

Stable Basic Mode claims are not complete while any related row remains `FAIL`, `PARTIAL-PHYSICAL`, `BLOCKED-PHYSICAL`, or `BLOCKED-HARDWARE`, unless the claim is downgraded, scoped out, or explicitly deferred in release notes and the release checklist.
