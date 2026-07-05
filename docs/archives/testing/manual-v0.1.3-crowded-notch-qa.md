# v0.1.3 Crowded and Notch Manual QA

Status: partial physical/session QA. Built-in-display installed-app and read-only hardware passes were executed; crowded/notch/external display scenarios still need hands-on coverage with suitable hardware/session setup.

Use this checklist for the v0.1.3 crowded reveal and notch recovery claim. Record hardware, display layout, macOS build, menu bar auto-hide setting, active app, and whether Pro Discovery was enabled.

## Scope

- Crowded reveal fallback order: inline reveal, Second Bar, Full Menu Bar Mode, suggestion/recovery.
- Notch and constrained menu bar behavior without screenshots, ScreenCaptureKit, Screen Recording, Apple Events, Input Monitoring, private APIs, network access, or telemetry.
- Basic Mode fallback when Pro Discovery is off or Accessibility permission is missing.

## Matrix

| Scenario | Steps | Expected Result | Status | Evidence |
| --- | --- | --- | --- | --- |
| Enough room | Use a lightly populated menu bar, then Expand and Reveal All from the status menu. | Reveal stays inline and does not open Second Bar or Full Menu Bar Mode. | PARTIAL PASS | 2026-07-01 installed app on built-in display: Arrange Expand/Collapse/Reveal All buttons were clickable without permission prompts. Reveal All opened Second Bar with `No Hidden Items`, count `0`, `Privacy Safe`, and `Ready`; no actual hidden item geometry was available to validate inline-vs-fallback behavior. 2026-07-02 `CrowdedRevealDecisionEngineTests/enoughCapacityRevealsInline` and `CrowdedRevealRescueServiceTests/nonCrowdedProceedsInline` passed. |
| Crowded with Pro Discovery | Enable Pro Discovery, create a crowded menu bar with many third-party status items, then Reveal All. | Second Bar opens with the explanation that inline reveal may not fit. | PARTIAL PASS | 2026-07-01: `MenuBarFixtureApp` launched disposable status items, but MenuBarDeclutter still reported `Discovered 0` and `New Items 0` after Pro rescan. 2026-07-02: the installed scan blocker is resolved and fixture items are discoverable. `CrowdedRevealDecisionEngineTests/crowdedMenuPrefersSecondBarWhenAvailable` and `CrowdedRevealRescueServiceTests/crowdedOpensSecondBarWhenEnabled` passed, but hands-on constrained menu-bar reveal remains pending. |
| Crowded without Second Bar | Disable Second Bar while Full Menu Bar Mode is enabled, then Reveal All. | Full Menu Bar Mode temporarily reveals items. | PARTIAL PASS | 2026-07-02 `CrowdedRevealDecisionEngineTests/crowdedMenuFallsBackToFullMenuBarMode` and `CrowdedRevealRescueServiceTests/crowdedFallsBackToFullMenuBarMode` passed. Hands-on installed fallback remains pending. |
| Crowded with ask-before-switching | Enable Ask Before Switching, then Reveal All on a crowded layout. | Layout/Arrange suggestion opens instead of automatically switching surfaces. | PARTIAL PASS | 2026-07-02 `CrowdedRevealDecisionEngineTests/askBeforeSwitchingShowsSuggestionInsteadOfOpeningFallback` passed. Hands-on installed setting toggle and reveal remain pending. |
| Basic fallback | Turn Pro Mode off and use a crowded layout. | Basic Mode stays usable; rescue avoids Pro-only Second Bar and uses Full Menu Bar Mode or suggestions when available. | PARTIAL PASS | 2026-07-02 `CrowdedRevealDecisionEngineTests/proDiscoveryOffSkipsSecondBarAndUsesBasicFallback` and `CrowdedRevealRescueServiceTests/proDiscoveryOffFallsBackToFullMenuBarModeInsteadOfSecondBar` passed. Hands-on crowded Basic Mode layout remains pending. |
| Safe Mode | Launch in Safe Mode, then Expand and Reveal All. | Automation surfaces do not open; inline recovery remains available. | PARTIAL PASS | 2026-07-02 `CrowdedRevealDecisionEngineTests/safeModeSuppressesAutomationAndRevealsInline`, `CrowdedRevealRescueServiceTests/safeModeProceedsInlineWithoutOpeningFallbacks`, and command-router Safe Mode tests passed. Hands-on installed Safe Mode crowded reveal remains pending. |
| Notch MacBook | On a built-in notch display, hide several items and Reveal All. | Notch pressure chooses Second Bar or a clear fallback before items disappear behind constrained space. | PARTIAL | 2026-07-01 hardware check recorded MacBook Pro `Mac16,7` with one built-in Liquid Retina XDR display online. 2026-07-02 read-only re-check confirmed the same model with a single built-in Liquid Retina XDR display, 3456 x 2234 Retina, main display yes, mirror off, online yes, and dark mode active. Fixture discovery is now available, but notch-pressure fallback still needs hands-on hidden-item layout validation. |
| External monitor | Move focus between built-in and external displays, switch the main display, then reveal hidden items. | Rescue decisions do not rely on stale display estimates; panels remain on a current visible display. | NOT AVAILABLE | 2026-07-01 hardware check found no external display connected. 2026-07-02 read-only re-check again found only the built-in display online. |
| Long app menus | Use an app with long menu titles or many app menus, then reveal hidden items. | Inline reveal either works or falls back with clear explanation; no private app-menu inspection is used. | PARTIAL PASS | 2026-07-02 `CrowdedRevealDecisionEngineTests/highActiveAppMenuPressureCanTriggerRescue` passed using modeled aggregate menu pressure. Hands-on validation in an app with long visible menus remains pending. |
| Menu bar auto-hide | Enable macOS menu bar auto-hide, then open Find Icon, Second Bar, Expand, and Reveal All. | Panels remain reachable and explanations remain accurate. | PENDING | |
| Light/dark and contrast | Repeat one crowded and one notch scenario in light mode, dark mode, and increased contrast if available. | Text remains readable and controls do not overlap. | PARTIAL | 2026-07-02 read-only defaults check showed dark mode active. Light mode and increased contrast passes remain pending. |
| Sleep/wake and Spaces | Keep Second Bar open, sleep/wake, then switch Spaces and reveal items again. | Second Bar repositions or recovers; crowded rescue remains usable. | PENDING | |

## Evidence To Capture

- Hardware model and notch presence.
- Display count, resolution, scaling, and main-display assignment.
- Active app and whether its menu titles are unusually long.
- Approximate third-party status item count.
- Current rescue settings: Second Bar status-menu shortcut visible, Full Menu Bar Mode enabled, Ask Before Switching, Pro Mode, Accessibility Discovery.
- Diagnostics export with privacy-safe aggregate capacity metadata only.
