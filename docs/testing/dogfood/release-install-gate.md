# Gate E: Installed Release

Installed-app validation belongs after the fixture and Basic dogfood gate are usable.

Allowed results: PASS, FAIL, BLOCKED, PARTIAL, NOT TESTED.

| Scenario | Result | Notes |
| --- | --- | --- |
| Archive Release build | NOT TESTED | |
| Install to /Applications or private test location | NOT TESTED | |
| Launch installed app | NOT TESTED | |
| Launch at Login from installed app | NOT TESTED | |
| Restart login test | NOT TESTED | |
| Codesign verification | NOT TESTED | |
| Hardened runtime verification | NOT TESTED | |
| Developer ID/notarization out-of-scope status recorded | NOT TESTED | Current project stance does not require Developer ID signing, notarization, or stapling. |
| `spctl` verification | NOT TESTED | |
| LSUIElement behavior from installed app | NOT TESTED | |
| URL scheme opens installed app | NOT TESTED | |
| No unexpected network connection | NOT TESTED | |
