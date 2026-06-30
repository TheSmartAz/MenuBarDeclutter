import SwiftUI

struct PrivateAccessSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    let coordinator: PrivateAccessCoordinator?
    var commandAvailabilities: [MenuBarCommandAvailabilitySummary] = []
    var onChange: (() -> Void)?

    @State private var testStatus: String?

    var body: some View {
        ClearGlassSettingsPage(
            "Private Access",
            subtitle: "Gate sensitive app actions with LocalAuthentication. No biometric data is stored by MenuBarDeclutter.",
            badges: [.preview, .privacySafe]
        ) {
            PrivateAccessOverview(
                isEnabled: settingsStore.privateAccessEnabled,
                isUnlocked: coordinator?.isUnlocked,
                protectedCount: protectedSurfaceCount,
                allowsPasswordFallback: settingsStore.privateAccessAllowDevicePasswordFallback
            )

            lockSection
            protectedSurfacesSection
            commandCenterSection
            privacyBoundarySection
        }
    }

    private var lockSection: some View {
        ClearGlassSection("Lock", subtitle: "Authentication policy, unlock session, and test controls.") {
            FeatureGateNotice(
                .preview,
                text: "Preview in v0.1.1. Gates app actions only; not encryption or system icon hiding."
            )

            ClearGlassDivider()

            PrivateAccessLockStatePanel(
                isEnabled: settingsStore.privateAccessEnabled,
                isUnlocked: coordinator?.isUnlocked,
                unlockDurationSeconds: settingsStore.privateAccessUnlockDurationSeconds,
                lastAuthStatus: settingsStore.privateAccessLastAuthStatus
            )

            ClearGlassDivider()

            PrivateAccessToggleRow(
                systemImage: "lock.fill",
                title: "Enable Private Access",
                subtitle: "Require Touch ID or device password before protected MenuBarDeclutter actions.",
                isOn: $settingsStore.privateAccessEnabled,
                onChange: notifyChanged
            )

            ClearGlassDivider()

            PrivateAccessToggleRow(
                systemImage: "key.fill",
                title: "Allow Device Password Fallback",
                subtitle: "Use device-owner authentication when Touch ID is unavailable.",
                isOn: $settingsStore.privateAccessAllowDevicePasswordFallback,
                onChange: notifyChanged
            )

            ClearGlassDivider()

            ClearGlassSliderRow(
                "Unlock Duration",
                subtitle: "How long a successful unlock remains active.",
                value: $settingsStore.privateAccessUnlockDurationSeconds,
                in: AppConstants.minPrivateAccessUnlockDurationSeconds...AppConstants.maxPrivateAccessUnlockDurationSeconds,
                step: 30,
                valueSuffix: "s"
            )
            .onChange(of: settingsStore.privateAccessUnlockDurationSeconds) { _, _ in
                notifyChanged()
            }

            ClearGlassDivider()

            lockActionControls

            if let testStatus {
                ClearGlassDivider()
                ClearGlassInlineMessage(text: testStatus, systemImage: "info.circle")
            }

            if !settingsStore.privateAccessEnabled {
                ClearGlassDivider()
                ClearGlassInlineMessage(
                    text: "Private Access is off. Protected-surface choices are preserved, but no authentication is required until this is enabled.",
                    systemImage: "lock.open",
                    style: .secondary
                )
            }
        }
    }

    private var protectedSurfacesSection: some View {
        ClearGlassSection("Protected Surfaces", subtitle: "Choose which local app actions require an active unlock.") {
            ProtectedSurfaceToggleRow(
                systemImage: "eye.slash",
                title: "Always Hidden Reveal",
                subtitle: "Require auth before revealing the always-hidden zone.",
                isOn: $settingsStore.privateAccessProtectAlwaysHidden,
                isFeatureEnabled: settingsStore.privateAccessEnabled,
                onChange: notifyChanged
            )

            ClearGlassDivider()

            ProtectedSurfaceToggleRow(
                systemImage: "menubar.rectangle",
                title: "Second Bar",
                subtitle: "Require auth before opening Second Bar.",
                isOn: $settingsStore.privateAccessProtectSecondBar,
                isFeatureEnabled: settingsStore.privateAccessEnabled,
                onChange: notifyChanged
            )

            ClearGlassDivider()

            ProtectedSurfaceToggleRow(
                systemImage: "magnifyingglass",
                title: "Find Icon",
                subtitle: "Require auth before opening Find Icon.",
                isOn: $settingsStore.privateAccessProtectFindIcon,
                isFeatureEnabled: settingsStore.privateAccessEnabled,
                onChange: notifyChanged
            )

            ClearGlassDivider()

            ProtectedSurfaceToggleRow(
                systemImage: "arrow.up.left.and.arrow.down.right",
                title: "Icon Moving",
                subtitle: "Icon moving is protected by default because it changes menu bar organization.",
                isOn: $settingsStore.privateAccessProtectIconMoving,
                isFeatureEnabled: settingsStore.privateAccessEnabled,
                onChange: notifyChanged
            )

            ClearGlassDivider()

            ProtectedSurfaceToggleRow(
                systemImage: "testtube.2",
                title: "Spacing Labs",
                subtitle: "Protect spacing commands if Labs apply, restore, or reset operations are enabled.",
                isOn: $settingsStore.privateAccessProtectSpacingLabs,
                isFeatureEnabled: settingsStore.privateAccessEnabled,
                onChange: notifyChanged
            )

            ClearGlassDivider()

            ProtectedSurfaceToggleRow(
                systemImage: "person.crop.rectangle.stack",
                title: "Profile Apply",
                subtitle: "Require auth before applying a local profile.",
                isOn: $settingsStore.privateAccessProtectProfileApply,
                isFeatureEnabled: settingsStore.privateAccessEnabled,
                onChange: notifyChanged
            )

            ClearGlassDivider()

            ProtectedSurfaceToggleRow(
                systemImage: "sparkles.rectangle.stack",
                title: "Automation Commands",
                subtitle: "Require an active unlock before App Intents or URL automation can run protected commands.",
                isOn: $settingsStore.privateAccessProtectAutomationCommands,
                isFeatureEnabled: settingsStore.privateAccessEnabled,
                onChange: notifyChanged
            )
        }
    }

    @ViewBuilder
    private var commandCenterSection: some View {
        if !commandAvailabilities.isEmpty {
            ClearGlassSection("Command Center", subtitle: "Shared routing status for protected app actions.") {
                ForEach(Array(commandAvailabilities.enumerated()), id: \.offset) { index, summary in
                    CommandAvailabilityRow(summary: summary)

                    if index < commandAvailabilities.count - 1 {
                        ClearGlassDivider()
                    }
                }
            }
        }
    }

    private var privacyBoundarySection: some View {
        ClearGlassSection("Privacy Boundary", subtitle: "Private Access protects app actions, not external system state.") {
            PrivateAccessBoundaryGrid()

            ClearGlassDivider()

            ClearGlassInlineMessage(
                text: "Private Access gates MenuBarDeclutter actions. It is not encryption and does not hide third-party menu bar items that are already visible outside the app.",
                systemImage: "lock.shield",
                style: .info
            )
        }
    }

    private var lockActionControls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                lockButtons
                lockStatus
            }

            VStack(alignment: .leading, spacing: 8) {
                lockButtons
                lockStatus
            }
        }
        .controlSize(.small)
        .padding(.vertical, 8)
    }

    private var lockButtons: some View {
        HStack(spacing: 10) {
            Button("Test Authentication", systemImage: "touchid") {
                Task { @MainActor in
                    guard let coordinator else {
                        testStatus = "Authentication service unavailable."
                        return
                    }
                    let result = await coordinator.testAuthentication()
                    testStatus = "Authentication \(result.statusString)."
                }
            }
            .disabled(!settingsStore.privateAccessEnabled)

            Button("Clear Unlock Session", systemImage: "lock") {
                coordinator?.clearUnlock()
                testStatus = "Unlock session cleared."
            }
            .disabled(coordinator == nil)
        }
    }

    @ViewBuilder
    private var lockStatus: some View {
        if let coordinator {
            ClearGlassStatusValue(
                text: coordinator.isUnlocked ? "Unlocked" : "Locked",
                style: coordinator.isUnlocked ? .success : .secondary
            )
        } else {
            ClearGlassStatusValue(text: "Unavailable", style: .secondary)
        }
    }

    private var protectedSurfaceCount: Int {
        [
            settingsStore.privateAccessProtectAlwaysHidden,
            settingsStore.privateAccessProtectSecondBar,
            settingsStore.privateAccessProtectFindIcon,
            settingsStore.privateAccessProtectIconMoving,
            settingsStore.privateAccessProtectSpacingLabs,
            settingsStore.privateAccessProtectProfileApply,
            settingsStore.privateAccessProtectAutomationCommands
        ]
        .filter { $0 }
        .count
    }

    private func notifyChanged() {
        onChange?()
    }
}

