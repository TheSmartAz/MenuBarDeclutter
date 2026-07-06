import Foundation
import Testing

@Suite("QA Scripts")
struct QAScriptsTests {
    @Test func dogfoodScriptsExistAndAreExecutable() throws {
        let root = Self.repositoryRoot()
        let scripts = [
            "scripts/qa_build_fixture.sh",
            "scripts/qa_run_fixture.sh",
            "scripts/qa_stop_fixture.sh",
            "scripts/qa_preflight.sh",
            "scripts/qa_dogfood_preflight.sh",
            "scripts/qa_installed_app_smoke.sh",
            "scripts/qa_second_bar_activation_matrix.sh",
            "scripts/verify_privacy_boundary.sh",
            "scripts/test.sh",
            "scripts/export_visual_smoke_screenshots.sh",
            "scripts/qa_capture_ui_screenshots.sh"
        ]

        for script in scripts {
            try Self.expectExecutable(script, in: root)
        }
    }

    @Test func releaseScriptsExistAndAreExecutable() throws {
        let root = Self.repositoryRoot()
        let scripts = [
            "scripts/release_clean.sh",
            "scripts/release_archive.sh",
            "scripts/release_export_app.sh",
            "scripts/release_package_zip.sh",
            "scripts/release_notarize.sh",
            "scripts/release_staple.sh",
            "scripts/release_validate_gatekeeper.sh",
            "scripts/release_install_local.sh",
            "scripts/release_uninstall_local.sh",
            "scripts/build_release.sh",
            "scripts/verify_release_artifact.sh",
            "scripts/verify_installed_app.sh"
        ]

        for script in scripts {
            try Self.expectExecutable(script, in: root)
        }
    }

    @Test func criticalShellScriptsPassBashSyntaxCheck() throws {
        let root = Self.repositoryRoot()
        let scripts = [
            "scripts/qa_preflight.sh",
            "scripts/qa_dogfood_preflight.sh",
            "scripts/build_release.sh",
            "scripts/release_archive.sh",
            "scripts/release_export_app.sh",
            "scripts/release_package_zip.sh",
            "scripts/release_install_local.sh",
            "scripts/release_uninstall_local.sh",
            "scripts/release_notarize.sh",
            "scripts/release_staple.sh",
            "scripts/verify_release_artifact.sh",
            "scripts/verify_installed_app.sh",
            "scripts/qa_installed_app_smoke.sh",
            "scripts/qa_second_bar_activation_matrix.sh",
            "scripts/verify_privacy_boundary.sh",
            "scripts/test.sh",
            "scripts/export_visual_smoke_screenshots.sh",
            "scripts/qa_capture_ui_screenshots.sh"
        ]

        for script in scripts {
            try Self.expectBashSyntax(script, in: root)
        }
    }

    @Test func scriptsClearIntentionalTerminationCrashMarker() throws {
        let root = Self.repositoryRoot()
        let scripts = [
            "scripts/qa_preflight.sh",
            "scripts/qa_dogfood_preflight.sh",
            "scripts/qa_installed_app_smoke.sh",
            "scripts/release_install_local.sh"
        ]

        for script in scripts {
            let text = try String(contentsOf: root.appendingPathComponent(script), encoding: .utf8)
            #expect(text.contains("clear_intentional_termination_marker"))
            #expect(text.contains("running.marker"))
            #expect(text.contains("Yongjun-Zhang.MenuBarDeclutter"))
        }
    }

    @Test func preflightUsesStableBuildForTestingLane() throws {
        let root = Self.repositoryRoot()
        let script = root.appendingPathComponent("scripts/qa_preflight.sh")
        let text = try String(contentsOf: script, encoding: .utf8)

        #expect(text.contains("ENABLE_DEBUG_DYLIB=$XCODE_ENABLE_DEBUG_DYLIB"))
        #expect(text.contains("find_xctestrun_path"))
        #expect(text.contains("test-without-building"))
        #expect(text.contains("-only-testing:MenuBarDeclutterTests"))
    }

    @Test func dogfoodPreflightUsesStableBuildForTestingLane() throws {
        let root = Self.repositoryRoot()
        let script = root.appendingPathComponent("scripts/qa_dogfood_preflight.sh")
        let text = try String(contentsOf: script, encoding: .utf8)

        #expect(text.contains("ENABLE_DEBUG_DYLIB=$XCODE_ENABLE_DEBUG_DYLIB"))
        #expect(text.contains("find_xctestrun_path"))
        #expect(text.contains("test-without-building"))
        #expect(text.contains("-only-testing:MenuBarDeclutterTests/DogfoodStoreTests"))
        #expect(text.contains("phase15_tests_passed"))
        #expect(text.contains("phase15_tests_blocked_by_infra"))
        #expect(text.contains("xcode_tests_have_started"))
        #expect(text.contains("return 126"))
        #expect(text.contains("DOGFOOD_VERIFY_RELEASE_AFTER_TEST_FAILURE"))
        #expect(text.contains("DOGFOOD_REQUIRE_RELEASE_APP"))
        #expect(text.contains("run_release_artifact_verification"))
        #expect(text.contains("DOGFOOD_ARTIFACT_VERIFY_ATTEMPTS"))
        #expect(text.contains("Release artifact verification was killed by the OS"))
    }

