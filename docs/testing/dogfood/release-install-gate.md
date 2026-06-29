# Gate E: Installed Release

Installed-app validation belongs after the fixture and Basic dogfood gate are usable.

Allowed results: PASS, FAIL, BLOCKED, NOT TESTED.

| Scenario | Result | Notes |
| --- | --- | --- |
| Archive Release build | NOT TESTED | |
| Install to /Applications or private test location | NOT TESTED | |
| Launch installed app | NOT TESTED | |
| Launch at Login from installed app | NOT TESTED | |
| Restart login test | NOT TESTED | |
| Codesign verification | NOT TESTED | |
| Hardened runtime verification | NOT TESTED | |
| Notarization placeholder or real notarization | NOT TESTED | |
| Staple notarization ticket if available | NOT TESTED | |
| `spctl` verification | NOT TESTED | |
| LSUIElement behavior from installed app | NOT TESTED | |
| URL scheme opens installed app | NOT TESTED | |
| No unexpected network connection | NOT TESTED | |
