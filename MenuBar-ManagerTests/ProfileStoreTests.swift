import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("ProfileStore")
@MainActor
struct ProfileStoreTests {
    @Test func profileSaveLoadRoundTripsJSON() throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }

        let created = harness.store.createProfile(name: "Work")
        var edited = created
        edited.showSecondBar = true
        edited.targetZonesByBundleID = ["com.example.app": .hidden]
        harness.store.update(edited)

        let reloaded = ProfileStore(appSupportPaths: harness.paths)
        reloaded.load()

        #expect(reloaded.profiles.count == 1)
        #expect(reloaded.profiles.first?.name == "Work")
        #expect(reloaded.profiles.first?.showSecondBar == true)
        #expect(reloaded.profiles.first?.targetZonesByBundleID["com.example.app"] == .hidden)
    }

    @Test func loadSkipsCorruptProfileFilesAndKeepsValidProfiles() throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }

        harness.store.createProfile(name: "Good")
        let corruptURL = harness.paths.profilesDirectory.appendingPathComponent("corrupt.json")
        try Data("{".utf8).write(to: corruptURL)

        let reloaded = ProfileStore(appSupportPaths: harness.paths)
        reloaded.load()

        #expect(reloaded.profiles.map(\.name) == ["Good"])
        #expect(reloaded.lastError?.contains("Skipped 1 profile file") == true)
        #expect(reloaded.lastError?.contains("corrupt.json") == true)
    }

    @Test func profileJSONHandlesSchemaVersion() throws {
        let harness = try makeHarness()
        defer { harness.cleanup() }

        let profile = ProfileModel(name: "Legacy")
        let encodedData = try harness.store.encodedData(for: profile)
        let encodedObject = try #require(try JSONSerialization.jsonObject(with: encodedData) as? [String: Any])
        #expect(try #require(encodedObject["schemaVersion"] as? Int) == ProfileModel.currentSchemaVersion)

        var legacyObject = encodedObject
        legacyObject.removeValue(forKey: "schemaVersion")
        let legacyData = try JSONSerialization.data(withJSONObject: legacyObject)
        let decoded = try harness.store.decodeProfile(from: legacyData)

        #expect(decoded.schemaVersion == ProfileModel.currentSchemaVersion)
        #expect(decoded.name == "Legacy")
    }

    @Test func exportAndImportProfileJSON() throws {
        let source = try makeHarness()
        let destination = try makeHarness()
        defer {
            source.cleanup()
            destination.cleanup()
        }

        let profile = source.store.createProfile(name: "Travel")
        let exportURL = source.baseURL.appendingPathComponent("Travel.json")
        try source.store.exportProfile(profile, to: exportURL)

        let imported = try destination.store.importProfile(from: exportURL)

        #expect(imported.name == "Travel")
        #expect(destination.store.profiles.count == 1)
    }

    private func makeHarness() throws -> Harness {
        let baseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProfileStoreTests-\(UUID().uuidString)", isDirectory: true)
        let paths = AppSupportPaths(baseURL: baseURL)
        let store = ProfileStore(appSupportPaths: paths, now: { Date(timeIntervalSince1970: 100) })
        return Harness(baseURL: baseURL, paths: paths, store: store)
    }

    private struct Harness {
        let baseURL: URL
        let paths: AppSupportPaths
        let store: ProfileStore

        func cleanup() {
            try? FileManager.default.removeItem(at: baseURL)
        }
    }
}

@Suite("ProfileEditorView")
@MainActor
struct ProfileEditorViewTests {
    @Test func targetZoneTextSortsByBundleIdentifier() {
        let text = ProfileEditorView.text(from: [
            "com.example.sync": .hidden,
            "com.example.clock": .visible,
            "com.example.deep": .alwaysHidden
        ])

        #expect(text == """
        com.example.clock=visible
        com.example.deep=alwaysHidden
        com.example.sync=hidden
        """)
    }

    @Test func targetZoneParserTrimsInputAndSkipsInvalidLines() {
        let zones = ProfileEditorView.zones(from: """
         com.example.sync = hidden
        missing-separator
        com.example.bad = unsupported
        com.example.deep=alwaysHidden
        =visible
        """)

        #expect(zones == [
            "com.example.sync": .hidden,
            "com.example.deep": .alwaysHidden
        ])
    }
}
