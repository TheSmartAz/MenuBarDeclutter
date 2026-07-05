# Alpha RC Checklist

Do not mark an Alpha RC ready until every required item is PASS or has a written skip reason.

Historical note: the status rows below document the 2026-06-28 Alpha RC validation snapshot. The current checkout has later Phase 9.2-9.5 work, including the local-only `MenuBarFixtureApp` QA scheme and v0.1 freeze docs.

| Item | Required Result | Status | Notes |
| --- | --- | --- | --- |
| Working tree | Clean or documented diff | PASS | Automated validation started from clean commit `a30414e`; this checklist update documents results. |
| Schemes | `MenuBarDeclutter` canonical; `MenuBar-Manager` deprecated fallback; later dogfood QA also has `MenuBarFixtureApp` | PASS | The Alpha RC run showed the product schemes; current `xcodebuild -list` also includes the fixture QA scheme. |
| Unit/UI tests | `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'` passes | PASS | Dated Alpha RC run passed: 203 unit tests + 7 UI executions. Result bundle: `/tmp/MenuBarDeclutter-AlphaRCFull.xcresult`. Later v0.1 preflight records 215 unit tests in 37 suites plus 7 UI tests. |
| Privacy verification | `scripts/verify_privacy_boundary.sh` passes | PASS | Source/project privacy check passed; built Release app check also passed with `APP_PATH`. |
| QA preflight | `scripts/qa_preflight.sh` passes | PASS | Scripted preflight passed tests and privacy verification. |
| Basic Mode | Manual QA pass | NOT TESTED | Requires hands-on clean first launch, menu bar drag, collapse/expand, hover, auto-rehide, and hotkey validation. |
| Pro permission flow | Enable/request/grant/revoke QA pass | NOT TESTED | Requires System Settings Accessibility interaction. |
| Icon moving | Pass or documented as experimental with known limitations | PASS | Experimental limitations are documented; real third-party move QA remains NOT TESTED in the QA run. |
| External display | Tested or explicit hardware gap documented | PASS | Hardware gap documented in the QA run; not manually tested. |
| Notch display | Tested or explicit hardware gap documented | PASS | Hardware gap documented in the QA run; not manually tested. |
| Launch at Login | Installed signed app test pass | NOT TESTED | Requires installed signed app validation through System Settings. |
| Safe Mode recovery | Crash marker and next-launch flag tested | NOT TESTED | Requires hands-on crash-marker / modifier-key / relaunch validation. |
| Codesign | `scripts/verify_release_artifact.sh` passes for artifact | PASS | Local Release app passed `scripts/verify_release_artifact.sh build/DerivedData/Build/Products/Release/MenuBarDeclutter.app`. |
| Notarization | Attempted or skipped with explicit reason | NOT TESTED | Skipped because no Developer ID notarized distribution artifact was produced. |
| Version/build | Marketing version and build number reviewed | PASS | Current v0.1 build settings report marketing version `0.1.0`, build `1`, bundle ID `Yongjun-Zhang.MenuBarDeclutter`. |
| Known limitations | Included in release notes | PASS | `docs/release/alpha-rc-release-notes-2026-06-28.md` links the known limitations and calls out remaining manual QA blockers. |

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
