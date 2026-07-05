# Installed Alpha Release Notes Template

Version:
Build:
Date:
Commit:
Notarization status:

## What Is Included

- Permission-free Basic Mode collapse, expand, reveal all, separator reset, Settings, Diagnostics, and Safe Mode.
- Optional Pro Mode with Accessibility-only discovery after explicit opt-in.
- Find Icon and Second Bar when Pro requirements are met.
- Experimental Icon Moving in Labs, disabled by default.

## Privacy

- No ScreenCaptureKit.
- No Screen Recording.
- No Apple Events permission.
- No Input Monitoring.
- No network access.
- No telemetry.

## Installation

1. Unzip the release.
2. Move `MenuBarDeclutter.app` to `/Applications`.
3. Launch it from `/Applications`.
4. Validate Launch at Login only from the installed app.

## Known Limitations

Link to `docs/release/v0.1-known-limitations.md`.

## Verification

Record:

- `scripts/verify_release_artifact.sh build/Export/MenuBarDeclutter.app`
- `scripts/verify_installed_app.sh /Applications/MenuBarDeclutter.app`
- Notarization or dry-run result
- Installed-app QA run
