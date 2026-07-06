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

Pressing only Enable Pro Mode must not trigger a permission prompt. If macOS Accessibility is already granted, refreshing permission status may turn private discovery defaults on.

## Permission-Free Recovery

Safe Mode, diagnostics, reset layout, and uninstall do not require Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.
