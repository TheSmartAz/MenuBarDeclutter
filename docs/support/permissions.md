# Permissions

## Basic Mode

Basic Mode does not request Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.

Basic Mode should still work when Accessibility is denied, revoked, or never requested.

## Pro Mode

Private discovery surfaces can use Accessibility metadata only when all of these are true:

- macOS Accessibility permission is granted.
- Pro Mode and Accessibility Discovery are on. If macOS already reports Accessibility as granted, MenuBarDeclutter turns these defaults on automatically for Find Icon and Second Bar.
- The user refreshes or rescans the local menu bar metadata after permission changes.

If permission is denied or revoked, Pro surfaces degrade and Basic Mode remains usable.

Accurate Icons is a separate opt-in capability. When enabled, it can request Screen Recording and use ScreenCaptureKit to crop small rendered menu bar item thumbnails locally. It is off by default and is not part of Basic Mode.

Pro Second Bar compact/status-menu readiness requires both Pro Accessibility Discovery and Accurate Icons. If Accurate Icons is off or Screen Recording is missing, Show Second Bar reports the missing requirement instead of opening the strip or panel. Basic Mode inline hide/show remains available.

MenuBarDeclutter does not use Apple Events permission, Apple Events scripting/control of other apps, Input Monitoring, telemetry, analytics, crash upload, cloud sync, remote config, or private menu bar APIs. The local `menubardeclutter://` URL handler only receives commands addressed to this app.

Rendered icon thumbnails remain local, can be cleared from Privacy settings, and are excluded from diagnostics exports by default.

## Requesting Accessibility

The app must not show an Accessibility prompt automatically. Only use the explicit permission request button from a private-access surface when you want to test metadata features.

Granting Accessibility is optional. Revoking it should disable or degrade Pro metadata features without breaking Basic Mode.

Expected setup order for Pro metadata testing:

1. Press Request Permission from Privacy, Find Icon, or Second Bar, or open System Settings manually.
2. Grant MenuBarDeclutter in macOS Privacy & Security -> Accessibility.
3. Return to MenuBarDeclutter and press Rescan or Refresh.
4. Confirm Find Icon and Second Bar skip their old app-level enable states and move to usable metadata views.

Expected setup order for Pro Second Bar compact strip testing:

1. Enable Optional Pro.
2. Enable Accessibility Discovery.
3. Request and grant Accessibility from the explicit button.
4. Enable Accurate Icons.
5. Request and grant Screen Recording from the explicit Accurate Icons control.
6. Warm up icons, then open Second Bar.

If MenuBarDeclutter does not appear in Privacy & Security -> Screen & System Audio Recording after the request, use Add and select `/Applications/MenuBarDeclutter.app`, then quit and reopen MenuBarDeclutter before checking the setup state again.

Before running compact strip sign-off, use `scripts/qa_second_bar_permission_preflight.sh` to verify the installed app, CDHash, privacy strings, the app's last public ScreenCapture preflight result, local preference gates, and remaining manual TCC checks. Add `--open-settings` when you want the script to open the relevant Privacy & Security panes for manual review. Add `--restart-app` after changing macOS privacy settings when you want the script to quit and reopen the installed app before checking the app-observed permission state. Add `--prepare-local-gates` only for hands-on dogfood when you want the script to turn on local Optional Pro, Accessibility Discovery, Accurate Icons, Second Bar, and primary-click compact strip opt-in before restarting the app. These flags do not request or grant macOS privacy permissions.

After changing Accessibility or Screen Recording in macOS, quit and reopen MenuBarDeclutter before rerunning the script.

When the preflight passes, continue with hands-on compact strip QA, export
diagnostics JSON from Settings -> Diagnostics, then run the diagnostics-backed
manual gate audit:

```sh
SECOND_BAR_DIAGNOSTICS_JSON=/path/to/diagnostics.json \
SECOND_BAR_AUDIT_MATRIX_OUTPUT=docs/testing/pro-second-bar-direct-activation-matrix.generated.md \
DOGFOOD_SECOND_BAR_AUDIT_ONLY=1 scripts/qa_dogfood_preflight.sh
```

Review accepted generated matrix rows, copy them into
`docs/testing/pro-second-bar-direct-activation-matrix.md`, then run
`scripts/qa_second_bar_signoff_audit.sh`.

For local dogfood, prefer a stable Apple Development-signed install when that identity is available:

```sh
scripts/build_release.sh --dry-run --local-development-signing --install --verify-installed
```

The default dry-run remains ad-hoc/no-account for CI and machines without signing identities:

```sh
scripts/build_release.sh --dry-run --install --verify-installed
```

Ad-hoc installs can change CDHash on every rebuild, which may require granting Accessibility or Screen Recording again for the new local binary. `--local-development-signing` is not Developer ID signing, notarization, or public distribution; it only uses the project Apple Development signing identity for local dogfood.

Pressing only Enable Pro Mode must not trigger a permission prompt. If macOS Accessibility is already granted, refreshing permission status may turn private discovery defaults on.

## Permission-Free Recovery

Safe Mode, diagnostics, reset layout, and uninstall do not require Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.
