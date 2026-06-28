# macOS 26 Notes

MenuBarDeclutter targets macOS 26.0+ only.

## Required Test Areas

- Transparent menu bar enabled and disabled.
- Menu bar background enabled and disabled.
- Liquid Glass appearance.
- Reduce Transparency.
- Increase Contrast.
- Control Center and menu bar customization because macOS 26 adds more menu bar controls.
- Notch displays.
- External displays.
- Apple Silicon primary hardware.

## Architecture Notes

- No compatibility branches are needed for macOS 13, 14, or 15.
- Intel support should be documented separately before release.
- Phase 0 uses public AppKit `NSStatusItem` behavior only.