private struct PrivateAccessOverview: View {
    let isEnabled: Bool
    let isUnlocked: Bool?
    let protectedCount: Int
    let allowsPasswordFallback: Bool

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            PrivateAccessOverviewPill(
                title: "Private Access",
                value: isEnabled ? "On" : "Off",
                systemImage: isEnabled ? "lock.fill" : "lock.open",
                style: isEnabled ? .success : .secondary
            )

            PrivateAccessOverviewPill(
                title: "Session",
                value: sessionText,
                systemImage: isUnlocked == true ? "lock.open" : "lock",
                style: sessionStyle
            )

            PrivateAccessOverviewPill(
                title: "Protected",
                value: "\(protectedCount)",
                systemImage: "shield.lefthalf.filled",
                style: protectedCount > 0 ? .info : .secondary
            )

            PrivateAccessOverviewPill(
                title: "Fallback",
                value: allowsPasswordFallback ? "Allowed" : "Touch ID",
                systemImage: "key",
                style: allowsPasswordFallback ? .info : .secondary
            )
        }
    }

    private var sessionText: String {
        guard isEnabled else { return "Inactive" }
        return isUnlocked == true ? "Unlocked" : "Locked"
    }

    private var sessionStyle: ClearGlassStatusStyle {
        guard isEnabled else { return .secondary }
        return isUnlocked == true ? .success : .warning
    }
}

