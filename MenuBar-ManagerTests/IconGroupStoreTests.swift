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

@Suite("IconGroupSnapshotResolver")
struct IconGroupSnapshotResolverTests {
    @Test func matchedSnapshotsAreUniqueAndPreserveOrder() {
        let resolver = IconGroupSnapshotResolver()
        let first = makeSnapshot(id: "cloud-1", bundleIdentifier: "com.example.cloud")
        let second = makeSnapshot(id: "vpn-1", bundleIdentifier: "com.example.vpn")
        let group = IconGroup(
            name: "Utilities",
            itemRefs: [
                IconGroupItemRef(bundleIdentifier: "com.example.cloud"),
                IconGroupItemRef(snapshotStableID: "cloud-1"),
                IconGroupItemRef(bundleIdentifier: "com.example.vpn")
            ]
        )

        let matches = resolver.matchedSnapshots(for: group, snapshots: [first, second])

        #expect(matches.map(\.id) == ["cloud-1", "vpn-1"])
    }

    @Test func searchQueryMatchesLocalizedSnapshotText() {
        let resolver = IconGroupSnapshotResolver()
        let cafe = makeSnapshot(
            id: "cafe-1",
            title: "Café Sync",
            appName: "Menu Utility",
            bundleIdentifier: "com.example.cafe"
        )
        let vpn = makeSnapshot(
            id: "vpn-1",
            title: "Tunnel",
            appName: "VPN Client",
            bundleIdentifier: "com.example.vpn"
        )
        let group = IconGroup(
            name: "Utilities",
            itemRefs: [
                IconGroupItemRef(bundleIdentifier: "com.example.cafe"),
                IconGroupItemRef(bundleIdentifier: "com.example.vpn")
            ]
        )

        let matches = resolver.matchedSnapshots(
            for: group,
            snapshots: [cafe, vpn],
            searchQuery: "cafe"
        )

        #expect(matches.map(\.id) == ["cafe-1"])
    }

    @Test func revealPlanPrefersRevealAllWhenAnyMatchIsAlwaysHidden() {
        let resolver = IconGroupSnapshotResolver()
        let hidden = makeSnapshot(id: "hidden-1", bundleIdentifier: "com.example.hidden", zone: .hidden)
        let alwaysHidden = makeSnapshot(
            id: "always-hidden-1",
            bundleIdentifier: "com.example.always-hidden",
            zone: .alwaysHidden
        )
        let group = IconGroup(
            name: "Protected",
            itemRefs: [
                IconGroupItemRef(bundleIdentifier: "com.example.hidden"),
                IconGroupItemRef(bundleIdentifier: "com.example.always-hidden")
            ]
        )

        let plan = resolver.revealPlan(for: group, snapshots: [hidden, alwaysHidden])

        #expect(plan == .revealAllHiddenItems)
    }

    @Test func revealPlanDistinguishesHiddenVisibleAndUnavailableGroups() {
        let resolver = IconGroupSnapshotResolver()
        let visible = makeSnapshot(id: "visible-1", bundleIdentifier: "com.example.visible", zone: .visible)
        let hidden = makeSnapshot(id: "hidden-1", bundleIdentifier: "com.example.hidden", zone: .hidden)

        #expect(resolver.revealPlan(for: [visible]) == .noRevealNeeded)
        #expect(resolver.revealPlan(for: [hidden]) == .expandHiddenZone)
        #expect(resolver.revealPlan(for: []) == .noMatchingItems)
    }

