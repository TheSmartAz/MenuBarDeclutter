import Foundation

@MainActor
protocol DynamicHotkeyManaging: AnyObject {
    func register(
        identifier: GlobalHotkeyManager.RegistrationIdentifier,
        hotkey: HotkeyModel?,
        action: @escaping () -> Void
    )
    func unregister(identifier: GlobalHotkeyManager.RegistrationIdentifier)
    func isRegistered(identifier: GlobalHotkeyManager.RegistrationIdentifier) -> Bool
}

extension GlobalHotkeyManager: DynamicHotkeyManaging {}

@MainActor
struct DynamicHotkeyRegistrationSnapshot: Equatable, Sendable {
    var attemptedCount: Int
    var registeredCount: Int
    var conflictCount: Int
    var skippedCount: Int
    var lastAction: String?
}

@MainActor
final class DynamicHotkeyRegistrationService {
    private let settingsStore: SettingsStore
    private let bindingStore: HotkeyBindingStore
    private weak var hotkeyManager: (any DynamicHotkeyManaging)?
    private let protectedActionGate: ProtectedActionGate?
    private let diagnosticsLogger: DiagnosticsLogger
    private let performAction: (HotkeyAction) async -> Bool

    private var registeredBindingIDs: Set<UUID> = []
    private(set) var lastSnapshot = DynamicHotkeyRegistrationSnapshot(
        attemptedCount: 0,
        registeredCount: 0,
        conflictCount: 0,
        skippedCount: 0,
        lastAction: nil
    )

    init(
        settingsStore: SettingsStore,
        bindingStore: HotkeyBindingStore,
        hotkeyManager: any DynamicHotkeyManaging,
        protectedActionGate: ProtectedActionGate? = nil,
        diagnosticsLogger: DiagnosticsLogger,
        performAction: @escaping (HotkeyAction) async -> Bool
    ) {
        self.settingsStore = settingsStore
        self.bindingStore = bindingStore
        self.hotkeyManager = hotkeyManager
        self.protectedActionGate = protectedActionGate
        self.diagnosticsLogger = diagnosticsLogger
        self.performAction = performAction
    }

    func refreshRegistrations() {
        unregisterAll()

        guard settingsStore.dynamicHotkeysEnabled else {
            updateSnapshot(attempted: 0, registered: 0, conflicts: 0, skipped: bindingStore.enabledCount)
            diagnosticsLogger.log("Dynamic hotkeys disabled.", level: .debug, category: .hotkey)
            return
        }

        let enabledBindings = bindingStore.bindings.filter(\.isEnabled)
        let conflicts = Set(HotkeyConflictDetector.detectConflicts(in: enabledBindings).flatMap { [$0.0.id, $0.1.id] })
        let maxCount = max(0, settingsStore.maxDynamicHotkeys)
        var registeredCount = 0
        var skippedCount = 0

        for binding in enabledBindings {
            guard registeredCount < maxCount else {
                skippedCount += 1
                continue
            }

            guard !conflicts.contains(binding.id) else {
                skippedCount += 1
                continue
            }

            let identifier = GlobalHotkeyManager.RegistrationIdentifier.dynamic(binding.id)
            let model = HotkeyModel(keyCode: UInt32(binding.keyCode), modifiersRaw: UInt32(binding.modifiersRaw))
            hotkeyManager?.register(identifier: identifier, hotkey: model) { [weak self] in
                guard let self else { return }
                Task { @MainActor in
                    await self.handle(binding: binding)
                }
            }
            registeredBindingIDs.insert(binding.id)
            registeredCount += 1
        }

        updateSnapshot(
            attempted: enabledBindings.count,
            registered: registeredCount,
            conflicts: conflicts.count,
            skipped: skippedCount
        )
        diagnosticsLogger.log(
            "Dynamic hotkey registration refreshed: \(registeredCount) registered, \(conflicts.count) conflict target(s), \(skippedCount) skipped.",
            category: .hotkey
        )
    }

    func unregisterAll() {
        for id in registeredBindingIDs {
            hotkeyManager?.unregister(identifier: .dynamic(id))
        }
        registeredBindingIDs.removeAll()
    }

    private func handle(binding: HotkeyBinding) async {
        lastSnapshot.lastAction = redactedLabel(for: binding)
        diagnosticsLogger.log("Dynamic hotkey fired: \(redactedLabel(for: binding)).", category: .hotkey)

        let resource = protectedResource(for: binding.action)
        if let protectedActionGate, let resource {
            _ = await protectedActionGate.execute(
                resource: resource,
                reason: "Unlock to run \(binding.action.displayLabel)."
            ) {
                Task { @MainActor in
                    _ = await self.performAction(binding.action)
                }
            }
        } else {
            _ = await performAction(binding.action)
        }
    }

    private func protectedResource(for action: HotkeyAction) -> ProtectedResource? {
        switch action {
        case .revealAndHighlightItem:
            .findIcon
        case .openGroup(let id), .openSecondBarFilteredToGroup(let id):
            .protectedGroup(id)
        case .openSecondBarFilteredToItem:
            .secondBar
        case .applyProfile:
            .profileApply
        case .enterFullMenuBarMode, .exitFullMenuBarMode, .pauseAutomation, .resumeAutomation:
            nil
        }
    }

    private func redactedLabel(for binding: HotkeyBinding) -> String {
        switch binding.action {
        case .openGroup, .openSecondBarFilteredToGroup:
            "Protected/group hotkey"
        case .revealAndHighlightItem, .openSecondBarFilteredToItem:
            "Item hotkey"
        default:
            binding.label
        }
    }

    private func updateSnapshot(attempted: Int, registered: Int, conflicts: Int, skipped: Int) {
        lastSnapshot.attemptedCount = attempted
        lastSnapshot.registeredCount = registered
        lastSnapshot.conflictCount = conflicts
        lastSnapshot.skippedCount = skipped
    }
}