    @Test func testScriptDefaultsToReliableUnitLaneWithProjectSigning() throws {
        let root = Self.repositoryRoot()
        let text = try String(contentsOf: root.appendingPathComponent("scripts/test.sh"), encoding: .utf8)

        #expect(text.contains("TEST_MODE=\"${TEST_MODE:-unit}\""))
        #expect(text.contains("AD_HOC_SIGNING_OVERRIDES=\"${AD_HOC_SIGNING_OVERRIDES:-0}\""))
        #expect(text.contains("xcodebuild test"))
        #expect(text.contains("-only-testing:MenuBarDeclutterTests"))
        #expect(text.contains("--ui|--ui-tests"))
        #expect(text.contains("-only-testing:MenuBarDeclutterUITests"))
        #expect(text.contains("Set AD_HOC_SIGNING_OVERRIDES=1"))
        #expect(text.contains("CODE_SIGN_IDENTITY=-"))
        #expect(text.contains("CODE_SIGNING_REQUIRED=NO"))
    }

    @Test func releaseBuildDefaultsToDryRunAndRequiresDeveloperIDOptIn() throws {
        let root = Self.repositoryRoot()
        let buildRelease = try String(contentsOf: root.appendingPathComponent("scripts/build_release.sh"), encoding: .utf8)
        let exportApp = try String(contentsOf: root.appendingPathComponent("scripts/release_export_app.sh"), encoding: .utf8)
        let archive = try String(contentsOf: root.appendingPathComponent("scripts/release_archive.sh"), encoding: .utf8)
        let package = try String(contentsOf: root.appendingPathComponent("scripts/release_package_zip.sh"), encoding: .utf8)

        #expect(buildRelease.contains("DRY_RUN=1"))
        #expect(buildRelease.contains("--developer-id"))
        #expect(buildRelease.contains("DEVELOPER_ID=1"))
        #expect(exportApp.contains("DRY_RUN=\"${DRY_RUN:-1}\""))
        #expect(exportApp.contains("DEVELOPER_ID_EXPORT=\"${DEVELOPER_ID_EXPORT:-0}\""))
        #expect(exportApp.contains("Developer ID export is out of the current project scope"))
        #expect(archive.contains("AD_HOC_SIGNING_OVERRIDES=\"${AD_HOC_SIGNING_OVERRIDES:-1}\""))
        #expect(archive.contains("CODE_SIGN_IDENTITY=-"))
        #expect(archive.contains("CODE_SIGNING_REQUIRED=NO"))
        #expect(package.contains("DRY_RUN=\"${DRY_RUN:-1}\""))
        #expect(package.contains("ZIP_PATH=\"$ROOT_DIR/build/Dist/MenuBarDeclutter-v$VERSION-alpha.zip\""))
        #expect(package.contains("ZIP_PATH=\"$ROOT_DIR/build/Dist/MenuBarDeclutter-v$VERSION.zip\""))
        #expect(package.contains("VERSIONED_ZIP_PATH=\"${VERSIONED_ZIP_PATH:-}\""))
    }

    @Test func preflightScriptsClassifyXcodeAutomationModeTimeoutsAsInfrastructure() throws {
        let root = Self.repositoryRoot()

        for script in ["scripts/qa_preflight.sh", "scripts/qa_dogfood_preflight.sh"] {
            let text = try String(contentsOf: root.appendingPathComponent(script), encoding: .utf8)

            #expect(text.contains("is_xcode_runner_bootstrap_failure"))
            #expect(text.contains("Timed out while enabling automation mode"))
            #expect(text.contains("failed to initialize for UI testing"))
            #expect(text.contains("BLOCKED-INFRA"))
            #expect(text.contains("xcode_tests_have_started"))
            #expect(text.contains("timed out after tests started"))
            #expect(text.contains("return 125") || text.contains("rc=125"))
        }
    }

