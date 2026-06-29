import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("HotkeyBindingStore")
@MainActor
struct HotkeyBindingStoreTests {
    private func makeTempDir() -> URL {
        let temp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("HotkeyTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        return temp
    }

    @Test func saveAndLoad() {
        let dir = makeTempDir()
        let backups = dir.appendingPathComponent("backups", isDirectory: true)
        let store = HotkeyBindingStore(directory: dir, backupsDirectory: backups)

        let binding = HotkeyBinding(action: .enterFullMenuBarMode, keyCode: 11, modifiersRaw: 0x0100 | 0x0800)
        store.add(binding: binding)

        let newStore = HotkeyBindingStore(directory: dir, backupsDirectory: backups)
        newStore.load()

        #expect(newStore.bindings.count == 1)
        #expect(newStore.bindings[0].keyCode == 11)
        #expect(newStore.bindings[0].action == .enterFullMenuBarMode)
    }

    @Test func corruptedJSONRecovers() {
        let dir = makeTempDir()
        let backups = dir.appendingPathComponent("backups", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let fileURL = dir.appendingPathComponent("hotkeys.json")
        try? "{ invalid }".data(using: .utf8)!.write(to: fileURL)

        let store = HotkeyBindingStore(directory: dir, backupsDirectory: backups)
        store.load()

        #expect(store.bindings.isEmpty)
    }

    @Test func resetClearsBindings() {
        let dir = makeTempDir()
        let backups = dir.appendingPathComponent("backups", isDirectory: true)
        let store = HotkeyBindingStore(directory: dir, backupsDirectory: backups)

        store.add(binding: HotkeyBinding(action: .pauseAutomation, keyCode: 1, modifiersRaw: 0))
        #expect(store.count == 1)

        store.reset()
        #expect(store.count == 0)
    }
}

@Suite("HotkeyConflictDetector")
struct HotkeyConflictDetectorTests {
    @Test func detectsConflictingBindings() {
        let binding1 = HotkeyBinding(action: .pauseAutomation, keyCode: 11, modifiersRaw: 0x0100)
        let binding2 = HotkeyBinding(action: .resumeAutomation, keyCode: 11, modifiersRaw: 0x0100)

        let conflicts = HotkeyConflictDetector.detectConflicts(in: [binding1, binding2])
        #expect(conflicts.count == 1)
    }

    @Test func noConflictForDifferentKeys() {
        let binding1 = HotkeyBinding(action: .pauseAutomation, keyCode: 11, modifiersRaw: 0x0100)
        let binding2 = HotkeyBinding(action: .resumeAutomation, keyCode: 12, modifiersRaw: 0x0100)

        let conflicts = HotkeyConflictDetector.detectConflicts(in: [binding1, binding2])
        #expect(conflicts.isEmpty)
    }

    @Test func wouldConflictDetectsNewBinding() {
        let existing = HotkeyBinding(action: .pauseAutomation, keyCode: 11, modifiersRaw: 0x0100)
        let newBinding = HotkeyBinding(action: .resumeAutomation, keyCode: 11, modifiersRaw: 0x0100)

        #expect(HotkeyConflictDetector.wouldConflict(newBinding, in: [existing]))
    }

    @Test func noConflictForSameBinding() {
        let binding = HotkeyBinding(action: .pauseAutomation, keyCode: 11, modifiersRaw: 0x0100)

        #expect(!HotkeyConflictDetector.wouldConflict(binding, in: [binding]))
    }
}
