# Release Checklist

Last reviewed: 2026-07-05

This checklist covers the current v0.1.10 local/internal release stance. Developer ID signing, notarization, stapling, and public distribution are out of scope until explicitly requested.

## Build And Test

- Confirm project identity and schemes:

  ```sh
  xcodebuild -list
  ```

- Run a canonical build:

  ```sh
  xcodebuild -scheme MenuBarDeclutter -destination 'platform=macOS' build CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO
  ```

- Run focused logic tests when touching pure logic:

  ```sh
  scripts/run_logic_tests.sh
  ```

- For release/risk changes, run the current preflight:

  ```sh
  scripts/qa_preflight.sh
  ```

- If direct full-scheme `xcodebuild test` fails before tests attach because of the local Xcode LaunchServices/UI-runner issue, record the exact failure and include split-lane or focused test evidence.

## Privacy

- Confirm Basic Mode does not request Accessibility, Screen Recording, Apple Events, Input Monitoring, network access, telemetry, cloud sync, or ScreenCaptureKit.
- Confirm Optional Pro Discovery checks Accessibility without prompting by default and prompts only from explicit user action.
- Confirm Accurate Icons is the only Screen Recording/ScreenCaptureKit path, is off by default, and is scoped to local visible rendered thumbnails.
- Confirm Apple Events usage strings, Input Monitoring usage strings, network entitlements, analytics SDKs, telemetry, remote config, cloud sync, crash upload, and private menu bar APIs are absent.
- Confirm diagnostics exports exclude screenshots, screen contents, rendered icon thumbnails, live search text, selected item identity, network data, and sensitive personal paths by default.
- Run:

  ```sh
  scripts/verify_privacy_boundary.sh
  ```

- For installed builds, run:

  ```sh
  APP_PATH=/Applications/MenuBarDeclutter.app scripts/verify_privacy_boundary.sh
  ```

## App Behavior

- Confirm `LSUIElement`/accessory behavior removes the Dock icon.
- Confirm status item appears and Basic menu commands work.
- Confirm Settings, Recovery, Diagnostics, Onboarding replay, and Quit work from app surfaces.
- Confirm Launch at Login registers/unregisters only after explicit user opt-in.
- Confirm Safe Mode, reset layout, reset settings, and recovery actions remain reachable when optional features fail.
- Confirm Workspaces, Function Bar, Info Strip, Set Builder, and Groups are app-owned Preview UI and do not claim to replace the macOS system menu bar.
- Confirm Experimental Icon Moving is disabled by default and cannot run from launch, wake, profiles, smart triggers, URL automation, or App Intents.

## Release Artifact

- Run the dry-run release flow:

  ```sh
  scripts/build_release.sh --dry-run
  ```

- For installed-app claims, run:

  ```sh
  scripts/build_release.sh --dry-run --install --verify-installed
  scripts/qa_installed_app_smoke.sh --app-path /Applications/MenuBarDeclutter.app
  ```

- Confirm artifact identity: `MenuBarDeclutter`, version `0.1.10`, build `11`.
- Confirm the installed bundle has the expected URL scheme and app category.
- Confirm no Developer ID/notarization success is claimed unless that work has explicitly entered scope.
- Record any local `spctl` instability separately from app launch/runtime behavior.

## Manual QA

Use:

- `docs/testing/qa-process.md`
- `docs/testing/manual-qa.md`
- `docs/testing/macos26-test-matrix.md`
- `docs/testing/manual-v0.1.10-results.md`

Hardware-only rows can be `BLOCKED` or `PARTIAL` when the local setup lacks the required hardware or permission state. Do not convert unavailable hardware checks into release claims.

## Documentation

- Update `docs/project-summary.md` for user-facing project status changes.
- Update `docs/architecture/architecture-overview.md` for service/coordinator or permission-boundary changes.
- Update `docs/privacy/privacy-boundary.md` for any permission, data, diagnostic, capture, or network-adjacent change.
- Update active feature/support docs for public wording changes.
- Move superseded phase/version docs to `docs/archives/` rather than leaving stale current claims in active docs.
