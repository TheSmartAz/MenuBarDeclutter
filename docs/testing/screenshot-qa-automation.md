# Screenshot QA Automation

This runbook captures repeatable screenshots of MenuBarDeclutter UI surfaces without XCTest UI automation. It launches the app with the existing `--ui-testing` launch switches, waits for the requested Settings page or floating panel, finds the app-owned window through public CoreGraphics window metadata, and captures it with the system `screencapture` tool.

Run screenshot QA for UI, layout, visual design, panel, Settings, onboarding,
and status-menu changes, or for release-candidate visual evidence. It is not
required for non-visual patch-lane changes; see `docs/testing/qa-process.md`.

## Prerequisites

- macOS 26 with Xcode command line tools available.
- A built `MenuBarDeclutter.app`, or permission to let the script build the Debug app.
- A local interactive desktop session. Headless SSH sessions cannot capture on-screen windows.
- Screen Recording permission may be requested for the terminal or Codex runner that executes `screencapture`. This is a QA-runner permission only; do not grant Screen Recording to MenuBarDeclutter for Basic Mode QA.
- Close private windows or use a clean desktop before running screenshot capture. The script captures only the selected app window, but window shadows and transparent regions can reveal surrounding desktop pixels.

The script does not use network access, private APIs, Accessibility automation, Apple Events UI scripting, Input Monitoring, or XCTest UI automation.

## Exact Command

For the full repeatable capture pass:

```sh
scripts/qa_capture_ui_screenshots.sh --build
```

For a quicker pass of the focused Settings sidebar pages plus floating panels:

```sh
scripts/qa_capture_ui_screenshots.sh --build --focused-only
```

To capture an existing installed or exported app:

```sh
APP_PATH=/Applications/MenuBarDeclutter.app scripts/qa_capture_ui_screenshots.sh
```

## Captured Surfaces

The full pass captures these Settings launch-switch surfaces:

- General
- Hide & Reveal
- Arrange
- Find & Rescue
- Workspaces
- Privacy
- Recovery
- Advanced
- Diagnostics
- Behavior
- Layout
- Menu Bar Items
- Search Settings
- Second Bar Settings
- Groups
- Hotkeys
- Profiles
- Automation
- Private Access
- Import / Export

It also attempts these floating panels when their launch switches are available:

- Floating Find Icon
- Floating Second Bar
- Floating Group Panel

Focused Settings pages are required. Floating panels are best-effort by default because preview gates can change; pass `--strict-optional` if a missing panel should fail the run.

## Outputs

By default, outputs are written to:

```text
docs/testing/screenshot-qa/<UTC timestamp>/
```

Each run contains:

- `screenshots/*.png` - normalized per-surface screenshots.
- `logs/*.log` - app stdout/stderr per surface.
- `logs/*-window.log` - window lookup diagnostics when a surface cannot be found.
- `manifest.tsv` - status, window ID, window title, window bounds, screenshot path, and launch args.
- `README.md` - run summary with the exact command and known limitations.

Use `--output-dir PATH` or `OUTPUT_DIR=PATH` to choose a different artifact location.

## Known Limitations

- XCTest screenshot attachment export still works after successful UI tests via `scripts/export_visual_smoke_screenshots.sh`, but XCTest automation may time out while enabling automation mode in macOS automation sessions. This script avoids that path by launching the app directly.
- `screencapture` depends on an active graphical session and may fail until the runner app has Screen Recording permission.
- The script terminates existing `MenuBarDeclutter` processes before capture so it does not select an older app window. Use `--keep-running-app` only when you know there is no conflicting window.
- Screenshots are visual QA artifacts. Review them before sharing outside the project because they can include window shadows or transparent edge pixels from the surrounding desktop.
