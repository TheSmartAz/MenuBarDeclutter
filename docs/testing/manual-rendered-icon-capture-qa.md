# Manual QA: Accurate Icons Rendered Capture

## Preconditions

- Optional Pro and Accessibility Discovery are enabled if testing discovered menu bar items.
- Screen Recording is not granted at the start of the first pass.
- A mix of template, colored, text-like, and dynamic menu bar items is visible.

## Automated Evidence

- `removeAllClearsRenderedAndStaleIconLookups`: PASS in the app-hosted test bundle; verifies rendered cache lookup, stale rendered fallback after menu bar height changes, and cache clear removing both live and stale lookups.

## Checks

| Area | Steps | Expected |
| --- | --- | --- |
| Basic boundary | Launch fresh, leave Accurate Icons off, use Expand/Collapse/Reveal All. | No Screen Recording prompt appears. Basic Mode remains usable. |
| Permission request | Open Privacy -> Accurate Icons, enable Rendered Icon Capture, press Request Permission. | macOS Screen Recording flow is user-initiated. If denied, UI shows Needs Permission and app icons remain as fallback. |
| Visible capture | Grant Screen Recording, rescan menu bar items, open Find Icon and Second Bar. | Visible menu bar items use thumbnails matching the rendered menu bar glyph shape/style where frames are available. |
| Reveal sweep | Enable Reveal Sweep, hide an item with MenuBarDeclutter, open Second Bar or Find Icon. | The app temporarily reveals items, captures thumbnails, restores prior visibility, and does not get stuck in reveal-all. |
| Second Bar warm-up | Complete Pro Second Bar Setup, then click Warm Up Icons. | The app performs a user-initiated one-time reveal/capture/restore pass without requiring Reveal Sweep to stay enabled. |
| Cache clear | Privacy -> Accurate Icons -> Clear Cache. | Rendered thumbnails disappear from cache and app icons are used until the next capture. |
| Diagnostics | Export diagnostics after captures. | Export includes Accurate Icons boolean settings but no screenshots, screen contents, or thumbnail image files. |
| Revocation | Revoke Screen Recording in System Settings, refresh/open surfaces. | App degrades to stale thumbnails or app icons; Basic Mode and Pro metadata remain usable according to their permissions. |

## Out Of Scope

- Private/offscreen menu bar item capture.
- Capturing items macOS does not currently render on-screen.
- Exporting raw screenshots or thumbnails in diagnostics.
