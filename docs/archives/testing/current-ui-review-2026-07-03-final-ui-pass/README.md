# MenuBarDeclutter Screenshot QA

Generated: 2026-07-04T01:48:16Z

Command:

```sh
scripts/qa_capture_ui_screenshots.sh --build 
```

App bundle: `/Users/thesmartaz/XCode-Project/MacOS-Project/MenuBar-Manager/build/DerivedData/screenshot-qa/Build/Products/Debug/MenuBarDeclutter.app`
Scheme: `MenuBarDeclutter`
Destination: `platform=macOS`
Configuration: `Debug`

Results:

- Captured: 23
- Skipped: 0
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
- XCTest attachment export remains useful after successful UI tests, but XCTest automation can time out while enabling automation mode on macOS automation sessions.
