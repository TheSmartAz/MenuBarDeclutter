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
            "scripts/qa_second_bar_manual_gate_audit.sh",
            "scripts/qa_second_bar_matrix_coverage.sh",
            "scripts/qa_second_bar_signoff_audit.sh",
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
            "scripts/qa_second_bar_manual_gate_audit.sh",
            "scripts/qa_second_bar_matrix_coverage.sh",
            "scripts/qa_second_bar_signoff_audit.sh",
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

    @Test func privacyVerifierKeepsSecondBarEntryPointsPromptFree() throws {
        let root = Self.repositoryRoot()
        let verifier = try String(
            contentsOf: root.appendingPathComponent("scripts/verify_privacy_boundary.sh"),
            encoding: .utf8
        )

        #expect(verifier.contains("check_second_bar_entrypoints_do_not_prompt"))
        #expect(verifier.contains("Second Bar status and compact entry points do not request privacy prompts"))
        #expect(verifier.contains("Explicit Screen Recording request buttons remain available for Accurate Icons"))

        for file in [
            "MenuBar-Manager/App/AppEnvironment.swift",
            "MenuBar-Manager/CommandCenter/MenuBarCommandRouter.swift",
            "MenuBar-Manager/SecondBar/ProSecondBarReadiness.swift",
            "MenuBar-Manager/SecondBar/SecondBarCompactStripWindowController.swift",
            "MenuBar-Manager/StatusBar/StatusBarMenuBuilder.swift"
        ] {
            let text = try String(contentsOf: root.appendingPathComponent(file), encoding: .utf8)
            #expect(!text.contains("requestPromptFromUserAction"), "\(file) must not request Accessibility prompts.")
            #expect(!text.contains("requestPermissionFromUserAction"), "\(file) must not request Screen Recording prompts.")
            #expect(!text.contains("CGRequestScreenCaptureAccess"), "\(file) must not directly request Screen Recording.")
        }

        let setupChecklist = try String(
            contentsOf: root.appendingPathComponent("MenuBar-Manager/Settings/ProSecondBarSetupChecklistView.swift"),
            encoding: .utf8
        )
        let privacySettings = try String(
            contentsOf: root.appendingPathComponent("MenuBar-Manager/Settings/PrivacySettingsView.swift"),
            encoding: .utf8
        )

        #expect(setupChecklist.contains("requestPromptFromUserAction"))
        #expect(setupChecklist.contains("requestPermissionFromUserAction"))
        #expect(privacySettings.contains("requestPromptFromUserAction"))
        #expect(privacySettings.contains("requestPermissionFromUserAction"))
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

    @Test func dogfoodPreflightCanRunSecondBarManualAuditWhenDiagnosticsAreProvided() throws {
        let root = Self.repositoryRoot()
        let text = try String(
            contentsOf: root.appendingPathComponent("scripts/qa_dogfood_preflight.sh"),
            encoding: .utf8
        )

        #expect(text.contains("SECOND_BAR_DIAGNOSTICS_JSON"))
        #expect(text.contains("run_second_bar_manual_gate_audit"))
        #expect(text.contains("qa_second_bar_manual_gate_audit.sh"))
        #expect(text.contains("SECOND_BAR_AUDIT_REQUIRE_NOTCH"))
        #expect(text.contains("SECOND_BAR_AUDIT_REQUIRE_FAILURE_ROW"))
        #expect(text.contains("SECOND_BAR_AUDIT_MIN_WARMED_ICONS"))
        #expect(text.contains("SECOND_BAR_AUDIT_MATRIX_OUTPUT"))
        #expect(text.contains("DOGFOOD_SECOND_BAR_AUDIT_ONLY"))
        #expect(text.contains("Second Bar manual gate audit skipped"))
    }

    @Test func dogfoodPreflightSecondBarAuditOnlyRunsManualAuditFixture() throws {
        let root = Self.repositoryRoot()
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DogfoodSecondBarAuditOnly-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let diagnosticsURL = tempDirectory.appendingPathComponent("diagnostics.json")
        let auditLogURL = tempDirectory.appendingPathComponent("audit.log")
        let matrixURL = tempDirectory.appendingPathComponent("matrix.md")
        try Self.secondBarManualGateAuditFixture.write(to: diagnosticsURL, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [
            root.appendingPathComponent("scripts/qa_dogfood_preflight.sh").path
        ]
        process.environment = ProcessInfo.processInfo.environment.merging([
            "DOGFOOD_SECOND_BAR_AUDIT_ONLY": "1",
            "SECOND_BAR_DIAGNOSTICS_JSON": diagnosticsURL.path,
            "SECOND_BAR_AUDIT_OUTPUT": auditLogURL.path,
            "SECOND_BAR_AUDIT_MATRIX_OUTPUT": matrixURL.path,
            "SECOND_BAR_AUDIT_REQUIRE_NOTCH": "1",
            "SECOND_BAR_AUDIT_REQUIRE_FAILURE_ROW": "1",
            "SECOND_BAR_AUDIT_MAX_FALLBACK_ICONS": "0",
            "SECOND_BAR_AUDIT_DATE": "2026-07-06",
            "SECOND_BAR_AUDIT_APP_CATEGORY": "calendar",
            "SECOND_BAR_AUDIT_DYNAMIC_ICON": "yes",
            "SECOND_BAR_AUDIT_RETRY_RESULT": "retried-pass"
        ]) { _, new in new }
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let auditLog = try String(contentsOf: auditLogURL, encoding: .utf8)
        let matrix = try String(contentsOf: matrixURL, encoding: .utf8)

        #expect(process.terminationStatus == 0, "stdout: \(output)\nstderr: \(error)")
        #expect(output.contains("Second Bar audit-only mode"))
        #expect(output.contains("Second Bar manual gate audit passed"))
        #expect(auditLog.contains("PASS: Direct activation PASS coverage - 1 PASS row(s)"))
        #expect(matrix.contains("FAIL_AX_PRESS"))
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
        #expect(text.contains("panel|33-compact-second-bar-fallback-icons|Compact Second Bar - Fallback Icons|optional|--ui-testing-show-compact-second-bar"))
        #expect(text.contains("panel|34-compact-second-bar-accessibility-required|Compact Second Bar - Accessibility Required|optional|--ui-testing-show-compact-second-bar"))
        #expect(text.contains("panel|35-compact-second-bar-accurate-icons-required|Compact Second Bar - Accurate Icons Required|optional|--ui-testing-show-compact-second-bar"))
        #expect(text.contains("panel|36-compact-second-bar-screen-recording-required|Compact Second Bar - Screen Recording Required|optional|--ui-testing-show-compact-second-bar"))
        #expect(text.contains("--ui-testing-second-bar-primary-click-enabled"))
        #expect(text.contains("--ui-testing-seed-rendered-icons"))
        #expect(text.contains("--ui-testing-seed-partial-rendered-icons"))
        #expect(text.contains("--ui-testing-accessibility-revoked-after-launch"))
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

    @Test func secondBarMatrixCoverageScriptChecksRequiredHandsOnBreadth() throws {
        let root = Self.repositoryRoot()
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SecondBarMatrixCoverage-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let matrixURL = tempDirectory.appendingPathComponent("matrix.md")
        let matrix = """
        | Date | macOS Build | App Build | App Category | Item Zone | Dynamic Icon | Activation Result | Retry Result | targetID | targetZone | visitedElementCount | axError | Notes |
        | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | utility | hidden | no | PASS | not-needed | utility-1 | hidden | 4 | none | utility template item |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | template | hidden | no | PASS | not-needed | utility-2 | hidden | 5 | none | common monochrome item |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | calendar | hidden | yes | PASS | not-needed | dynamic-1 | hidden | 6 | none | colored dynamic calendar item |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | sync | hidden | yes | PASS | not-needed | dynamic-2 | hidden | 7 | none | stateful sync item |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | popover | hidden | no | PASS | not-needed | popover-1 | hidden | 4 | none | popover-style item |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | popover | hidden | no | PASS | not-needed | popover-2 | hidden | 5 | none | custom popover item |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | menu | hidden | no | PASS | not-needed | menu-1 | hidden | 4 | none | menu-style item |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | menu | hidden | no | PASS | not-needed | menu-2 | hidden | 5 | none | standard menu item |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | utility | hidden | no | FAIL_STALE_METADATA | retried-pass | stale-1 | hidden | 1 | none | relaunch owner app after scan; stale metadata |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | utility | hidden | no | BLOCKED | not-needed | permission-1 | hidden | 0 | none | Accessibility permission revoked; readiness gate blocked activation |
        """
        try matrix.write(to: matrixURL, atomically: true, encoding: .utf8)

        let passProcess = Process()
        passProcess.executableURL = URL(fileURLWithPath: "/bin/bash")
        passProcess.arguments = [
            root.appendingPathComponent("scripts/qa_second_bar_matrix_coverage.sh").path,
            matrixURL.path
        ]
        let passOutputPipe = Pipe()
        let passErrorPipe = Pipe()
        passProcess.standardOutput = passOutputPipe
        passProcess.standardError = passErrorPipe

        try passProcess.run()
        passProcess.waitUntilExit()

        let passOutput = String(data: passOutputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let passError = String(data: passErrorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        #expect(passProcess.terminationStatus == 0, "stdout: \(passOutput)\nstderr: \(passError)")
        #expect(passOutput.contains("Utility/template icon PASS rows - 2/2"))
        #expect(passOutput.contains("Colored/dynamic icon PASS rows - 2/2"))
        #expect(passOutput.contains("Second Bar direct activation matrix coverage passed."))

        let failProcess = Process()
        failProcess.executableURL = URL(fileURLWithPath: "/bin/bash")
        failProcess.arguments = [
            root.appendingPathComponent("scripts/qa_second_bar_matrix_coverage.sh").path,
            "--min-popover", "3",
            matrixURL.path
        ]
        let failOutputPipe = Pipe()
        let failErrorPipe = Pipe()
        failProcess.standardOutput = failOutputPipe
        failProcess.standardError = failErrorPipe

        try failProcess.run()
        failProcess.waitUntilExit()

        let failOutput = String(data: failOutputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        #expect(failProcess.terminationStatus == 1)
        #expect(failOutput.contains("FAIL: Popover-style PASS rows - 2/3"))
    }

    @Test func secondBarSignoffAuditAggregatesEvidenceAndFailsMissingDogfood() throws {
        let root = Self.repositoryRoot()
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SecondBarSignoffAudit-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let manualQAURL = tempDirectory.appendingPathComponent("manual.md")
        let dogfoodURL = tempDirectory.appendingPathComponent("dogfood.md")
        let matrixURL = tempDirectory.appendingPathComponent("matrix.md")
        let manifestURL = tempDirectory.appendingPathComponent("manifest.tsv")

        let manualQA = """
        | Area | Result | Notes |
        | --- | --- | --- |
        | Latest installed app | PASS | |
        | Installed privacy and network boundary | PASS | |
        | App Intent readiness gate | PASS | |
        | URL automation readiness gate | PASS | |
        | Direct activation matrix logging | PASS | |
        | Direct activation matrix helper | PASS | |
        | Manual gate audit helper | PASS | |
        | Primary-click opt-in gate | PASS | |
        | Activation failure retry state | PASS | |
        | Compact strip item inclusion | PASS | |
        | Compact strip scan state | PASS | |
        | Compact strip diagnostics export | PASS | |
        | Compact strip screenshot QA | PASS | |
        | Warm-up diagnostics | PASS | |
        | Readiness diagnostics export | PASS | |
        """
        let dogfoodPass = """
        | Scenario | Result | Notes |
        | --- | --- | --- |
        | Second Bar setup gates ready | PASS | |
        | Second Bar compact strip opens and closes | PASS | |
        | Second Bar Accurate Icons warm-up | PASS | |
        | Second Bar notch placement | PASS | |
        | Second Bar external display placement | PASS | |
        | Second Bar direct activation matrix | PASS | |
        | Second Bar manual gate audit passes | PASS | |
        """
        let matrix = """
        | Date | macOS Build | App Build | App Category | Item Zone | Dynamic Icon | Activation Result | Retry Result | targetID | targetZone | visitedElementCount | axError | Notes |
        | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | utility | hidden | no | PASS | not-needed | utility-1 | hidden | 4 | none | utility template item |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | template | hidden | no | PASS | not-needed | utility-2 | hidden | 5 | none | common monochrome item |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | calendar | hidden | yes | PASS | not-needed | dynamic-1 | hidden | 6 | none | colored dynamic calendar item |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | sync | hidden | yes | PASS | not-needed | dynamic-2 | hidden | 7 | none | stateful sync item |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | popover | hidden | no | PASS | not-needed | popover-1 | hidden | 4 | none | popover-style item |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | popover | hidden | no | PASS | not-needed | popover-2 | hidden | 5 | none | custom popover item |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | menu | hidden | no | PASS | not-needed | menu-1 | hidden | 4 | none | menu-style item |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | menu | hidden | no | PASS | not-needed | menu-2 | hidden | 5 | none | standard menu item |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | utility | hidden | no | FAIL_STALE_METADATA | retried-pass | stale-1 | hidden | 1 | none | relaunch owner app after scan; stale metadata |
        | 2026-07-06 | 26.0 | 0.1.10 build 11 | utility | hidden | no | BLOCKED | not-needed | permission-1 | hidden | 0 | none | Accessibility permission revoked; readiness gate blocked activation |
        """
        let manifest = """
        status\tslug\tlabel\tkind\twindow_id\tx\ty\twidth\theight\tlayer\ttitle\tpath\targs
        captured\t32-compact-second-bar\tCompact Second Bar\tpanel\t1\t0\t0\t166\t42\t3\tSecond Bar Compact Strip\tscreenshots/32.png\t
        captured\t33-compact-second-bar-fallback-icons\tCompact Second Bar - Fallback Icons\tpanel\t2\t0\t0\t166\t42\t3\tSecond Bar Compact Strip\tscreenshots/33.png\t
        captured\t34-compact-second-bar-accessibility-required\tCompact Second Bar - Accessibility Required\tpanel\t3\t0\t0\t146\t42\t3\tSecond Bar Compact Strip\tscreenshots/34.png\t
        captured\t35-compact-second-bar-accurate-icons-required\tCompact Second Bar - Accurate Icons Required\tpanel\t4\t0\t0\t146\t42\t3\tSecond Bar Compact Strip\tscreenshots/35.png\t
        captured\t36-compact-second-bar-screen-recording-required\tCompact Second Bar - Screen Recording Required\tpanel\t5\t0\t0\t146\t42\t3\tSecond Bar Compact Strip\tscreenshots/36.png\t
        """

        try manualQA.write(to: manualQAURL, atomically: true, encoding: .utf8)
        try dogfoodPass.write(to: dogfoodURL, atomically: true, encoding: .utf8)
        try matrix.write(to: matrixURL, atomically: true, encoding: .utf8)
        try manifest.write(to: manifestURL, atomically: true, encoding: .utf8)

        let passProcess = Process()
        passProcess.executableURL = URL(fileURLWithPath: "/bin/bash")
        passProcess.arguments = [
            root.appendingPathComponent("scripts/qa_second_bar_signoff_audit.sh").path,
            "--manual-qa", manualQAURL.path,
            "--dogfood-gate", dogfoodURL.path,
            "--matrix", matrixURL.path,
            "--screenshot-manifest", manifestURL.path
        ]
        let passOutputPipe = Pipe()
        let passErrorPipe = Pipe()
        passProcess.standardOutput = passOutputPipe
        passProcess.standardError = passErrorPipe

        try passProcess.run()
        passProcess.waitUntilExit()

        let passOutput = String(data: passOutputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let passError = String(data: passErrorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        #expect(passProcess.terminationStatus == 0, "stdout: \(passOutput)\nstderr: \(passError)")
        #expect(passOutput.contains("PASS: Direct activation matrix coverage"))
        #expect(passOutput.contains("PASS: Gate C dogfood - Second Bar direct activation matrix is PASS"))
        #expect(passOutput.contains("Second Bar sign-off audit passed."))

        let dogfoodFail = dogfoodPass.replacing(
            "| Second Bar setup gates ready | PASS | |",
            with: "| Second Bar setup gates ready | NOT TESTED | |"
        )
        try dogfoodFail.write(to: dogfoodURL, atomically: true, encoding: .utf8)

        let failProcess = Process()
        failProcess.executableURL = URL(fileURLWithPath: "/bin/bash")
        failProcess.arguments = passProcess.arguments
        let failOutputPipe = Pipe()
        let failErrorPipe = Pipe()
        failProcess.standardOutput = failOutputPipe
        failProcess.standardError = failErrorPipe

        try failProcess.run()
        failProcess.waitUntilExit()

        let failOutput = String(data: failOutputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        #expect(failProcess.terminationStatus == 1)
        #expect(failOutput.contains("FAIL: Gate C dogfood - Second Bar setup gates ready expected PASS, got NOT TESTED"))
    }

    @Test func secondBarManualGateAuditChecksReadinessRuntimeAndActivationEvidence() throws {
        let root = Self.repositoryRoot()
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SecondBarManualGateAudit-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let diagnosticsURL = tempDirectory.appendingPathComponent("diagnostics.json")
        let matrixURL = tempDirectory.appendingPathComponent("matrix.md")
        try Self.secondBarManualGateAuditFixture.write(to: diagnosticsURL, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [
            root.appendingPathComponent("scripts/qa_second_bar_manual_gate_audit.sh").path,
            "--require-notch-avoidance",
            "--require-failure-row",
            "--max-fallback-icons", "0",
            "--matrix-output", matrixURL.path,
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
        let matrix = try String(contentsOf: matrixURL, encoding: .utf8)

        #expect(process.terminationStatus == 0, "stdout: \(output)\nstderr: \(error)")
        #expect(output.contains("PASS: Readiness is ready"))
        #expect(output.contains("PASS: Last icon warm-up result - Refreshed 3 thumbnail(s) (3 >= 1)"))
        #expect(output.contains("PASS: Direct activation PASS coverage - 1 PASS row(s)"))
        #expect(output.contains("PASS: Direct activation failure coverage - 1 failure row(s)"))
        #expect(output.contains("Second Bar manual gate audit passed"))
        #expect(matrix.contains("| Date | macOS Build | App Build | App Category | Item Zone | Dynamic Icon | Activation Result | Retry Result | targetID | targetZone | visitedElementCount | axError | Notes |"))
        #expect(matrix.contains("| 2026-07-06 | 26.0 | 0.1.10 build 11 | calendar | hidden | yes | PASS | retried-pass | item-1 | hidden | 4 | none | Menu bar item activated. |"))
        #expect(matrix.contains("FAIL_AX_PRESS"))

        let staleWarmUpDiagnosticsURL = tempDirectory.appendingPathComponent("stale-warm-up.json")
        let staleWarmUpFixture = Self.secondBarManualGateAuditFixture.replacing(
            "\"lastIconWarmUpResult\": \"Refreshed 3 thumbnail(s)\"",
            with: "\"lastIconWarmUpResult\": \"Refreshed 0 thumbnail(s)\""
        )
        try staleWarmUpFixture.write(to: staleWarmUpDiagnosticsURL, atomically: true, encoding: .utf8)

        let warmUpFailureProcess = Process()
        warmUpFailureProcess.executableURL = URL(fileURLWithPath: "/bin/bash")
        warmUpFailureProcess.arguments = [
            root.appendingPathComponent("scripts/qa_second_bar_manual_gate_audit.sh").path,
            staleWarmUpDiagnosticsURL.path
        ]
        let warmUpFailureOutputPipe = Pipe()
        let warmUpFailureErrorPipe = Pipe()
        warmUpFailureProcess.standardOutput = warmUpFailureOutputPipe
        warmUpFailureProcess.standardError = warmUpFailureErrorPipe

        try warmUpFailureProcess.run()
        warmUpFailureProcess.waitUntilExit()

        let warmUpFailureOutput = String(
            data: warmUpFailureOutputPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        #expect(warmUpFailureProcess.terminationStatus == 1)
        #expect(warmUpFailureOutput.contains("FAIL: Last icon warm-up result - expected at least 1 refreshed icon(s), got \"Refreshed 0 thumbnail(s)\""))
    }

    private static let secondBarManualGateAuditFixture = """
    {
      "application": {
        "marketingVersion": "0.1.10",
        "buildNumber": "11"
      },
      "system": {
        "macOSVersion": "26.0"
      },
      "secondBarReadiness": {
        "readinessState": "ready",
        "readinessTitle": "Ready",
        "readinessMessage": "Second Bar is ready.",
        "isReady": true,
        "entitlement": "licensed",
        "entitlementActive": true,
        "accessibilityDiscoveryEnabled": true,
        "accessibilityPermission": "granted",
        "accurateIconsEnabled": true,
        "screenCapturePermission": "granted",
        "primaryClickOptIn": true,
        "primaryClickRoute": "toggleCompactStrip",
        "safeModeActive": false
      },
      "secondBarRuntime": {
        "visible": false,
        "itemCount": 3,
        "currentScreen": "screen-1",
        "lastPosition": "x 100, y 24, 166 x 42",
        "iconWarmUpInProgress": false,
        "lastIconWarmUpResult": "Refreshed 3 thumbnail(s)",
        "lastCompactVisibleItemCount": 2,
        "lastCompactOverflowItemCount": 1,
        "lastCompactFallbackIconCount": 0,
        "lastCompactScanState": "Fresh",
        "lastCompactAvoidedNotch": true,
        "lastActivationResult": "success",
        "lastActivationMatrixResult": "PASS",
        "lastActivationTargetZone": "hidden",
        "lastActivationVisitedElementCount": 4,
        "lastActivationAXError": null
      },
      "logs": [
        {
          "timestamp": "2026-07-06T10:01:00Z",
          "message": "Second Bar activation result: success.",
          "metadata": {
            "targetID": "item-1",
            "targetZone": "hidden",
            "matrixResult": "PASS",
            "visitedElementCount": "4",
            "axError": "none",
            "message": "Menu bar item activated."
          }
        },
        {
          "timestamp": "2026-07-06T10:02:00Z",
          "message": "Second Bar activation result: actionFailed.",
          "metadata": {
            "targetID": "item-2",
            "targetZone": "hidden",
            "matrixResult": "FAIL_AX_PRESS",
            "visitedElementCount": "5",
            "axError": "cannotComplete",
            "message": "Menu bar item did not accept AXPress."
          }
        }
      ]
    }
    """

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