    @Test func installedAppSmokeCoversOneShotSafeModeFlag() throws {
        let root = Self.repositoryRoot()
        let text = try String(
            contentsOf: root.appendingPathComponent("scripts/qa_installed_app_smoke.sh"),
            encoding: .utf8
        )

        #expect(text.contains("RUN_SAFE_MODE_FLAG"))
        #expect(text.contains("--skip-safe-mode-flag"))
        #expect(text.contains("safe-mode-next-launch.flag"))
        #expect(text.contains("clear_safe_mode_flags"))
        #expect(text.contains("expected_safe_mode_flag_path"))
        #expect(text.contains("APP_LAUNCH_TIMEOUT_SECONDS"))
        #expect(text.contains("candidate_installed_pids"))
        #expect(text.contains("pgrep -f"))
        #expect(text.contains("app_uses_sandbox"))
        #expect(text.contains("com.apple.security.app-sandbox"))
        #expect(text.contains("consumed the expected one-shot Safe Mode flag"))
    }

    @Test func screenshotCaptureTargetsFloatingPanelTitles() throws {
        let root = Self.repositoryRoot()
        let text = try String(
            contentsOf: root.appendingPathComponent("scripts/qa_capture_ui_screenshots.sh"),
            encoding: .utf8
        )

        #expect(text.contains("--title-contains"))
        #expect(text.contains("--pid \"$owner_pid\""))
        #expect(text.contains("WINDOW_MIN_HEIGHT=\"${WINDOW_MIN_HEIGHT:-40}\""))
        #expect(text.contains("panel|21-floating-find-icon|Floating Find Icon|optional|--ui-testing-show-search|Find Icon"))
        #expect(text.contains("panel|22-floating-second-bar|Floating Second Bar|optional|--ui-testing-show-second-bar --ui-testing-pro-discovery-enabled --ui-testing-accessibility-granted --ui-testing-accurate-icons-enabled --ui-testing-screen-capture-granted --ui-testing-seed-menu-bar-items|Second Bar"))
        #expect(text.contains("panel|23-floating-group-panel|Floating Group Panel|optional|--ui-testing-show-group-panel|Pinned Tools"))
        #expect(text.contains("panel|28-floating-second-bar-typed|Floating Second Bar - Typed|optional|--ui-testing-show-second-bar --ui-testing-pro-discovery-enabled --ui-testing-accessibility-granted --ui-testing-accurate-icons-enabled --ui-testing-screen-capture-granted --ui-testing-seed-menu-bar-items --ui-testing-second-bar-query=Drop|Second Bar"))
        #expect(text.contains("panel|32-compact-second-bar|Compact Second Bar|optional|--ui-testing-show-compact-second-bar"))
        #expect(text.contains("--ui-testing-second-bar-primary-click-enabled"))
        #expect(text.contains("--ui-testing-seed-rendered-icons"))
        #expect(text.contains("window_id\\tx\\ty\\twidth\\theight\\tlayer\\ttitle\\tpath\\targs"))
    }

    @Test func screenshotCaptureRetriesWindowRegistrationMisses() throws {
        let root = Self.repositoryRoot()
        let text = try String(
            contentsOf: root.appendingPathComponent("scripts/qa_capture_ui_screenshots.sh"),
            encoding: .utf8
        )

        #expect(text.contains("CAPTURE_ATTEMPTS=\"${CAPTURE_ATTEMPTS:-2}\""))
        #expect(text.contains("while (( attempt <= CAPTURE_ATTEMPTS ))"))
        #expect(text.contains("captured $label after retry attempt $attempt"))
        #expect(text.contains("no capturable window found for $label after $CAPTURE_ATTEMPTS attempt(s)"))
    }

