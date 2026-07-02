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
            "scripts/verify_privacy_boundary.sh",
            "scripts/test.sh",
            "scripts/export_visual_smoke_screenshots.sh"
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
            "scripts/verify_privacy_boundary.sh",
            "scripts/test.sh",
            "scripts/export_visual_smoke_screenshots.sh"
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
