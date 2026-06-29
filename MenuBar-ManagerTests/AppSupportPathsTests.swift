import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("AppSupportPaths")
@MainActor
struct AppSupportPathsTests {
    @Test func pathsAreNestedUnderDisplayName() {
        let paths = AppSupportPaths()
        let support = paths.applicationSupportDirectory.path
        #expect(support.hasSuffix("/\(AppConstants.displayName)"))
        #expect(paths.diagnosticsDirectory.path.hasSuffix("/\(AppConstants.displayName)/diagnostics"))
        #expect(paths.profilesDirectory.path.hasSuffix("/\(AppConstants.displayName)/profiles"))
        #expect(paths.backupsDirectory.path.hasSuffix("/\(AppConstants.displayName)/backups"))
        #expect(paths.dogfoodDirectory.path.hasSuffix("/\(AppConstants.displayName)/Dogfood"))
        #expect(paths.dogfoodRunsDirectory.path.hasSuffix("/\(AppConstants.displayName)/Dogfood/runs"))
        #expect(paths.dogfoodExportsDirectory.path.hasSuffix("/\(AppConstants.displayName)/Dogfood/exports"))
    }

    @Test func ensureDirectoriesExistCreatesAllKnownSubdirectories() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("AppSupportPathsTests.\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let paths = AppSupportPaths(fileManager: .default, baseURL: tempRoot)

        let created = try paths.ensureDirectoriesExist()

        #expect(created.count == 7)
        for url in created {
            #expect(FileManager.default.fileExists(atPath: url.path))
        }

        #expect(FileManager.default.fileExists(atPath: paths.diagnosticsDirectory.path))
        #expect(FileManager.default.fileExists(atPath: paths.profilesDirectory.path))
        #expect(FileManager.default.fileExists(atPath: paths.backupsDirectory.path))
        #expect(FileManager.default.fileExists(atPath: paths.dogfoodDirectory.path))
        #expect(FileManager.default.fileExists(atPath: paths.dogfoodRunsDirectory.path))
        #expect(FileManager.default.fileExists(atPath: paths.dogfoodExportsDirectory.path))
        #expect(FileManager.default.fileExists(atPath: paths.applicationSupportDirectory.path))
    }

    @Test func ensureDirectoriesExistIsIdempotent() throws {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("AppSupportPathsTests.idem.\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let paths = AppSupportPaths(fileManager: .default, baseURL: tempRoot)

        let first = try paths.ensureDirectoriesExist()
        let second = try paths.ensureDirectoriesExist()

        #expect(first.count == 7)
        #expect(second.isEmpty)
    }

    @Test func diagnosticsExportURLResolvesInsideDiagnosticsDirectory() {
        let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let paths = AppSupportPaths(baseURL: tempRoot)
        let url = paths.diagnosticsExportURL(filename: "diagnostics.txt")
        #expect(url.path.hasSuffix("/\(AppConstants.displayName)/diagnostics/diagnostics.txt"))
    }
}
