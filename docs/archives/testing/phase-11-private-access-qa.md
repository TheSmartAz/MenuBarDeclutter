# Phase 11 Private Access QA

## Preconditions

- App installed or running from Xcode.
- Private Access disabled at start.

## Steps

1. Open Settings > Private Access.
2. Turn on Enable Private Access and complete the Touch ID or device password prompt.
3. Confirm Private Access remains off if authentication is canceled, fails, or is unavailable.
4. Confirm successful authentication turns Private Access on and marks the session unlocked.
5. Enable each protected surface one at a time.
6. Click Test Authentication.
7. Confirm success, failure, cancel, and unavailable states are shown without
   exposing protected names.
8. Clear the unlock session.
9. Trigger a protected group or protected action and confirm it prompts.
10. Disable Private Access and confirm the same Basic Mode action works without
   authentication.

## Expected

- No new macOS privacy prompt appears.
- Enabling Private Access requires successful Touch ID or device password authentication.
- Diagnostics show generic auth status only.
- Safe Mode clears unlock sessions.
