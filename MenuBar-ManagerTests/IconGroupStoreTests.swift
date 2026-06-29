import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("IconGroupStore")
@MainActor
struct IconGroupStoreTests {
    private func makeTempDir() -> URL {
        let temp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("GroupTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        return temp
    }

    @Test func saveAndLoad() {
        let dir = makeTempDir()
        let backups = dir.appendingPathComponent("backups", isDirectory: true)
        let store = IconGroupStore(directory: dir, backupsDirectory: backups)

        let group1 = store.createGroup(name: "Work Apps")
        let group2 = store.createGroup(name: "System Items")

        store.addItem(to: group1.id, ref: IconGroupItemRef(bundleIdentifier: "com.example.app1"))
        store.addItem(to: group2.id, ref: IconGroupItemRef(bundleIdentifier: "com.example.app2"))

        let newStore = IconGroupStore(directory: dir, backupsDirectory: backups)
        newStore.load()

        #expect(newStore.groups.count == 2)
        #expect(newStore.groups[0].name == "Work Apps")
        #expect(newStore.groups[0].itemRefs.count == 1)
        #expect(newStore.groups[1].name == "System Items")
    }

    @Test func corruptedJSONRecovers() {
        let dir = makeTempDir()
        let backups = dir.appendingPathComponent("backups", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let fileURL = dir.appendingPathComponent("groups.json")
        try? "{ invalid json }".data(using: .utf8)!.write(to: fileURL)

        let store = IconGroupStore(directory: dir, backupsDirectory: backups)
        store.load()

        #expect(store.groups.isEmpty)
    }

    @Test func resetClearsGroups() {
        let dir = makeTempDir()
        let backups = dir.appendingPathComponent("backups", isDirectory: true)
        let store = IconGroupStore(directory: dir, backupsDirectory: backups)

        _ = store.createGroup(name: "Test")
        #expect(store.groupCount == 1)

        store.reset()
        #expect(store.groupCount == 0)
    }
}

@Suite("IconGroupMatcher")
struct IconGroupMatcherTests {
    @Test func matchByBundleIdentifier() {
        let matcher = IconGroupMatcher()
        let ref = IconGroupItemRef(bundleIdentifier: "com.example.app")
        let snapshot = MenuBarItemSnapshot(
            title: "Test",
            role: "AXButton",
            subrole: nil,
            frame: nil,
            owningProcessIdentifier: 1234,
            owningApplicationName: "TestApp",
            bundleIdentifier: "com.example.app",
            zone: .visible,
            isLikelySystemItem: false,
            scanTimestamp: Date()
        )

        let matches = matcher.match(ref: ref, snapshots: [snapshot])
        #expect(matches.count == 1)
        #expect(matches.first?.bundleIdentifier == "com.example.app")
    }

    @Test func matchBySnapshotStableID() {
        let matcher = IconGroupMatcher()
        let snapshot = MenuBarItemSnapshot(
            title: "Test",
            role: "AXButton",
            subrole: nil,
            frame: nil,
            owningProcessIdentifier: 1234,
            owningApplicationName: "TestApp",
            bundleIdentifier: nil,
            zone: .visible,
            isLikelySystemItem: false,
            scanTimestamp: Date()
        )
        let ref = IconGroupItemRef(snapshotStableID: snapshot.id)

        let matches = matcher.match(ref: ref, snapshots: [snapshot])
        #expect(matches.count == 1)
    }

    @Test func matchUnavailableItem() {
        let matcher = IconGroupMatcher()
        let ref = IconGroupItemRef(bundleIdentifier: "com.nonexistent.app")
        let snapshot = MenuBarItemSnapshot(
            title: "Test",
            role: "AXButton",
            subrole: nil,
            frame: nil,
            owningProcessIdentifier: 1234,
            owningApplicationName: "TestApp",
            bundleIdentifier: "com.different.app",
            zone: .visible,
            isLikelySystemItem: false,
            scanTimestamp: Date()
        )

        let matches = matcher.match(ref: ref, snapshots: [snapshot])
        #expect(matches.isEmpty)
    }
}

@Suite("IconGroupValidation")
struct IconGroupValidationTests {
    @Test func rejectsEmptyName() {
        let group = IconGroup(name: "")
        let errors = IconGroupValidation.validateSingle(group, existingGroups: [])
        #expect(errors.contains(.emptyName))
    }

    @Test func rejectsDuplicateName() {
        let group1 = IconGroup(name: "Test")
        let group2 = IconGroup(name: "test")
        let errors = IconGroupValidation.validateSingle(group2, existingGroups: [group1])
        #expect(errors.contains(.duplicateName))
    }

    @Test func acceptsValidGroup() {
        let group = IconGroup(name: "My Group")
        let errors = IconGroupValidation.validateSingle(group, existingGroups: [])
        #expect(errors.isEmpty)
    }
}
