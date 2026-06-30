import Carbon
import Carbon.HIToolbox
import Foundation

nonisolated enum GroupHotkeyAssignmentKind: Equatable, Sendable {
    case openPanel
    case reveal

    func action(for groupID: UUID) -> HotkeyAction {
        switch self {
        case .openPanel:
            .openGroup(groupID)
        case .reveal:
            .revealGroup(groupID)
        }
    }

    var displayName: String {
        switch self {
        case .openPanel:
            "Open Group"
        case .reveal:
            "Reveal Group"
        }
    }
}

nonisolated struct GroupHotkeyAssignmentResult: Equatable, Sendable {
    enum Status: Equatable, Sendable {
        case created
        case enabledExisting
        case alreadyAssigned
        case unavailable
    }

    let status: Status
    let message: String
}

nonisolated struct GroupHotkeyAssignmentPlan: Equatable, Sendable {
    enum Operation: Equatable, Sendable {
        case add(HotkeyBinding)
        case enableExisting(UUID)
        case none
    }

    let operation: Operation
    let result: GroupHotkeyAssignmentResult
}

@MainActor
struct GroupHotkeyAssignmentPlanner {
    func plan(
        groupID: UUID,
        kind: GroupHotkeyAssignmentKind,
        existingBindings: [HotkeyBinding],
        now: Date = Date()
    ) -> GroupHotkeyAssignmentPlan {
        let action = kind.action(for: groupID)

        if let existing = existingBindings.first(where: { $0.action == action }) {
            let hotkeyName = displayName(for: existing)
            if existing.isEnabled {
                return GroupHotkeyAssignmentPlan(
                    operation: .none,
                    result: GroupHotkeyAssignmentResult(
                        status: .alreadyAssigned,
                        message: "\(kind.displayName) hotkey already exists: \(hotkeyName)."
                    )
                )
            }

            return GroupHotkeyAssignmentPlan(
                operation: .enableExisting(existing.id),
                result: GroupHotkeyAssignmentResult(
                    status: .enabledExisting,
                    message: "\(kind.displayName) hotkey re-enabled: \(hotkeyName)."
                )
            )
        }

        for suggestion in suggestions(for: kind) {
            let binding = HotkeyBinding(
                action: action,
                keyCode: suggestion.keyCode,
                modifiersRaw: suggestion.modifiersRaw,
                label: action.displayLabel,
                createdAt: now,
                updatedAt: now
            )
            guard !HotkeyConflictDetector.wouldConflict(binding, in: existingBindings) else {
                continue
            }

            return GroupHotkeyAssignmentPlan(
                operation: .add(binding),
                result: GroupHotkeyAssignmentResult(
                    status: .created,
                    message: "\(kind.displayName) hotkey assigned: \(displayName(for: binding))."
                )
            )
        }

        return GroupHotkeyAssignmentPlan(
            operation: .none,
            result: GroupHotkeyAssignmentResult(
                status: .unavailable,
                message: "No suggested \(kind.displayName.lowercased()) shortcut is available."
            )
        )
    }

    private func suggestions(for kind: GroupHotkeyAssignmentKind) -> [HotkeySuggestion] {
        switch kind {
        case .openPanel:
            [
                HotkeySuggestion(keyCode: Int(kVK_ANSI_G), modifiersRaw: Self.commandOption),
                HotkeySuggestion(keyCode: Int(kVK_F6), modifiersRaw: Self.commandOption),
                HotkeySuggestion(keyCode: Int(kVK_ANSI_G), modifiersRaw: Self.commandOptionControl)
            ]
        case .reveal:
            [
                HotkeySuggestion(keyCode: Int(kVK_ANSI_G), modifiersRaw: Self.commandOptionShift),
                HotkeySuggestion(keyCode: Int(kVK_F7), modifiersRaw: Self.commandOption),
                HotkeySuggestion(keyCode: Int(kVK_ANSI_G), modifiersRaw: Self.commandOptionShiftControl)
            ]
        }
    }

    private func displayName(for binding: HotkeyBinding) -> String {
        HotkeyModel(
            keyCode: UInt32(binding.keyCode),
            modifiersRaw: UInt32(binding.modifiersRaw)
        )
        .displayName
    }

    private static let commandOption = UInt(cmdKey) | UInt(optionKey)
    private static let commandOptionControl = UInt(cmdKey) | UInt(optionKey) | UInt(controlKey)
    private static let commandOptionShift = UInt(cmdKey) | UInt(optionKey) | UInt(shiftKey)
    private static let commandOptionShiftControl = UInt(cmdKey) | UInt(optionKey) | UInt(shiftKey) | UInt(controlKey)
}

private struct HotkeySuggestion {
    let keyCode: Int
    let modifiersRaw: UInt
}
