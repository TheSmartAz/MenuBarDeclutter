# Manual v0.1.1 System QA

Use an installed `/Applications/MenuBarDeclutter.app` build unless a row explicitly says local build. Prefer the dry-run release artifact for local QA and a notarized Developer ID build for release-candidate QA.

Do not grant permissions, change Login Items, restart system services, or capture screenshots unless that step explicitly calls for it and the tester has agreed. Diagnostics exports are preferred over screenshots because they are designed to avoid screen contents.

## Preconditions

- Install a fresh build with `scripts/build_release.sh --dry-run --install --verify-installed`, or install the notarized release candidate.
- Record the build number from Settings -> General.
- Record macOS version, hardware model, display layout, notch presence, and whether the menu bar is auto-hidden.
- Start in Basic Mode with Pro Mode off unless the row says otherwise.
- Keep `docs/testing/manual-v0.1.1-results-template.md` open and fill a result for every gate.
- If a failure happens, export diagnostics from Settings -> Diagnostics before changing more state.

| Area | Steps | Expected Result | Capture On Failure |
| --- | --- | --- | --- |
| First-run onboarding | Clean preferences, launch app, step through all seven pages, click Open Menu Bar Settings on the native cleanup page, return to onboarding, complete it, relaunch | Onboarding includes the Apple Menu Bar settings cleanup step, opens System Settings best-effort, persists completion, and triggers no permission prompt | Page title, opened System Settings destination, whether completion persisted, diagnostics |
| Basic live menu bar | Command-drag control and separators into a normal working position, collapse, expand, reveal all, trigger Reset App Layout, collapse and expand again | Control remains reachable; primary separator remains available; reset does not require Pro, Accessibility, Screen Recording, network, or Login Items | Exact display setup, current menu bar auto-hide setting, diagnostics export |
| Auto-rehide and hover reveal | Enable auto-rehide, collapse, reveal, wait for countdown; enable hover reveal if desired, hover through the menu bar band, then disable both | Auto-rehide returns to collapsed state only when configured; hover reveal does not require Pro permission and does not leave app stuck expanded | Timer settings, hover/reveal timeline, diagnostics |
| Crowded menu bar | Run with many third-party status items, collapse, expand, reveal all, open Layout page, check capacity warnings and Second Bar fallback copy | Hidden items are managed through public status item spacing; expanded mode restores access where macOS allows; fallback messaging is honest when items are offscreen | List of active menu bar apps, display width, menu bar auto-hide state, diagnostics |
| Second Bar fallback | Enable Pro Mode and Accessibility Discovery, grant Accessibility only from the explicit button if this test is in scope, open Second Bar with hidden metadata | Panel shows metadata/icons without screenshots, Screen Recording, or captured menu bar pixels; missing permission state is clear if permission is not granted | Permission state, Second Bar visible state, diagnostics |
| Notch layouts | On a notch MacBook, test hidden item search, Second Bar placement, layout suggestions, and window movement near the notch | Panels avoid the modeled notch and remain inside the visible screen frame | Hardware model, display resolution/scaling, panel placement notes, diagnostics |
| External displays | Attach display, detach display, switch main display, test mirror mode, test different menu bar heights and scaling | Geometry recomputes; Basic control remains accessible; panels remain on visible screens | Display arrangement before/after, scaling, main display, diagnostics |
| Sleep/wake and Spaces | Collapse app, sleep/wake, switch Spaces, toggle auto-hide menu bar, then reveal and reset layout | Recovery keeps Basic Mode usable; status menu remains reachable; no permission prompt appears | Timeline, macOS appearance/menu bar setting, diagnostics |
| Appearance variants | Test light mode, dark mode, menu bar auto-hide, menu bar background on/off, and high-contrast appearance if available | Status items remain visible enough to recover; Settings text and badges remain readable | Variant name, issue location, screenshot only if intentionally shared |
| Launch at Login | From installed app, enable Launch at Login, logout/login, restart, then disable and verify removal | App launches only from explicit opt-in, reports installed-app status, and can be removed cleanly | Login item state, app path, diagnostics |
| Pro permission | With Pro off, open Pro surfaces; enable Pro without requesting permission; request Accessibility from explicit button; revoke permission; restart; toggle Discovery off/on | No automatic prompt; unavailable states are clear; Basic Mode keeps working after grant, revoke, and restart | Permission state before/after, Pro/Discovery toggles, diagnostics |
| Safe Mode | Option-launch app, use one-shot Safe Mode flag if available, simulate or preserve crash marker recovery only in a safe local test, then reset | Starts expanded; optional services suppressed; reset/recovery menu remains reachable; Basic control is visible | Startup diagnostics, visible status item state, crash marker note |
| Private Access | Test Touch ID success, cancel, unavailable/fallback, failure, protected group/action, and session expiration where hardware supports it | Protected actions require successful gate; cancel/failure does not apply protected action; Basic Mode remains usable | LocalAuthentication result text, protected action, diagnostics without protected names if possible |
| Shortcuts/App Intents | Discover actions in Shortcuts, run stable actions, run group-ID actions, run blocked states with automation paused/Safe Mode/Labs off/Pro off | Safe Mode and pause gates block automation; Labs, Pro, Accessibility, and Private Access gates fail closed; blocked action reports a clear reason | Shortcut/action name, gate state, returned result, diagnostics |
| URL automation | Exercise `menubardeclutter://` routes for safe actions and blocked actions, including `group/<uuid>` and `reveal-group/<uuid>` where a disposable group exists | URL commands do not bypass Safe Mode, automation pause, Pro gates, Labs gates, Accessibility gates, or Private Access gates | URL command, gate state, returned result, diagnostics |
| Labs | Try Spacing Labs with Labs off, then Labs on if explicitly testing; do not restart system processes | No automatic global defaults mutation or system process restart; Labs labels stay visible | Settings state, command attempted, logs |
| Experimental | Try Icon Moving only with explicit confirmation and a known movable third-party item | Fails safely or verifies movement; no stable claim is shown; system items are rejected unless explicitly allowed | Before/after positions, target item, diagnostics |
| Import/Export Preview | Export a settings package, inspect JSON metadata, choose package for import dry-run, then apply only to a disposable local test package | Export uses real values plus omission metadata; import reports dry-run/backup, safe apply is explicit, conflicting dynamic hotkeys are skipped, and imported experimental enablement stays off | Package metadata, dry-run counts, apply counts, backup path, diagnostics |
| Diagnostics export redaction | Export diagnostics with default options, inspect output locally | Default export excludes screenshots, screen contents, live search text, selected item identity, protected group names, protected hotkey targets, active unlock sessions, and import/export paths unless explicitly chosen | Export filename, redaction issue if found |
| Uninstall | Quit app, remove Login Item if enabled, delete `/Applications/MenuBarDeclutter.app`, remove app support files only if intentionally resetting | App can be removed cleanly; support docs are enough to complete uninstall | Steps completed, remaining files if any |

## Failure Capture

For every failure, record:

- Build version and installed path.
- Exact test row and step.
- Expected result vs actual result.
- Whether Pro Mode, Accessibility Discovery, Accessibility permission, Labs, Private Access, Safe Mode, or automation pause was enabled.
- Display arrangement and menu bar appearance if layout-related.
- Diagnostics export path if one was intentionally generated.

Avoid attaching screenshots by default. If a screenshot is necessary, state why it is needed and confirm it does not expose private screen contents.