private struct PrivateAccessOverviewPill: View {
    let title: String
    let value: String
    let systemImage: String
    let style: ClearGlassStatusStyle

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(style.tint)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
        }
    }
}

private struct PrivateAccessLockStatePanel: View {
    let isEnabled: Bool
    let isUnlocked: Bool?
    let unlockDurationSeconds: Double
    let lastAuthStatus: String?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                lockMetric("State", value: stateText, systemImage: stateImage, style: stateStyle)
                lockMetric("Unlock", value: unlockDurationText, systemImage: "timer", style: .secondary)
                lockMetric("Last Test", value: lastAuthText, systemImage: "touchid", style: lastAuthStyle)
            }

            VStack(alignment: .leading, spacing: 8) {
                lockMetric("State", value: stateText, systemImage: stateImage, style: stateStyle)
                lockMetric("Unlock", value: unlockDurationText, systemImage: "timer", style: .secondary)
                lockMetric("Last Test", value: lastAuthText, systemImage: "touchid", style: lastAuthStyle)
            }
        }
        .padding(.vertical, 8)
    }

    private var stateText: String {
        guard isEnabled else { return "Off" }
        return isUnlocked == true ? "Unlocked" : "Locked"
    }

    private var stateImage: String {
        isUnlocked == true ? "lock.open" : "lock"
    }

    private var stateStyle: ClearGlassStatusStyle {
        guard isEnabled else { return .secondary }
        return isUnlocked == true ? .success : .warning
    }

    private var unlockDurationText: String {
        unlockDurationSeconds.formatted(.number.precision(.fractionLength(0))) + "s"
    }

    private var lastAuthText: String {
        switch lastAuthStatus {
        case "success":
            "Success"
        case "failure":
            "Failure"
        case "cancel":
            "Canceled"
        case "unavailable":
            "Unavailable"
        default:
            "No Test"
        }
    }

    private var lastAuthStyle: ClearGlassStatusStyle {
        switch lastAuthStatus {
        case "success":
            .success
        case "failure":
            .danger
        case "cancel", "unavailable":
            .warning
        default:
            .secondary
        }
    }

    private func lockMetric(
        _ label: String,
        value: String,
        systemImage: String,
        style: ClearGlassStatusStyle
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(style.tint)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 0.5)
        }
    }
}

private struct PrivateAccessToggleRow: View {
    let systemImage: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var isEnabled = true
    var onChange: (() -> Void)?

    var body: some View {
        ClearGlassControlRow(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            iconTint: isOn ? .accentColor : .secondary
        ) {
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .disabled(!isEnabled)
                .onChange(of: isOn) { _, _ in
                    onChange?()
                }
        }
        .opacity(isEnabled ? 1 : 0.55)
    }
}

private struct ProtectedSurfaceToggleRow: View {
    let systemImage: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let isFeatureEnabled: Bool
    var onChange: (() -> Void)?

    var body: some View {
        ClearGlassControlRow(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            iconTint: isOn ? .accentColor : .secondary
        ) {
            HStack(spacing: 12) {
                ClearGlassStatusValue(
                    text: isOn ? "Protected" : "Open",
                    style: isOn ? .info : .secondary
                )

                Toggle(title, isOn: $isOn)
                    .labelsHidden()
                    .disabled(!isFeatureEnabled)
                    .onChange(of: isOn) { _, _ in
                        onChange?()
                    }
            }
        }
        .opacity(isFeatureEnabled ? 1 : 0.55)
    }
}

private struct PrivateAccessBoundaryGrid: View {
    private let columns = [
        GridItem(.adaptive(minimum: 190), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            boundaryItem(
                systemImage: "checkmark.shield",
                title: "Gates App Actions",
                detail: "Prompts before selected MenuBarDeclutter actions."
            )

            boundaryItem(
                systemImage: "lock.slash",
                title: "Not Encryption",
                detail: "Settings remain ordinary local preferences."
            )

            boundaryItem(
                systemImage: "menubar.rectangle",
                title: "Not System Hiding",
                detail: "Visible third-party menu bar items are not hidden by this lock."
            )
        }
        .padding(.vertical, 8)
    }

    private func boundaryItem(systemImage: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                    .foregroundStyle(.primary)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 0.5)
        }
    }
}

#Preview {
    PrivateAccessSettingsView(
        settingsStore: SettingsStore(),
        coordinator: nil
    )
}
