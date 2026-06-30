# Manual v0.1.1 System QA Results - 2026-06-29

Date: 2026-06-29
Tester: Codex with Codex Computer Use and local shell verification
Build: MenuBarDeclutter 0.1.1 (2), bundle ID `Yongjun-Zhang.MenuBarDeclutter`
macOS version: macOS 26.1 (25B78)
Hardware: MacBook Pro Mac16,7, Apple M4 Pro, 14 CPU cores, 48 GB memory
Displays: Built-in Liquid Retina XDR Display, 3456 x 2234 Retina, main display; no external display detected
Installed path: `/Applications/MenuBarDeclutter.app`
Build source: `scripts/build_release.sh --dry-run --install --verify-installed`, development-signed and not notarized
Pro Mode: started with stored `proModeEnabled = 1`; clean-launch health recovery disabled Pro Mode because Accessibility permission was missing; left off as the safe recovered state
Accessibility Discovery: started enabled; disabled by clean-launch health recovery with Pro Mode
Accessibility permission: Not Requested
Labs enabled: App Intents Labs Access off; icon moving off; spacing Labs not enabled
Safe Mode: previous crash marker path observed and then cleared for clean-launch follow-up
Automation paused: yes after QA restore; temporarily resumed only for URL automation and auto-rehide checks
Menu bar auto-hide: `_HIHideMenuBar` default absent; not changed during QA

| Gate | PASS/FAIL/BLOCKED | Notes |
| --- | --- | --- |
| First-run onboarding | PASS | Covered by the installed-app Computer Use run in `manual-v0.1.1-results-2026-06-29-computer-use.md`; not replayed here to avoid changing onboarding state again. |
| Basic live menu bar | BLOCKED | App installed and launched, but Computer Use timed out when inspecting `SystemUIServer`; live status item click and command-drag checks still require hands-on menu bar QA. Diagnostics/logs confirm URL-driven collapse/expand/reveal-all commands can change internal visibility state when automation is not paused. |
| Auto-rehide and hover reveal | PASS / BLOCKED | Initial installed-app QA found auto-rehide scheduled after URL-driven expand but not firing while Settings was closed. The runtime was fixed to use a main-actor task countdown instead of a run-loop timer, then reinstalled from `scripts/build_release.sh --dry-run --install --verify-installed`. A focused installed-app pass enabled auto-rehide at 5s, resumed automation, closed Settings, invoked `menubardeclutter://collapse` and `menubardeclutter://expand`, waited past the delay, and confirmed `isCollapsed = 1`; Computer Use Diagnostics then showed `Visibility collapsed`, `Accessibility Not Requested`, and `Automation Ready`. Hover reveal remains blocked because the current Computer Use tool exposes clicks/scrolls but not a controllable hover-only pointer pass over the menu bar band. Auto-rehide and automation pause were restored after the test. |
| Crowded menu bar | BLOCKED | Requires a deliberately crowded live menu bar and physical command-drag/spacing validation. |
| Second Bar fallback | PASS / BLOCKED | Settings correctly show Stable/Pro/Accessibility requirements, disabled controls, and `Not Requested` permission fallback. Live Second Bar placement and item interaction remain blocked until Accessibility permission is granted intentionally. |
| Notch layout | BLOCKED | Built-in MacBook Pro display is present, but live notch/menu-bar spacing was not validated because `SystemUIServer` inspection timed out. |
| External displays | BLOCKED | No external display was detected in this run. |
| Sleep/wake and Spaces | BLOCKED | Not performed; requires physical sleep/wake and Spaces switching. |
| Appearance variants | BLOCKED | Current installed-app UI was inspected in the active appearance; automated UI tests cover launch surfaces, but manual light/dark/high-contrast menu bar variants were not changed. |
| Launch at Login | BLOCKED | UI showed Launch at Login off and SMAppService status `Not Found`; not toggled because it changes OS Login Items state. |
| Pro permission | PASS / BLOCKED | Privacy, Search, and Second Bar pages showed no automatic prompt, `Not Requested` Accessibility status, explicit request/open-settings buttons, and disabled dependent controls. During clean-launch recovery, the app disabled Pro Mode/Accessibility Discovery because permission was missing, preserving Basic Mode. Grant/revoke behavior was not performed. |
| Safe Mode | PASS / BLOCKED | Installed app launched into Safe Mode from a previous local `running.marker`; Diagnostics export logged `Safe Mode active: Previous crash marker`, `Visibility state -> revealAll`, skipped Pro scans, disabled smart triggers, hid optional spacers/groups, and reported Health OK. The stale local marker was removed deliberately for clean-launch follow-up; the next launch reported Health OK with no previous crash marker. Option-launch and one-shot flag remain blocked by lack of modifier-key launch control through Computer Use. |
| Private Access | BLOCKED | Not exercised; requires intentional unlock/timeout and possibly biometric/password state. |
| Shortcuts/App Intents | PASS / BLOCKED | Automation page shows Preview/Privacy Safe state, Apple Events not used, App Intents enabled, Profile/Labs access off, and gated actions. Real Shortcuts app execution was not performed. |
| URL automation | PASS / PARTIAL | With automation paused, `menubardeclutter://collapse` was rejected and Diagnostics logged `Automation URL rejected: automation paused` without changing visibility. After resuming local app automation, `collapse`, `reveal-all`, and `expand` URLs were accepted and changed internal visibility state; automation was paused again afterward. The focused auto-rehide follow-up confirmed URL-driven expand can now return to collapsed state after the configured delay. |
| Labs | PASS / BLOCKED | Advanced page shows Privacy Safe/Diagnostics/Labs/Experimental badges, automation paused, icon moving off, and dependent controls disabled. No Labs mutation was applied. |
| Experimental Icon Moving | PASS / BLOCKED | Icon moving is disabled, confirmation remains required, dependent controls are disabled, and copy states explicit user action is required. Real simulated Command-drag was not performed. |
| Import/Export Preview | PASS | Installed app shows Preview and Privacy Safe badges, local JSON export copy, dry-run-first import copy, full `Export` and `Choose File` button labels, and no apply path. Exported `/Users/thesmartaz/Documents/MenuBarDeclutter-settings-qa-20260629.json`; JSON is valid, `redactionMode` is `privacySafe`, `includeAXSnapshots` is false, volatile fields are listed in `omittedSettings`, and no personal path hit was found. Choosing that package for import produced a dry-run only result: 80 modified settings, 0 added groups/hotkeys/spacers, backup count increased to 2, and no apply button appeared. |
| Diagnostics export redaction | PASS | Exported `/Users/thesmartaz/Documents/MenuBarDeclutter-diagnostics-2026-06-29_175645.txt`, `/Users/thesmartaz/Documents/MenuBarDeclutter-diagnostics-2026-06-29_175806.txt`, and `/Users/thesmartaz/Documents/MenuBarDeclutter-diagnostics-2026-06-29_180720.txt` through the installed app UI. Redaction search found only the `Excluded by design` line for screenshots, screen contents, live search text, selected item identity, personal file paths, and network data; no raw screen contents or unexpected personal paths were found. |
| Uninstall | BLOCKED | Not performed; app intentionally left installed for continued QA. |

