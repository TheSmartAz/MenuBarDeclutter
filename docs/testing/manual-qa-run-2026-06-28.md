# Manual QA Run - 2026-06-28

This run covered the manual-adjacent checks that can be exercised reliably from XCTest and recorded the hands-on scenarios that still require direct macOS interaction.

## Automated Workflow Coverage

- Added isolated UI-test launch mode so app launches use a temporary `UserDefaults` suite and temporary Application Support root.
- Verified Diagnostics opens directly and exposes recovery controls: Refresh, Fix Automatically, Reset Basic Mode, Disable Pro Mode, Export Health Report, and Safe Mode Next Launch.
- Verified Privacy opens directly and Basic Mode lists Accessibility, Screen Recording, Apple Events, and Input Monitoring as Not Requested, with Network Access as Not Used.
- Verified Find Icon default unavailable state without Pro Mode shows Pro Mode Required, Enable Pro Mode, and Open Privacy Settings.
- Verified Second Bar settings show the default requirements state with Pro Mode disabled and a path back to Privacy settings.
- Verified launch screenshot coverage still runs in Light and Dark appearances with `--ui-testing` isolation.

## Commands Run

```sh
xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS' -only-testing:MenuBar-ManagerUITests/MenuBar_ManagerUITests
```

Result: `** TEST SUCCEEDED **` on 2026-06-28. Executed 5 UI workflow tests with 0 failures.

```sh
xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'
```

Result: `** TEST SUCCEEDED **` on 2026-06-28. The combined run passed unit tests, 5 UI workflow tests, and 2 launch screenshot tests. Xcode reported the recurring duplicate matching macOS destination warning.

## Hands-On Checks Still Required

- Command-drag separator positioning with real menu bar items.
- Collapse/expand behavior with third-party status items across the visible, hidden, and always-hidden zones.
- External display attach/detach, resolution changes, notch placement, and transparent menu bar appearance.
- Launch at Login verification through System Settings and login/logout.
- Real Accessibility prompt, denial, grant, and revocation flows for opt-in Pro Mode.
- Real icon moving against third-party menu bar items.
- Network monitor confirmation during an interactive Basic Mode smoke test.
