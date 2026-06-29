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
            "scripts/qa_dogfood_preflight.sh"
        ]

        for script in scripts {
            let url = root.appendingPathComponent(script)
            #expect(FileManager.default.fileExists(atPath: url.path))
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let permissions = try #require(attributes[.posixPermissions] as? NSNumber)
            #expect((permissions.intValue & 0o111) != 0)
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
            "scripts/verify_installed_app.sh"
        ]

        for script in scripts {
            let url = root.appendingPathComponent(script)
            #expect(FileManager.default.fileExists(atPath: url.path))
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let permissions = try #require(attributes[.posixPermissions] as? NSNumber)
            #expect((permissions.intValue & 0o111) != 0)
        }
    }

    @Test func fixtureTargetIsMarkedSkipInstall() throws {
        let root = Self.repositoryRoot()
        let project = root.appendingPathComponent("MenuBar-Manager.xcodeproj/project.pbxproj")
        let text = try String(contentsOf: project, encoding: .utf8)

        #expect(text.contains("MenuBarFixtureApp"))
        #expect(text.contains("SKIP_INSTALL = YES;"))
        #expect(text.contains("Config/MenuBarFixtureApp-Info.plist"))
    }

    private static func repositoryRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
