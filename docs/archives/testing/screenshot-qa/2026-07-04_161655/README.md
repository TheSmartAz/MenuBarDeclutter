# MenuBarDeclutter Screenshot QA

Generated: 2026-07-04T16:18:54Z

Command:

```sh
scripts/qa_capture_ui_screenshots.sh --build --focused-only
```

App bundle: `/Users/thesmartaz/XCode-Project/MacOS-Project/MenuBar-Manager/build/DerivedData/screenshot-qa/Build/Products/Debug/MenuBarDeclutter.app`
Scheme: `MenuBarDeclutter`
Destination: `platform=macOS`
Configuration: `Debug`
Appearance: `light`

Results:

- Captured: 12
- Skipped: 1
- Failed: 0

Artifacts:

- Screenshots: `screenshots/*.png`
- Per-surface app logs: `logs/*.log`
- Window finder logs: `logs/*-window.log`
- Manifest: `manifest.tsv`

Notes:

- The app is launched with `--ui-testing` so screenshots use isolated defaults and temporary app-support data.
- This runner uses public CoreGraphics window metadata plus the system `screencapture` tool. It does not use private APIs, Accessibility automation, network access, or XCTest UI automation.
- macOS may require Screen Recording permission for the terminal or Codex runner that executes `screencapture`; do not grant Screen Recording to MenuBarDeclutter for Basic Mode QA.
- Status menu visual capture is not automated by this harness; keep using source-covered StatusBarMenuBuilder tests plus manual QA for status menu behavior.
- XCTest attachment export remains useful after successful UI tests, but XCTest automation can time out while enabling automation mode on macOS automation sessions.
