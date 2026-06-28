# Alpha RC QA Matrix

Use this matrix for real macOS validation. Automated tests do not replace these checks.

## Basic Mode

| Scenario | Expected Result |
| --- | --- |
| First launch | App appears as LSUIElement menu bar utility; no Dock icon; no permission prompt |
| Onboarding | Clear Basic/Pro privacy boundary; completion persists |
| Command-drag separator placement | User can place separator manually; app does not simulate this in Basic Mode |
| Collapse/expand | Separator length updates and icons hide/reveal |
| Reveal all | Both hidden zones are revealed |
| Always-hidden section | Secondary separator hides deeper items when enabled |
| Option-click reveal all | Option-click cycles reveal-all when enabled |
| Auto-rehide | Expanded state collapses after configured delay unless postponed |
| Hover reveal | Hovering menu bar reveals items without Input Monitoring prompt |
| Global hotkey | Optional hotkey toggles visibility |
| Reset separator length | Clears custom collapsed override and recomputes length |
| Reset app layout | Restores separator layout without deleting profiles |
| Reset all settings | Restores defaults; icon moving disabled; automation unpaused |

## macOS 26 Visual States

| Scenario | Expected Result |
| --- | --- |
| Transparent menu bar | Control and separators remain readable |
| Tinted Liquid Glass setting if available | Settings remain readable; no custom glass conflict |
| Reduce Transparency | Settings and menu bar controls remain legible |
| Increase Contrast | Labels and controls remain legible |
| Light mode | Settings and overlays readable |
| Dark mode | Settings and overlays readable |
| Wallpaper variations | Separator/control remain usable |
| Menu bar background visibility | Collapsed/expanded states remain understandable |

## Display States

| Scenario | Expected Result |
| --- | --- |
| Built-in display | Separator length and bands are correct |
| Notch display | Second Bar placement avoids notch where modeled |
| External display | Geometry reapplies after connection |
| External display as primary | Placement and separator lengths use active screens |
| External display disconnected while collapsed | Recovery expands/reapplies safely |
| Display scaling changes | Recovery recomputes geometry |
| Sleep/wake | Auto-rehide cancels and health reruns |
| Full-screen app | No crash; app recovers when menu bar returns |
| Space switch | Recovery path logs and preserves Basic Mode |

## Pro Mode

| Scenario | Expected Result |
| --- | --- |
| Pro Mode disabled | Pro surfaces unavailable; Basic Mode works |
| Enable Pro Mode | Accessibility Discovery can be enabled |
| Request Accessibility permission | Prompt only appears after explicit button |
| Grant permission | Manual scan can populate items |
| Revoke permission | Pro surfaces degrade gracefully |
| Relaunch after revoke | Permission state refreshes without crash |
| Manual scan refresh | Updates status and diagnostics |
| Diagnostics table | Shows AX snapshots without screenshots |
| AX failure degradation | Logs failures; app remains usable |

## Find Icon

| Scenario | Expected Result |
| --- | --- |
| Unavailable state | Explains Pro/Accessibility requirements |
| Search by app name | Ranks expected app |
| Search by bundle id | Finds matching bundle id |
| Keyboard navigation | Up/down/Return/Escape work |
| Activate visible item | Highlights approximate frame; no click automation |
| Activate hidden item | Reveals hidden zone then highlights |
| Activate always-hidden item | Enters reveal-all then highlights |
| Highlight overlay | Transparent, mouse-ignoring, auto-dismisses |
| Escape dismiss | Panel closes |
| Hotkey | Optional hotkey opens panel |

## Second Bar

| Scenario | Expected Result |
| --- | --- |
| Unavailable state | Explains Pro/Accessibility requirements |
| Below menu bar placement | Stays visible and clamped |
| Near mouse placement | Opens near cursor and clamped |
| Last position placement | Restores last safe position |
| Search | Filters hidden/always-hidden items |
| Keyboard navigation | Selection and Escape work |
| Auto-close | Closes after selection when enabled |
| Outside-click close | Closes when configured |
| External display | Chooses/clamps to correct display |
| Notch behavior | Avoids notch where modeled |

## Icon Moving

| Scenario | Expected Result |
| --- | --- |
| Disabled by default | No move runs until enabled |
| First-use warning | Experimental warning appears before enablement/action |
| Move third-party app to Hidden | Attempts Command-drag, verifies or fails safely |
| Move third-party app to Visible | Attempts Command-drag, verifies or fails safely |
| Move third-party app to Always Hidden | Attempts Command-drag, verifies or fails safely |
| Move Left | Attempts relative move and verifies |
| Move Right | Attempts relative move and verifies |
| Reject own app items | MenuBarDeclutter item cannot be moved |
| Reject system items by default | Likely system items blocked unless enabled |
| Fail safely on unsupported items | Restores visibility and logs error |
| Permission revoke during move | Move fails safely; Basic Mode remains usable |
| Display change during move | Move fails or recovers without stuck state |

## Profiles And Triggers

| Scenario | Expected Result |
| --- | --- |
| Create profile | Local JSON profile appears |
| Duplicate profile | Copy appears with unique identity |
| Delete profile | Profile removed locally |
| Export/import | JSON round trips |
| Dry run | Shows Basic changes and Pro move requirements |
| Apply Basic-only profile | Applies conservative settings |
| Confirm Pro moves are report-only | Profile apply does not run bulk moves |
| Display trigger | Applies profile when enabled and unpaused |
| App launched trigger | Applies profile when enabled and unpaused |
| Time trigger | Applies profile when enabled and unpaused |
| Pause all automation | Smart triggers stop firing until resumed |

## Health And Safe Mode

| Scenario | Expected Result |
| --- | --- |
| Force quit while collapsed | Running marker remains |
| Relaunch with crash marker | Safe Mode starts expanded/reveal-all |
| Safe Mode via Option key | Optional services suppressed |
| Safe Mode next launch flag | One-shot flag consumed on next launch |
| Fix Automatically | Targeted health repairs run |
| Disable Pro Mode | Pro settings disable; Basic Mode works |
| Export Health Report | Local text report excludes screen contents |

## Release

| Scenario | Expected Result |
| --- | --- |
| Archive | Release archive succeeds |
| Codesign verify | `codesign --verify --strict` succeeds |
| Notarization template | Template is filled and tested or skipped with reason |
| Install from exported artifact | Installed app launches correctly |
| Launch at Login from installed app | SMAppService status matches setting |
| Uninstall cleanup notes | User-facing cleanup documented |