    private func makeSnapshot(
        id: String,
        title: String? = "Sync",
        appName: String? = "Cloud Sync",
        bundleIdentifier: String?,
        zone: MenuBarZone = .hidden
    ) -> MenuBarItemSnapshot {
        MenuBarItemSnapshot(
            id: id,
            title: title,
            role: "AXMenuBarItem",
            subrole: nil,
            frame: nil,
            owningProcessIdentifier: 42,
            owningApplicationName: appName,
            bundleIdentifier: bundleIdentifier,
            zone: zone,
            isLikelySystemItem: false,
            scanTimestamp: Date(timeIntervalSince1970: 1)
        )
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

@Suite("IconGroupImportExport")
struct IconGroupImportExportTests {
    @Test func protectedGroupExportRedactsByDefault() throws {
        let protectedGroup = IconGroup(
            name: "Secret VPN",
            notes: "private notes",
            isProtected: true,
            showAsStatusItem: true,
            itemRefs: [
                IconGroupItemRef(
                    bundleIdentifier: "com.example.secret-vpn",
                    appName: "Secret VPN",
                    titleContains: "Private Tunnel",
                    manualLabel: "Secret VPN"
                )
            ]
        )

        let data = try IconGroupImportExport.exportGroup(protectedGroup)
        let json = String(decoding: data, as: UTF8.self)

        #expect(!json.contains("Secret VPN"))
        #expect(!json.contains("private notes"))
        #expect(!json.contains("com.example.secret-vpn"))
        #expect(!json.contains("Private Tunnel"))

        let container = try decodeContainer(data)
        #expect(container.schemaVersion == IconGroupImportExport.exportSchemaVersion)
        #expect(container.groups.first?.name == "Protected Group")
        #expect(container.groups.first?.itemRefs.isEmpty == true)
        #expect(container.groups.first?.isProtected == true)
        #expect(container.groups.first?.showAsStatusItem == false)
    }

    @Test func explicitUnredactedExportPreservesProtectedGroupDetails() throws {
        let protectedGroup = IconGroup(
            name: "Secret VPN",
            notes: "private notes",
            isProtected: true,
            itemRefs: [
                IconGroupItemRef(bundleIdentifier: "com.example.secret-vpn")
            ]
        )

        let data = try IconGroupImportExport.exportGroup(
            protectedGroup,
            redactionMode: .unredacted
        )
        let json = String(decoding: data, as: UTF8.self)

        #expect(json.contains("Secret VPN"))
        #expect(json.contains("private notes"))
        #expect(json.contains("com.example.secret-vpn"))
    }

    @Test func importRejectsUnsupportedSchemaVersion() throws {
        let container = IconGroupContainer(
            schemaVersion: IconGroupImportExport.exportSchemaVersion + 1,
            groups: []
        )
        let data = try encodeContainer(container)

        do {
            _ = try IconGroupImportExport.importReport(from: data)
            Issue.record("Expected unsupported schema version error.")
        } catch let error as IconGroupImportExport.ImportExportError {
            #expect(error == .unsupportedSchemaVersion(IconGroupImportExport.exportSchemaVersion + 1))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func importNormalizesRefsAndReportsWarnings() throws {
        let group = IconGroup(
            name: " Cloud ",
            itemRefs: [
                IconGroupItemRef(bundleIdentifier: " com.example.cloud ", manualLabel: " Cloud "),
                IconGroupItemRef(manualLabel: "Label Only")
            ]
        )
        let container = IconGroupContainer(
            schemaVersion: IconGroupImportExport.exportSchemaVersion,
            groups: [group]
        )

        let report = try IconGroupImportExport.importReport(from: encodeContainer(container))

        #expect(report.groups.count == 1)
        #expect(report.groups[0].name == "Cloud")
        #expect(report.groups[0].itemRefs.count == 1)
        #expect(report.groups[0].itemRefs[0].bundleIdentifier == "com.example.cloud")
        #expect(report.warnings.contains(IconGroupImportExport.ImportWarning(
            kind: .removedUnmatchableItemRefs,
            count: 1
        )))
    }

    private func encodeContainer(_ container: IconGroupContainer) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(container)
    }

    private func decodeContainer(_ data: Data) throws -> IconGroupContainer {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(IconGroupContainer.self, from: data)
    }
}

@Suite("IconGroupItemActionPlanner")
struct IconGroupItemActionPlannerTests {
    @Test func itemRefUsesSnapshotIdentityWithoutScreenData() {
        let snapshot = makeSnapshot()

        let ref = IconGroupItemActionPlanner.itemRef(from: snapshot)

        #expect(ref.bundleIdentifier == "com.example.cloud")
        #expect(ref.appName == "Cloud Sync")
        #expect(ref.snapshotStableID == snapshot.id)
        #expect(ref.titleContains == "Sync")
        #expect(ref.zone == .hidden)
        #expect(ref.manualLabel == "Cloud Sync")
    }

    @Test func defaultGroupNameAvoidsExistingNames() {
        let snapshot = makeSnapshot(appName: "Cloud Sync")
        let existing = [
            IconGroup(name: "Cloud Sync"),
            IconGroup(name: "Cloud Sync 2")
        ]

        let name = IconGroupItemActionPlanner.defaultGroupName(
            for: snapshot,
            existingGroups: existing
        )

        #expect(name == "Cloud Sync 3")
    }

    @Test func addingSnapshotSkipsStableIDDuplicate() {
        let snapshot = makeSnapshot()
        let group = IconGroup(
            name: "Cloud",
            itemRefs: [IconGroupItemRef(snapshotStableID: snapshot.id)]
        )

        let result = IconGroupItemActionPlanner.adding(snapshot: snapshot, to: group)

        #expect(!result.didAdd)
        #expect(result.group.itemRefs.count == 1)
    }

    @Test func addingSnapshotSkipsBundleIdentifierDuplicate() {
        let snapshot = makeSnapshot(bundleIdentifier: "com.example.cloud")
        let group = IconGroup(
            name: "Cloud",
            itemRefs: [IconGroupItemRef(bundleIdentifier: "COM.EXAMPLE.CLOUD")]
        )

        let result = IconGroupItemActionPlanner.adding(snapshot: snapshot, to: group)

        #expect(!result.didAdd)
        #expect(result.group.itemRefs.count == 1)
    }

    @Test func addingSnapshotAppendsNewRef() {
        let snapshot = makeSnapshot()
        let group = IconGroup(name: "Cloud")

        let result = IconGroupItemActionPlanner.adding(snapshot: snapshot, to: group)

        #expect(result.didAdd)
        #expect(result.group.itemRefs.count == 1)
        #expect(result.group.itemRefs[0].bundleIdentifier == "com.example.cloud")
    }

    private func makeSnapshot(
        title: String? = "Sync",
        appName: String? = "Cloud Sync",
        bundleIdentifier: String? = "com.example.cloud",
        zone: MenuBarZone = .hidden
    ) -> MenuBarItemSnapshot {
        MenuBarItemSnapshot(
            title: title,
            role: "AXMenuBarItem",
            subrole: nil,
            frame: nil,
            owningProcessIdentifier: 42,
            owningApplicationName: appName,
            bundleIdentifier: bundleIdentifier,
            zone: zone,
            isLikelySystemItem: false,
            scanTimestamp: Date(timeIntervalSince1970: 1)
        )
    }
}
