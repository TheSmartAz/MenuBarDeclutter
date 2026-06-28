# Alpha RC Checklist

Do not mark an Alpha RC ready until every required item is PASS or has a written skip reason.

| Item | Required Result | Status | Notes |
| --- | --- | --- | --- |
| Working tree | Clean or documented diff | NOT TESTED | |
| Schemes | `MenuBarDeclutter` canonical; `MenuBar-Manager` deprecated fallback | NOT TESTED | |
| Unit/UI tests | `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` passes | NOT TESTED | |
| Privacy verification | `scripts/verify_privacy_boundary.sh` passes | NOT TESTED | |
| QA preflight | `scripts/qa_preflight.sh` passes | NOT TESTED | |
| Basic Mode | Manual QA pass | NOT TESTED | |
| Pro permission flow | Enable/request/grant/revoke QA pass | NOT TESTED | |
| Icon moving | Pass or documented as experimental with known limitations | NOT TESTED | |
| External display | Tested or explicit hardware gap documented | NOT TESTED | |
| Notch display | Tested or explicit hardware gap documented | NOT TESTED | |
| Launch at Login | Installed signed app test pass | NOT TESTED | |
| Safe Mode recovery | Crash marker and next-launch flag tested | NOT TESTED | |
| Codesign | `scripts/verify_release_artifact.sh` passes for artifact | NOT TESTED | |
| Notarization | Attempted or skipped with explicit reason | NOT TESTED | |
| Version/build | Marketing version and build number reviewed | NOT TESTED | |
| Known limitations | Included in release notes | NOT TESTED | |

## Release Commands

```sh
xcodebuild -list
xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'
xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'
scripts/verify_privacy_boundary.sh
scripts/qa_preflight.sh
```

For a release artifact:

```sh
APP_PATH=/path/to/MenuBarDeclutter.app scripts/verify_release_artifact.sh
```
