# Phase 9.1 Audit

Date: 2026-06-28

## Commands Run

- `ls`
- `find . -maxdepth 4 -type f | sort`
- `xcodebuild -list`
- `xcodebuild -showBuildSettings -scheme MenuBarDeclutter -destination 'platform=macOS'`
- `xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'`

- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'`
- `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'`
- `scripts/verify_privacy_boundary.sh`
- `scripts/qa_preflight.sh`

## Schemes

Current shared schemes:

- `MenuBarDeclutter` - canonical Alpha RC scheme.
- `MenuBar-Manager` - deprecated compatibility scheme retained for existing scripts/docs during the transition.

## Targets

- App target: `MenuBarDeclutter`
- Unit test target: `MenuBarDeclutterTests`
- UI test target: `MenuBarDeclutterUITests`

## Bundle Identifiers

- App: `Yongjun-Zhang.MenuBarDeclutter`
- Unit tests: `Yongjun-Zhang.MenuBarDeclutterTests`
- UI tests: `Yongjun-Zhang.MenuBarDeclutterUITests`

Note: this is a temporary identity. The final app name and bundle identifier should be chosen deliberately before beta.

## Product Names

- Built wrapper: `MenuBarDeclutter.app`
- Display name: `MenuBarDeclutter`
- App support directory: `Application Support/MenuBarDeclutter`
- Diagnostics export prefix: `MenuBarDeclutter-diagnostics-`
- Health report export prefix: `MenuBarDeclutter-health-`

Note: the `.xcodeproj` package and source/test folders still use `MenuBar-Manager` to avoid noisy filesystem churn before the final name is chosen.

## Deployment Target

- `MACOSX_DEPLOYMENT_TARGET = 26.0`
- Supported platform: macOS only.

## Entitlements

The generated Debug entitlements include:

- `com.apple.security.app-sandbox = true`
- `com.apple.security.files.user-selected.read-write = true`
- `com.apple.security.get-task-allow = true` for Debug

No project entitlements file exists. Xcode generates sandbox entitlements from build settings.

## Info.plist

Explicit plist: `Config/MenuBarDeclutter-Info.plist`

Important keys:

- `CFBundleDisplayName = MenuBarDeclutter`
- `CFBundleName = MenuBarDeclutter`
- `CFBundleIdentifier = $(PRODUCT_BUNDLE_IDENTIFIER)`
- `CFBundleShortVersionString = $(MARKETING_VERSION)`
- `CFBundleVersion = $(CURRENT_PROJECT_VERSION)`
- `LSMinimumSystemVersion = $(MACOSX_DEPLOYMENT_TARGET)`
- `LSUIElement = true`
- `CFBundleURLTypes` registers `menubardeclutter`

## Privacy Boundary

- LSUIElement is set.
- URL scheme is registered as `menubardeclutter://`.
- App Sandbox is enabled.
- Outgoing and incoming network connections are disabled in build settings.
- No network entitlements are expected.
- No ScreenCaptureKit imports are present in app code.
- No Screen Recording, Apple Events, or Input Monitoring usage strings are registered.
- Accessibility references exist for Pro Mode only and are gated behind explicit Pro Mode/Accessibility Discovery/permission flow.

## Current Test Result

- `xcodebuild build -scheme MenuBarDeclutter -destination 'platform=macOS'`: `BUILD SUCCEEDED`.
- `xcodebuild test -scheme MenuBarDeclutter -destination 'platform=macOS'`: `TEST SUCCEEDED` (131 Swift tests, 7 UI tests).
- `xcodebuild test -scheme MenuBar-Manager -destination 'platform=macOS'`: `TEST SUCCEEDED` (131 Swift tests, 7 UI tests).
- `scripts/verify_privacy_boundary.sh`: passed.
- `scripts/qa_preflight.sh`: passed.

See `docs/status/phase-9.1-final-report.md` for exact result details.

## Manual QA Docs Available

- `docs/testing/manual-qa.md`
- `docs/testing/macos26-test-matrix.md`
- `docs/testing/privacy-qa.md`
- `docs/testing/alpha-rc-qa-matrix.md`
- `docs/testing/alpha-rc-qa-run-template.md`
- `docs/testing/known-risk-areas.md`

## Actionable Issues

1. Final product name and bundle identifier still need a deliberate beta decision; `MenuBarDeclutter` is temporary.
2. Launch at Login still requires installed signed app validation.
3. Real Command-drag separator placement, icon moving, external display/notch behavior, Accessibility grant/revoke, and network-watch checks require hands-on QA.
