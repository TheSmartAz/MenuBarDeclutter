import SwiftUI

struct ProSecondBarSetupChecklistView: View {
    @Bindable var settingsStore: SettingsStore
    var permissionService: AccessibilityPermissionService?
    var screenCapturePermissionService: ScreenCapturePermissionService?
    var iconCaptureCoordinator: MenuBarIconCaptureCoordinator?
    var scanCoordinator: MenuBarScanCoordinator?
    var onChange: (() -> Void)? = nil

    @State private var feedback: ProSecondBarSetupFeedback?

    private var setupPlan: ProSecondBarSetupPlanResult {
        ProSecondBarSetupPlan.evaluate(ProSecondBarReadinessInput(
            entitlement: settingsStore.proModeEnabled ? .licensed : .basic,
            accessibilityDiscoveryEnabled: settingsStore.accessibilityDiscoveryEnabled,
            accessibilityPermission: permissionService?.status ?? .notRequested,
            accurateIconsEnabled: settingsStore.renderedIconCaptureEnabled,
            screenCapturePermission: screenCapturePermissionService?.status ?? .notGranted
        ))
    }

    var body: some View {
        ClearGlassSection("Pro Second Bar Setup", subtitle: "Compact Second Bar stays blocked until every required private-access step is ready.") {
            ClearGlassInlineMessage(
                text: setupPlan.readiness.state.message,
                systemImage: setupPlan.isReady ? "checkmark.shield" : "exclamationmark.triangle",
                style: setupPlan.isReady ? .success : .warning
            )

            ForEach(setupPlan.steps) { step in
                ClearGlassDivider()

                ProSecondBarSetupStepRow(
                    step: step,
                    isActionEnabled: step.action.map(isActionEnabled) ?? false,
                    perform: perform
                )
            }

            ClearGlassDivider()
            accurateIconWarmUpRow

            if let feedback {
                ClearGlassDivider()

                ClearGlassInlineMessage(
                    text: feedback.text,
                    systemImage: feedback.systemImage,
                    style: feedback.style
                )
            }
        }
        .accessibilityIdentifier("proSecondBarSetup.section")
        .onAppear {
            permissionService?.refreshStatus()
            screenCapturePermissionService?.refreshStatus()
        }
    }

    private var accurateIconWarmUpRow: some View {
        ClearGlassControlRow(
            systemImage: "arrow.triangle.2.circlepath",
            title: "Warm Up Icons",
            subtitle: "Refresh rendered thumbnails for compact-strip items after permissions are ready.",
            iconTint: setupPlan.isReady ? .blue : .secondary
        ) {
            Button("Warm Up Icons", systemImage: "arrow.triangle.2.circlepath") {
                warmUpAccurateIcons()
            }
            .controlSize(.small)
            .disabled(!canWarmUpAccurateIcons)
            .help(canWarmUpAccurateIcons ? "Capture current menu bar thumbnails for Second Bar." : "Complete the Pro Second Bar setup checklist first.")
        }
        .opacity(setupPlan.isReady ? 1 : 0.72)
    }

    private var canWarmUpAccurateIcons: Bool {
        setupPlan.isReady && iconCaptureCoordinator != nil
    }

    private func isActionEnabled(_ action: ProSecondBarSetupAction) -> Bool {
        switch action {
        case .enableProMode:
            true
        case .enableAccessibilityDiscovery:
            settingsStore.proModeEnabled
        case .requestAccessibilityPermission:
            settingsStore.proModeEnabled
                && settingsStore.accessibilityDiscoveryEnabled
                && permissionService != nil
                && permissionService?.status != .granted
        case .enableAccurateIcons:
            settingsStore.proModeEnabled
                && settingsStore.accessibilityDiscoveryEnabled
                && permissionService?.status == .granted
        case .requestScreenRecordingPermission:
            settingsStore.renderedIconCaptureEnabled
                && screenCapturePermissionService != nil
                && screenCapturePermissionService?.status != .granted
        }
    }

