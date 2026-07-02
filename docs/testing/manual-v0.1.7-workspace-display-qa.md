# Manual QA - v0.1.7 Workspace Display

Current v0.1.7 release scope: single-screen UI QA on the built-in display. External multi-display QA is deferred to a future hardware follow-up and is not a current release blocker.

- Enable Workspaces Preview, Function Bar Preview, Info Strip Preview, and Info Strip auto-show.
- Enable Info Strip for the active Workspace.
- Show Function Bar.
- Wait past the Workspace idle delay.
- Confirm Info Strip appears and Function Bar hides.
- Hover Info Strip with hover-to-Function-Bar enabled and confirm Function Bar appears.
- Disable hover-to-Function-Bar globally and confirm hover no longer switches.
- Change the Workspace hover behavior to keep Info Strip and confirm hover no longer switches.
- Switch Workspaces and confirm Function Bar/Info Strip state reflects the active Workspace configuration.

## Run Record - 2026-07-02

- PASS: Enabled Workspaces Preview, Function Bar Preview, Set Builder Preview, and Info Strip Preview on the active Default workspace in the isolated UI-testing sandbox.
- PASS: Opened Info Strip Preview on the built-in Color LCD display and observed local tile rendering without any system permission prompt.
- PASS: Waited past the configured 8 second rotation interval and observed Info Strip tile rotation.
- PARTIAL: Function Bar hover transition was observed through the accessibility window state during the local pass, but the disabling/pinning variants were not manually repeated.
- DEFERRED: External multi-display behavior was not part of the current v0.1.7 release gate because the current scope is single-screen UI QA.
