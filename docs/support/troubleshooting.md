# Troubleshooting

## Install or update the app

Use the app from `/Applications/MenuBarDeclutter.app` for Launch at Login and installed-app validation. Local Xcode builds can report different Login Items status.

For local release testing from the repository:

```sh
scripts/build_release.sh --dry-run --install --verify-installed
```

## Basic control is missing

Open MenuBarDeclutter again from Applications. If the status item still does not appear, hold Option while launching to enter Safe Mode, then use Settings or the status menu to reset layout.

If the app opens but the menu bar layout still looks wrong:

1. Open the status menu.
2. Choose Settings.
3. Go to General.
4. Use Reset App Layout.
5. Collapse and expand once to verify the control remains reachable.

## Hidden items do not move

Use Command-drag to position the MenuBarDeclutter control and separators. Basic Mode uses public macOS status item behavior and does not use private menu bar APIs.

If a crowded menu bar still pushes items offscreen, use the Layout and Second Bar guidance in Settings. Second Bar is a metadata/icon browser when Pro gates are satisfied; it does not capture menu bar pixels.

## Pro features are unavailable

Check three separate gates:

- Pro Mode enabled.
- Accessibility Discovery enabled.
- macOS Accessibility permission granted from the explicit permission button.

Basic Mode should continue to work even when all Pro gates are off.

## Import or export looks limited

Import/Export is Preview in `v0.1.1`.

- Export writes a real local JSON settings package.
- Export intentionally omits volatile/private local state.
- Import is dry-run only and creates a backup before any future apply path.
- There is no import apply/commit button in this release.

## Release artifact warnings

Dry-run artifacts are not notarized. `spctl` and `stapler` warnings are expected until a Developer ID notarization run succeeds.

## Export diagnostics

1. Open the status menu.
2. Choose Show Diagnostics.
3. Pick TXT or JSON.
4. Use Export Diagnostics.

Default diagnostics exports are local and exclude screenshots, screen contents, live search text, selected item identity, protected group names, protected hotkey targets, active unlock sessions, and import/export paths unless explicitly chosen.

## Reporting Bugs

Export diagnostics from Settings. Include the app version, macOS version, hardware/display setup, the feature gate state, and the exact steps. Do not attach screenshots unless you intentionally choose to share screen contents.
