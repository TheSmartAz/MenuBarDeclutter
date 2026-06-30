import Carbon
import Carbon.HIToolbox
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

    @Test func saveAndLoadRevealGroupAction() {
        let dir = makeTempDir()
        let backups = dir.appendingPathComponent("backups", isDirectory: true)
        let store = HotkeyBindingStore(directory: dir, backupsDirectory: backups)
        let groupID = UUID()
        let binding = HotkeyBinding(
            action: .revealGroup(groupID),
            keyCode: Int(kVK_ANSI_G),
            modifiersRaw: UInt(cmdKey) | UInt(optionKey) | UInt(shiftKey)
        )

        store.add(binding: binding)

        let newStore = HotkeyBindingStore(directory: dir, backupsDirectory: backups)
        newStore.load()

        #expect(newStore.bindings.count == 1)
        #expect(newStore.bindings[0].action == .revealGroup(groupID))
        #expect(newStore.bindings[0].label == "Reveal Group")
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

@Suite("GroupHotkeyAssignmentPlanner")
@MainActor
struct GroupHotkeyAssignmentPlannerTests {
    @Test func createsOpenGroupBindingWithFirstSuggestedShortcut() throws {
        let groupID = UUID()
        let plan = GroupHotkeyAssignmentPlanner().plan(
            groupID: groupID,
            kind: .openPanel,
            existingBindings: [],
            now: Date(timeIntervalSince1970: 1)
        )

        guard case .add(let binding) = plan.operation else {
            Issue.record("Expected planner to create a binding.")
            return
        }
        #expect(plan.result.status == .created)
        #expect(binding.action == .openGroup(groupID))
        #expect(binding.keyCode == Int(kVK_ANSI_G))
        #expect(binding.modifiersRaw == UInt(cmdKey) | UInt(optionKey))
        #expect(binding.label == "Open Group")
    }

    @Test func createsRevealGroupBindingWithShiftedSuggestedShortcut() throws {
        let groupID = UUID()
        let plan = GroupHotkeyAssignmentPlanner().plan(
            groupID: groupID,
            kind: .reveal,
            existingBindings: [],
            now: Date(timeIntervalSince1970: 1)
        )

        guard case .add(let binding) = plan.operation else {
            Issue.record("Expected planner to create a binding.")
            return
        }
        #expect(plan.result.status == .created)
        #expect(binding.action == .revealGroup(groupID))
        #expect(binding.keyCode == Int(kVK_ANSI_G))
        #expect(binding.modifiersRaw == UInt(cmdKey) | UInt(optionKey) | UInt(shiftKey))
        #expect(binding.label == "Reveal Group")
    }

    @Test func skipsConflictingSuggestedShortcut() throws {
        let existing = HotkeyBinding(
            action: .pauseAutomation,
            keyCode: Int(kVK_ANSI_G),
            modifiersRaw: UInt(cmdKey) | UInt(optionKey) | UInt(shiftKey)
        )
        let groupID = UUID()

        let plan = GroupHotkeyAssignmentPlanner().plan(
            groupID: groupID,
            kind: .reveal,
            existingBindings: [existing],
            now: Date(timeIntervalSince1970: 1)
        )

        guard case .add(let binding) = plan.operation else {
            Issue.record("Expected planner to create a fallback binding.")
            return
        }
        #expect(binding.action == .revealGroup(groupID))
        #expect(binding.keyCode == Int(kVK_F7))
        #expect(binding.modifiersRaw == UInt(cmdKey) | UInt(optionKey))
    }

    @Test func reEnablesExistingDisabledBinding() {
        let groupID = UUID()
        let existing = HotkeyBinding(
            action: .openGroup(groupID),
            keyCode: Int(kVK_ANSI_G),
            modifiersRaw: UInt(cmdKey) | UInt(optionKey),
            isEnabled: false
        )

        let plan = GroupHotkeyAssignmentPlanner().plan(
            groupID: groupID,
            kind: .openPanel,
            existingBindings: [existing]
        )

        #expect(plan.operation == .enableExisting(existing.id))
        #expect(plan.result.status == .enabledExisting)
    }

    @Test func reportsUnavailableWhenSuggestionsConflict() {
        let conflicts = [
            HotkeyBinding(action: .pauseAutomation, keyCode: Int(kVK_ANSI_G), modifiersRaw: UInt(cmdKey) | UInt(optionKey)),
            HotkeyBinding(action: .resumeAutomation, keyCode: Int(kVK_F6), modifiersRaw: UInt(cmdKey) | UInt(optionKey)),
            HotkeyBinding(action: .enterFullMenuBarMode, keyCode: Int(kVK_ANSI_G), modifiersRaw: UInt(cmdKey) | UInt(optionKey) | UInt(controlKey))
        ]

        let plan = GroupHotkeyAssignmentPlanner().plan(
            groupID: UUID(),
            kind: .openPanel,
            existingBindings: conflicts
        )

        #expect(plan.operation == .none)
        #expect(plan.result.status == .unavailable)
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

@Suite("DynamicHotkeyBindingStatusPlanner")
struct DynamicHotkeyBindingStatusPlannerTests {
    @Test func reportsDisabledBinding() {
        let binding = HotkeyBinding(
            action: .pauseAutomation,
            keyCode: 11,
            modifiersRaw: 0x0100,
            isEnabled: false
        )

        let status = DynamicHotkeyBindingStatusPlanner.status(
            for: binding,
            in: [binding],
            dynamicHotkeysEnabled: true,
            maxDynamicHotkeys: 10,
            proModeEnabled: true
        )

        #expect(status.kind == .disabled)
        #expect(!status.canRegister)
    }

    @Test func reportsRegistrationDisabled() {
        let binding = HotkeyBinding(action: .pauseAutomation, keyCode: 11, modifiersRaw: 0x0100)

        let status = DynamicHotkeyBindingStatusPlanner.status(
            for: binding,
            in: [binding],
            dynamicHotkeysEnabled: false,
            maxDynamicHotkeys: 10,
            proModeEnabled: true
        )

        #expect(status.kind == .registrationDisabled)
        #expect(!status.canRegister)
    }

    @Test func reportsEnabledConflict() {
        let first = HotkeyBinding(action: .pauseAutomation, keyCode: 11, modifiersRaw: 0x0100)
        let second = HotkeyBinding(action: .resumeAutomation, keyCode: 11, modifiersRaw: 0x0100)

        let status = DynamicHotkeyBindingStatusPlanner.status(
            for: first,
            in: [first, second],
            dynamicHotkeysEnabled: true,
            maxDynamicHotkeys: 10,
            proModeEnabled: true
        )

        #expect(status.kind == .conflict)
        #expect(!status.canRegister)
    }

    @Test func ignoresDisabledConflicts() {
        let first = HotkeyBinding(action: .pauseAutomation, keyCode: 11, modifiersRaw: 0x0100)
        let second = HotkeyBinding(
            action: .resumeAutomation,
            keyCode: 11,
            modifiersRaw: 0x0100,
            isEnabled: false
        )

        let status = DynamicHotkeyBindingStatusPlanner.status(
            for: first,
            in: [first, second],
            dynamicHotkeysEnabled: true,
            maxDynamicHotkeys: 10,
            proModeEnabled: true
        )

        #expect(status.kind == .ready)
        #expect(status.canRegister)
    }

    @Test func reportsOverLimitAfterRegisterableSlotsAreUsed() {
        let first = HotkeyBinding(action: .pauseAutomation, keyCode: 11, modifiersRaw: 0x0100)
        let second = HotkeyBinding(action: .resumeAutomation, keyCode: 12, modifiersRaw: 0x0100)

        let status = DynamicHotkeyBindingStatusPlanner.status(
            for: second,
            in: [first, second],
            dynamicHotkeysEnabled: true,
            maxDynamicHotkeys: 1,
            proModeEnabled: true
        )

        #expect(status.kind == .overLimit)
        #expect(!status.canRegister)
    }

    @Test func reportsProRequirementWithoutBlockingRegistration() {
        let binding = HotkeyBinding(action: .revealGroup(UUID()), keyCode: 11, modifiersRaw: 0x0100)

        let status = DynamicHotkeyBindingStatusPlanner.status(
            for: binding,
            in: [binding],
            dynamicHotkeysEnabled: true,
            maxDynamicHotkeys: 10,
            proModeEnabled: false
        )

        #expect(status.kind == .requiresProMode)
        #expect(status.canRegister)
    }
}