    private func perform(_ action: ProSecondBarSetupAction) {
        switch action {
        case .enableProMode:
            PrivacyProSetupActions.enableProMode(
                settingsStore: settingsStore,
                permissionService: permissionService
            )
            feedback = ProSecondBarSetupFeedback(
                text: "Optional Pro is enabled. Continue with Accessibility Discovery.",
                systemImage: "star",
                style: .info
            )
        case .enableAccessibilityDiscovery:
            settingsStore.accessibilityDiscoveryEnabled = true
            permissionService?.refreshStatus()
            feedback = ProSecondBarSetupFeedback(
                text: "Accessibility Discovery is enabled. Request macOS Accessibility permission next.",
                systemImage: "figure.circle",
                style: .info
            )
        case .requestAccessibilityPermission:
            let status = permissionService?.requestPromptFromUserAction() ?? .unknown
            if status != .granted {
                permissionService?.openSystemSettingsPrivacyPane()
            }
            feedback = ProSecondBarSetupFeedback(
                text: status == .granted ? "Accessibility permission is granted." : "Accessibility permission is still required in System Settings. The Accessibility privacy pane has been opened.",
                systemImage: status == .granted ? "checkmark.circle" : "hand.raised",
                style: status == .granted ? .success : .warning
            )
        case .enableAccurateIcons:
            settingsStore.renderedIconCaptureEnabled = true
            screenCapturePermissionService?.refreshStatus()
            feedback = ProSecondBarSetupFeedback(
                text: "Accurate Icons is enabled. Request Screen Recording permission next.",
                systemImage: "sparkle.magnifyingglass",
                style: .info
            )
        case .requestScreenRecordingPermission:
            let status = screenCapturePermissionService?.requestPermissionFromUserAction() ?? .unknown
            if status != .granted {
                screenCapturePermissionService?.openSystemSettingsPrivacyPane()
            }
            let recoveryInstruction = status.recoveryInstruction.map { " \($0)" } ?? ""
            feedback = ProSecondBarSetupFeedback(
                text: status == .granted ? "Screen Recording permission is granted." : "Screen Recording permission is still required in System Settings. The Screen Recording privacy pane has been opened.\(recoveryInstruction)",
                systemImage: status == .granted ? "checkmark.circle" : "rectangle.on.rectangle",
                style: status == .granted ? .success : .warning
            )
        }

        notifySetupChanged()
    }

    private func warmUpAccurateIcons() {
        guard let iconCaptureCoordinator else {
            feedback = ProSecondBarSetupFeedback(
                text: "Icon capture is unavailable in this build.",
                systemImage: "exclamationmark.triangle",
                style: .warning
            )
            return
        }

        let started = iconCaptureCoordinator.warmUpSecondBarIconsIfAllowed(reason: "Pro Second Bar setup")
        feedback = ProSecondBarSetupFeedback(
            text: started ? "Icon warm-up started. Hidden items may briefly reveal, then return to their previous state." : "Icon warm-up is unavailable until Accurate Icons and Screen Recording are ready.",
            systemImage: started ? "arrow.triangle.2.circlepath" : "exclamationmark.triangle",
            style: started ? .info : .warning
        )
    }

    private func notifySetupChanged() {
        screenCapturePermissionService?.refreshStatus()
        if let onChange {
            onChange()
        } else {
            scanCoordinator?.refreshAfterSettingsChanged(reason: "Pro Second Bar setup")
        }
    }
}

private struct ProSecondBarSetupStepRow: View {
    let step: ProSecondBarSetupStep
    let isActionEnabled: Bool
    let perform: (ProSecondBarSetupAction) -> Void

    var body: some View {
        ClearGlassStepRow(
            systemImage: step.id.systemImage,
            title: step.id.title,
            subtitle: step.id.detail,
            iconTint: step.state.clearGlassStyle.tint,
            statusText: step.statusText,
            statusStyle: step.state.clearGlassStyle,
            isDimmed: step.state == .waiting
        ) {
            if let action = step.action {
                Button(action.title, systemImage: action.systemImage) {
                    perform(action)
                }
                .controlSize(.small)
                .disabled(!isActionEnabled)
            }
        }
    }
}

private struct ProSecondBarSetupFeedback: Identifiable {
    let id = UUID()
    let text: String
    let systemImage: String
    let style: ClearGlassStatusStyle
}

private extension ProSecondBarSetupStepState {
    var clearGlassStyle: ClearGlassStatusStyle {
        switch self {
        case .complete:
            .success
        case .current:
            .warning
        case .waiting:
            .secondary
        }
    }
}