Resolved issue details:

- Resolved row: Auto-rehide and hover reveal
- Original failing step: Clean-launch app, enable auto-rehide at 5s, resume local automation, close Settings, invoke `menubardeclutter://collapse`, invoke `menubardeclutter://expand`, wait 7s, reopen Settings to Diagnostics.
- Original expected result: Auto-rehide returns visibility to collapsed state after URL-driven reveal/expand when auto-rehide is enabled.
- Original actual result: Diagnostics still reported `Visibility expanded`; `MenuBarDeclutter-diagnostics-2026-06-29_180720.txt` logged `Auto-rehide scheduled in 5.0s` after the accepted `expand` URL, with no timer-expired collapse before Settings reopened after the wait.
- Fix: `RehideController` now drives countdown polling with a cancellable main-actor task, avoiding the installed-app run-loop timer stall seen while Settings was closed.
- Follow-up result: After rebuilding, installing, and verifying the dry-run artifact, the same URL-driven expand path returned `isCollapsed = 1`; Computer Use Diagnostics showed `Visibility collapsed`, `Accessibility Not Requested`, and `Automation Ready`.
- Remaining blocked scope: `SystemUIServer` Computer Use inspection timed out, so direct status item clicks and hover-only pointer testing remain blocked. URL-driven visibility changes were used as the closest controllable path. A prior Settings-open attempt was invalid because Settings can intentionally postpone rehide.
- Original diagnostics export path: `/Users/thesmartaz/Documents/MenuBarDeclutter-diagnostics-2026-06-29_180720.txt`
- Screenshot attached: no, reason: Computer Use accessibility trees captured the inspected UI state; no screen-content screenshot was needed for the result artifact

Attach diagnostics exports only when intentionally chosen. Avoid screenshots unless screen contents are necessary and approved by the tester.