    @Test func secondBarActivationMatrixScriptExtractsDiagnosticsRows() throws {
        let root = Self.repositoryRoot()
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SecondBarActivationMatrixScript-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let diagnosticsURL = tempDirectory.appendingPathComponent("diagnostics.json")
        let fixture = """
        {
          "application": {
            "marketingVersion": "0.1.10",
            "buildNumber": "11"
          },
          "system": {
            "macOSVersion": "26.0"
          },
          "logs": [
            {
              "timestamp": "2026-07-06T10:00:00Z",
              "message": "Other log.",
              "metadata": {}
            },
            {
              "timestamp": "2026-07-06T10:01:00Z",
              "message": "Second Bar activation result: success.",
              "metadata": {
                "targetID": "item-1",
                "targetZone": "hidden",
                "matrixResult": "PASS",
                "visitedElementCount": "3",
                "axError": "",
                "message": "Activated menu item"
              }
            }
          ]
        }
        """
        try fixture.write(to: diagnosticsURL, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [
            root.appendingPathComponent("scripts/qa_second_bar_activation_matrix.sh").path,
            "--date", "2026-07-06",
            "--app-category", "calendar",
            "--dynamic-icon", "yes",
            "--retry-result", "retried-pass",
            diagnosticsURL.path
        ]
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        #expect(process.terminationStatus == 0, "stderr: \(error)")
        #expect(output.contains("| 2026-07-06 | 26.0 | 0.1.10 build 11 | calendar | hidden | yes | PASS | retried-pass | item-1 | hidden | 3 | none | Activated menu item |"))
        #expect(!output.contains("Other log"))
    }

    @Test func fixtureTargetIsMarkedSkipInstall() throws {
        let root = Self.repositoryRoot()
        let project = root.appendingPathComponent("MenuBar-Manager.xcodeproj/project.pbxproj")
        let text = try String(contentsOf: project, encoding: .utf8)

        #expect(text.contains("MenuBarFixtureApp"))
        #expect(text.contains("SKIP_INSTALL = YES;"))
        #expect(text.contains("Config/MenuBarFixtureApp-Info.plist"))
    }

    @Test func releaseVerificationScriptsClassifyUnexpectedGatekeeperErrors() throws {
        let root = Self.repositoryRoot()
        for script in ["scripts/verify_release_artifact.sh", "scripts/verify_installed_app.sh"] {
            let text = try String(contentsOf: root.appendingPathComponent(script), encoding: .utf8)
            #expect(text.contains("expected_dry_run_spctl_failure"))
            #expect(text.contains("transient_spctl_failure"))
            #expect(text.contains("run_spctl_assessment"))
            #expect(text.contains("run_spctl_assessment_temp_copy"))
            #expect(text.contains("Too many open files"))
            #expect(text.contains("invalid resource directory"))
            #expect(text.contains("max_attempts=5"))
            #expect(text.contains("retrying ($attempt/$max_attempts)"))
            #expect(text.contains("temporary copy"))
            #expect(text.contains(": rejected$"))
            #expect(text.contains("raise_gatekeeper_file_limit"))
            #expect(text.contains("ulimit -n 1048575"))
            #expect(text.contains("ulimit -n 8192"))
            #expect(text.contains("persistent local Gatekeeper resource error after retries"))
            #expect(text.contains("unexpected error; not treating it as a notarization warning"))
            #expect(text.contains("Pro Accessibility Discovery requires a non-sandboxed assistive build"))
            #expect(text.contains("assistive/no-network invariants"))
            #expect(text.contains("version_from_config"))
            #expect(text.contains("build_from_config"))
            #expect(text.contains("Config/Shared.xcconfig"))
            #expect(!text.contains("EXPECTED_MARKETING_VERSION:-0.1.3"))
            #expect(!text.contains("EXPECTED_BUILD_VERSION:-4"))
        }
    }

    @Test func phase16ManualQADocsCoverAssistedMoveDogfood() throws {
        let root = Self.repositoryRoot()
        let doc = root.appendingPathComponent("docs/testing/manual-v0.1.3-assisted-move-dogfood.md")
        let text = try String(contentsOf: doc, encoding: .utf8)

        #expect(text.contains("Assisted Move is Experimental"))
        #expect(text.contains("source zone, target zone, planned direction, and risk"))
        #expect(text.contains("Dry-run must not post drag events"))
        #expect(text.contains("moveAttempted"))
        #expect(text.contains("sourceZone"))
        #expect(text.contains("targetZone"))
        #expect(text.contains("durationBucket"))
        #expect(text.contains("redacted=true"))
        #expect(text.contains("no raw item titles"))
        #expect(text.contains("guarded local move against a disposable fixture item passed"))
        #expect(text.contains("hands-on installed UI dry-run"))
    }

    @Test func uninstallPurgeIncludesSandboxContainerData() throws {
        let root = Self.repositoryRoot()
        let text = try String(
            contentsOf: root.appendingPathComponent("scripts/release_uninstall_local.sh"),
            encoding: .utf8
        )

        #expect(text.contains("Library/Containers/Yongjun-Zhang.MenuBarDeclutter"))
        #expect(text.contains("CONTAINER_SUPPORT"))
        #expect(text.contains("CONTAINER_PREFS"))
        #expect(text.contains("CONTAINER_CACHES"))
    }

    private static func repositoryRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private static func expectExecutable(_ script: String, in root: URL) throws {
        let url = root.appendingPathComponent(script)
        #expect(FileManager.default.fileExists(atPath: url.path))
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let permissions = try #require(attributes[.posixPermissions] as? NSNumber)
        #expect((permissions.intValue & 0o111) != 0)
    }

    private static func expectBashSyntax(_ script: String, in root: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-n", root.appendingPathComponent(script).path]
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)
    }
}
