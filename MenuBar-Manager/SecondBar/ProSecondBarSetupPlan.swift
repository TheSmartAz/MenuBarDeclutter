import Foundation

nonisolated enum ProSecondBarSetupStepID: String, CaseIterable, Identifiable, Sendable {
    case proMode
    case accessibilityDiscovery
    case accessibilityPermission
    case accurateIcons
    case screenRecording

    var id: String { rawValue }

    var title: String {
        switch self {
        case .proMode:
            "Optional Pro"
        case .accessibilityDiscovery:
            "Accessibility Discovery"
        case .accessibilityPermission:
            "Accessibility Permission"
        case .accurateIcons:
            "Accurate Icons"
        case .screenRecording:
            "Screen Recording"
        }
    }

    var detail: String {
        switch self {
        case .proMode:
            "Opt in before private-access features can run."
        case .accessibilityDiscovery:
            "Allow local discovery of menu bar item labels and frames."
        case .accessibilityPermission:
            "Grant macOS Accessibility permission from an explicit button press."
        case .accurateIcons:
            "Enable rendered menu bar thumbnails for compact-strip icons."
        case .screenRecording:
            "Grant macOS Screen Recording for Accurate Icons capture."
        }
    }

    var systemImage: String {
        switch self {
        case .proMode:
            "star"
        case .accessibilityDiscovery:
            "figure.circle"
        case .accessibilityPermission:
            "hand.raised"
        case .accurateIcons:
            "sparkle.magnifyingglass"
        case .screenRecording:
            "rectangle.on.rectangle"
        }
    }
}

nonisolated enum ProSecondBarSetupStepState: String, Equatable, Sendable {
    case complete
    case current
    case waiting

    var isActionable: Bool { self == .current }
}

nonisolated enum ProSecondBarSetupAction: String, Equatable, Sendable {
    case enableProMode
    case enableAccessibilityDiscovery
    case requestAccessibilityPermission
    case enableAccurateIcons
    case requestScreenRecordingPermission

    var title: String {
        switch self {
        case .enableProMode:
            "Enable Pro"
        case .enableAccessibilityDiscovery:
            "Enable Discovery"
        case .requestAccessibilityPermission:
            "Request Permission"
        case .enableAccurateIcons:
            "Enable Icons"
        case .requestScreenRecordingPermission:
            "Request Permission"
        }
    }

    var systemImage: String {
        switch self {
        case .enableProMode:
            "star"
        case .enableAccessibilityDiscovery:
            "figure.circle"
        case .requestAccessibilityPermission:
            "hand.raised"
        case .enableAccurateIcons:
            "sparkle.magnifyingglass"
        case .requestScreenRecordingPermission:
            "rectangle.on.rectangle"
        }
    }
}

nonisolated struct ProSecondBarSetupStep: Identifiable, Equatable, Sendable {
    let id: ProSecondBarSetupStepID
    let state: ProSecondBarSetupStepState
    let statusText: String
    let action: ProSecondBarSetupAction?

    var isSatisfied: Bool { state == .complete }
}

nonisolated struct ProSecondBarSetupPlanResult: Equatable, Sendable {
    let readiness: ProSecondBarReadinessResult
    let steps: [ProSecondBarSetupStep]

    var isReady: Bool { readiness.isReady }
    var firstAction: ProSecondBarSetupAction? { steps.first(where: { $0.action != nil })?.action }
}

nonisolated enum ProSecondBarSetupPlan {
    static func evaluate(_ input: ProSecondBarReadinessInput) -> ProSecondBarSetupPlanResult {
        let readiness = ProSecondBarReadiness.evaluate(input)
        let satisfiedByStep: [ProSecondBarSetupStepID: Bool] = [
            .proMode: input.entitlement.isActive,
            .accessibilityDiscovery: input.accessibilityDiscoveryEnabled,
            .accessibilityPermission: input.accessibilityPermission == .granted,
            .accurateIcons: input.accurateIconsEnabled,
            .screenRecording: input.screenCapturePermission == .granted
        ]
        let firstUnsatisfiedID = ProSecondBarSetupStepID.allCases.first { satisfiedByStep[$0] != true }

        let steps = ProSecondBarSetupStepID.allCases.map { stepID in
            let isSatisfied = satisfiedByStep[stepID] == true
            let state: ProSecondBarSetupStepState
            if isSatisfied {
                state = .complete
            } else if stepID == firstUnsatisfiedID {
                state = .current
            } else {
                state = .waiting
            }

            return ProSecondBarSetupStep(
                id: stepID,
                state: state,
                statusText: statusText(for: stepID, input: input, isSatisfied: isSatisfied),
                action: state.isActionable ? action(for: stepID) : nil
            )
        }

        return ProSecondBarSetupPlanResult(readiness: readiness, steps: steps)
    }

    private static func action(for stepID: ProSecondBarSetupStepID) -> ProSecondBarSetupAction {
        switch stepID {
        case .proMode:
            .enableProMode
        case .accessibilityDiscovery:
            .enableAccessibilityDiscovery
        case .accessibilityPermission:
            .requestAccessibilityPermission
        case .accurateIcons:
            .enableAccurateIcons
        case .screenRecording:
            .requestScreenRecordingPermission
        }
    }

    private static func statusText(
        for stepID: ProSecondBarSetupStepID,
        input: ProSecondBarReadinessInput,
        isSatisfied: Bool
    ) -> String {
        guard !isSatisfied else { return "Ready" }

        switch stepID {
        case .proMode:
            return "Off"
        case .accessibilityDiscovery:
            return "Off"
        case .accessibilityPermission:
            return accessibilityStatusText(input.accessibilityPermission)
        case .accurateIcons:
            return "Off"
        case .screenRecording:
            return screenCaptureStatusText(input.screenCapturePermission)
        }
    }

    private static func accessibilityStatusText(_ status: AccessibilityPermissionStatus) -> String {
        switch status {
        case .notRequested:
            "Not Requested"
        case .denied:
            "Denied"
        case .granted:
            "Granted"
        case .unknown:
            "Unknown"
        }
    }

    private static func screenCaptureStatusText(_ status: ScreenCapturePermissionStatus) -> String {
        switch status {
        case .granted:
            "Granted"
        case .notGranted:
            "Not Granted"
        case .unknown:
            "Unknown"
        }
    }
}
