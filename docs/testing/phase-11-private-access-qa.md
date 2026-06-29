# Phase 11 Private Access QA

## Preconditions

- App installed or running from Xcode.
- Private Access disabled at start.

## Steps

1. Open Settings > Private Access.
2. Enable Private Access.
3. Enable each protected surface one at a time.
4. Click Test Authentication.
5. Confirm success, failure, cancel, and unavailable states are shown without
   exposing protected names.
6. Clear the unlock session.
7. Trigger a protected group or protected action and confirm it prompts.
8. Disable Private Access and confirm the same Basic Mode action works without
   authentication.

## Expected

- No new macOS privacy prompt appears.
- Authentication uses Touch ID or device password only.
- Diagnostics show generic auth status only.
- Safe Mode clears unlock sessions.
