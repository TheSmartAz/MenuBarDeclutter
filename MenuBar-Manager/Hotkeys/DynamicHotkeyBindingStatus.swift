import Foundation

nonisolated enum DynamicHotkeyBindingStatusKind: Equatable, Sendable {
    case ready
    case disabled
    case registrationDisabled
    case conflict
    case overLimit
    case requiresProMode
}

nonisolated struct DynamicHotkeyBindingStatus: Equatable, Sendable {
    let kind: DynamicHotkeyBindingStatusKind
    let message: String
    let systemImage: String
    let isWarning: Bool

    var canRegister: Bool {
        switch kind {
        case .ready, .requiresProMode:
            true
        case .disabled, .registrationDisabled, .conflict, .overLimit:
            false
        }
    }
}

nonisolated struct DynamicHotkeyBindingStatusPlanner {
    static func status(
        for binding: HotkeyBinding,
        in bindings: [HotkeyBinding],
        dynamicHotkeysEnabled: Bool,
        maxDynamicHotkeys: Int,
        proModeEnabled: Bool
    ) -> DynamicHotkeyBindingStatus {
        guard binding.isEnabled else {
            return DynamicHotkeyBindingStatus(
                kind: .disabled,
                message: "Disabled. Enable to register.",
                systemImage: "pause.circle",
                isWarning: false
            )
        }

        guard dynamicHotkeysEnabled else {
            return DynamicHotkeyBindingStatus(
                kind: .registrationDisabled,
                message: "Dynamic hotkeys are off.",
                systemImage: "keyboard.badge.ellipsis",
                isWarning: true
            )
        }

        let enabledBindings = bindings.filter(\.isEnabled)
        let conflictIDs = Set(HotkeyConflictDetector.detectConflicts(in: enabledBindings).flatMap { [$0.0.id, $0.1.id] })
        if conflictIDs.contains(binding.id) {
            return DynamicHotkeyBindingStatus(
                kind: .conflict,
                message: "Shortcut conflict. This binding will not register.",
                systemImage: "exclamationmark.triangle",
                isWarning: true
            )
        }

        if registeredSlotIndex(for: binding, in: enabledBindings, conflictIDs: conflictIDs) >= max(0, maxDynamicHotkeys) {
            return DynamicHotkeyBindingStatus(
                kind: .overLimit,
                message: "Over the registration limit. Raise the maximum or disable another binding.",
                systemImage: "number.circle",
                isWarning: true
            )
        }

        if binding.action.requiresProMode && !proModeEnabled {
            return DynamicHotkeyBindingStatus(
                kind: .requiresProMode,
                message: "Registers, but the action requires Optional Pro to run.",
                systemImage: "lock",
                isWarning: true
            )
        }

        return DynamicHotkeyBindingStatus(
            kind: .ready,
            message: "Ready to register.",
            systemImage: "checkmark.circle",
            isWarning: false
        )
    }

    private static func registeredSlotIndex(
        for binding: HotkeyBinding,
        in enabledBindings: [HotkeyBinding],
        conflictIDs: Set<UUID>
    ) -> Int {
        var index = 0
        for candidate in enabledBindings {
            guard !conflictIDs.contains(candidate.id) else { continue }
            if candidate.id == binding.id {
                return index
            }
            index += 1
        }
        return index
    }
}
