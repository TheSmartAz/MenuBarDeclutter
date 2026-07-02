# Permissions

## Basic Mode

Basic Mode does not request Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.

Basic Mode should still work when Accessibility is denied, revoked, or never requested.

## Pro Mode

Pro Mode can use Accessibility metadata only when all of these are true:

- Pro Mode is enabled.
- Accessibility Discovery is enabled.
- The user explicitly presses a Request Permission button.
- macOS Accessibility permission is granted.
- The user refreshes or rescans the local menu bar metadata after permission changes.

If permission is denied or revoked, Pro surfaces degrade and Basic Mode remains usable.

MenuBarDeclutter does not use Screen Recording, ScreenCaptureKit, Apple Events permission, Apple Events scripting/control of other apps, Input Monitoring, telemetry, analytics, crash upload, cloud sync, or remote config. The local `menubardeclutter://` URL handler only receives commands addressed to this app.

## Requesting Accessibility

The app must not show an Accessibility prompt automatically. Only use the explicit permission request button from a Pro surface when you want to test Pro metadata features.

Granting Accessibility is optional. Revoking it should disable or degrade Pro metadata features without breaking Basic Mode.

Expected setup order for Pro metadata testing:

1. Enable Pro Mode.
2. Enable Accessibility Discovery.
3. Press Request Permission from Privacy, Find Icon, or Second Bar.
4. Grant MenuBarDeclutter in macOS Privacy & Security -> Accessibility.
5. Return to MenuBarDeclutter and press Rescan or Refresh.
6. Confirm Find Icon and Second Bar move from unavailable states to usable Pro metadata states.

Pressing only Enable Pro Mode must not enable Accessibility Discovery and must not trigger a permission prompt.

## Permission-Free Recovery

Safe Mode, diagnostics, reset layout, and uninstall do not require Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.
