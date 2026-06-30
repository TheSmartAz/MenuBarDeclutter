# Permissions

## Basic Mode

Basic Mode does not request Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.

Basic Mode should still work when Accessibility is denied, revoked, or never requested.

## Pro Mode

Pro Mode can use Accessibility metadata only when all of these are true:

- Pro Mode is enabled.
- Accessibility Discovery is enabled.
- The user explicitly presses the permission request button.
- macOS Accessibility permission is granted.

If permission is denied or revoked, Pro surfaces degrade and Basic Mode remains usable.

MenuBarDeclutter does not use Screen Recording, ScreenCaptureKit, Apple Events, Input Monitoring, telemetry, analytics, crash upload, cloud sync, or remote config.

## Requesting Accessibility

The app must not show an Accessibility prompt automatically. Only use the explicit permission request button from a Pro surface when you want to test Pro metadata features.

Granting Accessibility is optional. Revoking it should disable or degrade Pro metadata features without breaking Basic Mode.

## Permission-Free Recovery

Safe Mode, diagnostics, reset layout, and uninstall do not require Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.
