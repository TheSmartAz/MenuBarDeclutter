import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("SpacerItemStore")
@MainActor
struct SpacerItemStoreTests {
    private func makeTempDir() -> URL {
        let temp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("SpacerTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        return temp
    }

    @Test func saveAndLoad() {
        let dir = makeTempDir()
        let backups = dir.appendingPathComponent("backups", isDirectory: true)
        let store = SpacerItemStore(directory: dir, backupsDirectory: backups)

        store.add(type: .divider)
        store.add(type: .thinSpacer)
        store.add(type: .wideSpacer, title: "Gap")

        let newStore = SpacerItemStore(directory: dir, backupsDirectory: backups)
        newStore.load()

        #expect(newStore.items.count == 3)
        #expect(newStore.items[0].type == .divider)
        #expect(newStore.items[1].type == .thinSpacer)
        #expect(newStore.items[2].type == .wideSpacer)
        #expect(newStore.items[2].title == "Gap")
    }

    @Test func corruptedJSONRecovers() {
        let dir = makeTempDir()
        let backups = dir.appendingPathComponent("backups", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // Write corrupted JSON
        let fileURL = dir.appendingPathComponent("spacers.json")
        try? "{ invalid json }".data(using: .utf8)!.write(to: fileURL)

        let store = SpacerItemStore(directory: dir, backupsDirectory: backups)
        store.load()

        #expect(store.items.isEmpty)
    }

    @Test func lengthClamping() {
        let item = SpacerItemModel(type: .thinSpacer, length: 500)
        #expect(item.length == SpacerItemModel.maxLength)

        let item2 = SpacerItemModel(type: .thinSpacer, length: -10)
        #expect(item2.length == SpacerItemModel.minLength)

        let item3 = SpacerItemModel(type: .thinSpacer, length: .nan)
        #expect(item3.length == SpacerItemModel.minLength)
    }

    @Test func resetClearsItems() {
        let dir = makeTempDir()
        let backups = dir.appendingPathComponent("backups", isDirectory: true)
        let store = SpacerItemStore(directory: dir, backupsDirectory: backups)

        store.add(type: .divider)
        store.add(type: .thinSpacer)
        #expect(store.items.count == 2)

        store.reset()
        #expect(store.items.isEmpty)

        let newStore = SpacerItemStore(directory: dir, backupsDirectory: backups)
        newStore.load()
        #expect(newStore.items.isEmpty)
    }

    @Test func reorderUpdatesSortOrder() {
        let dir = makeTempDir()
        let backups = dir.appendingPathComponent("backups", isDirectory: true)
        let store = SpacerItemStore(directory: dir, backupsDirectory: backups)

        let item1 = store.add(type: .divider)
        let item2 = store.add(type: .thinSpacer)
        let item3 = store.add(type: .wideSpacer)

        // Reverse order
        store.reorder([item3, item2, item1])

        #expect(store.items[0].id == item3.id)
        #expect(store.items[0].sortOrder == 0)
        #expect(store.items[2].id == item1.id)
        #expect(store.items[2].sortOrder == 2)
    }
}

@Suite("SpacerItemModel")
struct SpacerItemModelTests {
    @Test func defaultLengthsByType() {
        #expect(SpacerItemModel(type: .divider).length == SpacerItemType.divider.defaultLength)
        #expect(SpacerItemModel(type: .thinSpacer).length == SpacerItemType.thinSpacer.defaultLength)
        #expect(SpacerItemModel(type: .wideSpacer).length == SpacerItemType.wideSpacer.defaultLength)
    }

    @Test func typeDisplayNames() {
        #expect(SpacerItemType.divider.displayName == "Divider")
        #expect(SpacerItemType.thinSpacer.displayName == "Thin Spacer")
        #expect(SpacerItemType.wideSpacer.displayName == "Wide Spacer")
    }
}
