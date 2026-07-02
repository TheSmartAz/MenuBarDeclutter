import SwiftUI

struct PrivacySettingsView: View {
    @Bindable var settingsStore: SettingsStore
    var permissionService: AccessibilityPermissionService?
    var scanCoordinator: MenuBarScanCoordinator?
    var onChange: (() -> Void)? = nil

    var body: some View {
        ClearGlassSettingsPage(
            "Privacy",
            subtitle: "Basic Mode stays permission-free. Pro Mode is opt-in and only uses local Accessibility discovery.",
            badges: [.stable, .privacySafe, .basicMode]
        ) {
            PrivacyStatusOverview(
                proModeEnabled: settingsStore.proModeEnabled,
                accessibilityDiscoveryEnabled: settingsStore.accessibilityDiscoveryEnabled,
                accessibilityStatusText: accessibilityStatusText,
                accessibilityStatusStyle: accessibilityStatusStyle
            )

            basicModeSection
            proModeSection
            localDataSection
            diagnosticsSection
        }
    }

    private var basicModeSection: some View {
        ClearGlassSection("Basic Mode Privacy", subtitle: "Fully usable without elevated permissions or network access.") {
            PrivacyPermissionRow(
                systemImage: "hand.raised",
                title: "Accessibility",
                subtitle: "Basic Mode never asks to inspect other apps or menu bar item metadata.",
                status: "Not Requested",
                style: .success
            )

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "rectangle.on.rectangle",
                title: "Screen Recording",
                subtitle: "No screenshots, screen contents, or pixel capture are used.",
                status: "Not Requested",
                style: .success
            )

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "apple.terminal",
                title: "Apple Events",
                subtitle: "MenuBarDeclutter does not control other applications in Basic Mode.",
                status: "Not Requested",
                style: .success
            )

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "keyboard",
                title: "Input Monitoring",
                subtitle: "The global shortcut path does not require keyboard monitoring permission.",
                status: "Not Requested",
                style: .success
            )

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "network.slash",
                title: "Network Access",
                subtitle: "No telemetry, sync, analytics, or remote lookup is performed.",
                status: "Not Used",
                style: .success
            )

            ClearGlassDivider()

            ClearGlassInlineMessage(
                text: "Basic Mode continues to work when every Pro capability is off, unavailable, or denied.",
                systemImage: "checkmark.shield",
                style: .success
            )
        }
        .accessibilityIdentifier("privacy.basicMode.section")
    }

    private var proModeSection: some View {
        ClearGlassSection("Optional Pro Discovery", subtitle: "Local menu bar metadata stays behind explicit Pro Mode controls.") {
            PrivacyProModeRow(
                isEnabled: settingsStore.proModeEnabled,
                enableAction: enableProMode
            )

            ClearGlassDivider()

            ClearGlassInlineMessage(
                text: "Setup is explicit: enable Pro Mode, turn on Accessibility Discovery, request permission from your own button press, rescan, then confirm Find & Rescue availability.",
                systemImage: "list.bullet.rectangle",
                style: .info
            )

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "figure.circle",
                title: "Accessibility Discovery",
                subtitle: "Read menu bar item frames and labels locally for Search, Second Bar, and layout diagnostics.",
                status: settingsStore.accessibilityDiscoveryEnabled ? "Enabled" : "Disabled",
                style: settingsStore.accessibilityDiscoveryEnabled ? .info : .secondary
            ) {
                Toggle("Accessibility Discovery", isOn: $settingsStore.accessibilityDiscoveryEnabled)
                    .labelsHidden()
                    .disabled(!settingsStore.proModeEnabled)
                    .onChange(of: settingsStore.accessibilityDiscoveryEnabled) {
                        notifyPrivacyChanged()
                    }
            }
            .opacity(settingsStore.proModeEnabled ? 1 : 0.55)

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "hand.raised",
                title: "Accessibility Permission",
                subtitle: "Required only when Pro discovery is enabled. The prompt is shown only from an explicit Request Permission button.",
                status: accessibilityStatusText,
                style: accessibilityStatusStyle
            ) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        accessibilityButtons
                    }

                    VStack(alignment: .trailing, spacing: 8) {
                        accessibilityButtons
                    }
                }
            }
            .opacity(settingsStore.proModeEnabled ? 1 : 0.55)

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "arrow.clockwise",
                title: "Rescan",
                subtitle: "Refresh local menu bar metadata after changing Pro or Accessibility settings.",
                status: canRequestRescan ? "Available" : "Unavailable",
                style: canRequestRescan ? .info : .secondary
            ) {
                Button("Rescan", systemImage: "arrow.clockwise") {
                    scanCoordinator?.requestManualRefresh()
                }
                .controlSize(.small)
                .disabled(!canRequestRescan)
            }
            .opacity(settingsStore.proModeEnabled ? 1 : 0.55)

            ClearGlassDivider()

            PrivacyScanThrottleRow(
                value: $settingsStore.menuBarScanIntervalSeconds,
                isEnabled: settingsStore.proModeEnabled && settingsStore.accessibilityDiscoveryEnabled
            )
            .onChange(of: settingsStore.menuBarScanIntervalSeconds) {
                notifyPrivacyChanged()
            }

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "lock",
                title: "Disable Pro Mode",
                subtitle: "Turns off Pro Mode and Accessibility Discovery. Basic Mode remains available.",
                status: settingsStore.proModeEnabled ? "Available" : "Disabled",
                style: settingsStore.proModeEnabled ? .warning : .secondary
            ) {
                Button("Disable Pro Mode", systemImage: "lock", role: .destructive) {
                    PrivacyProSetupActions.disableProMode(settingsStore: settingsStore)
                    notifyPrivacyChanged()
                }
                .disabled(!settingsStore.proModeEnabled)
            }

            if showsProModeMessage {
                ClearGlassDivider()
                proModeMessage
            }
        }
    }

    private var accessibilityButtons: some View {
        Group {
            Button("Request Permission", systemImage: "hand.raised") {
                permissionService?.requestPromptFromUserAction()
                notifyPrivacyChanged()
            }
            .disabled(!settingsStore.proModeEnabled || permissionService == nil || permissionService?.status == .granted)

            Button("Open Settings", systemImage: "gearshape") {
                permissionService?.openSystemSettingsPrivacyPane()
            }
            .disabled(!settingsStore.proModeEnabled || permissionService == nil)
        }
        .controlSize(.small)
    }

    @ViewBuilder
    private var proModeMessage: some View {
        if !settingsStore.proModeEnabled {
            ClearGlassInlineMessage(
                text: "Pro Mode controls are inactive. No Accessibility prompt is requested while Pro Mode is off.",
                systemImage: "lock",
                style: .secondary
            )
        } else if !settingsStore.accessibilityDiscoveryEnabled {
            ClearGlassInlineMessage(
                text: "Pro Mode is on, but discovery is disabled. Pro features degrade to their unavailable state until discovery is enabled.",
                systemImage: "pause.circle",
                style: .warning
            )
        } else if permissionService?.status == .denied {
            ClearGlassInlineMessage(
                text: "Accessibility is denied in System Settings. Pro discovery remains unavailable, but Basic Mode keeps working.",
                systemImage: "exclamationmark.triangle",
                style: .warning
            )
        } else if permissionService?.status == .granted {
            ClearGlassInlineMessage(
                text: "Accessibility is granted for local Pro discovery. Screen Recording, Apple Events, Input Monitoring, and network access are still not used here.",
                systemImage: "checkmark.shield",
                style: .success
            )
        }
    }

    private var showsProModeMessage: Bool {
        !settingsStore.proModeEnabled
            || !settingsStore.accessibilityDiscoveryEnabled
            || permissionService?.status == .denied
            || permissionService?.status == .granted
    }

    private var canRequestRescan: Bool {
        settingsStore.proModeEnabled
            && settingsStore.accessibilityDiscoveryEnabled
            && permissionService?.status == .granted
            && scanCoordinator != nil
    }

    private var localDataSection: some View {
        ClearGlassSection("Local Data Path", subtitle: "The app keeps its processing path on this Mac.") {
            PrivacyLocalDataFlow()

            ClearGlassDivider()

            ClearGlassInlineMessage(
                text: "MenuBarDeclutter does not collect, store, or transmit personal data. Local settings and diagnostics stay on disk unless you export them.",
                systemImage: "checkmark.shield",
                style: .success
            )
        }
    }

    private var diagnosticsSection: some View {
        ClearGlassSection("Diagnostics Export", subtitle: "Support bundles avoid sensitive visual or network data.") {
            PrivacyPermissionRow(
                systemImage: "doc.zipper",
                title: "Export Contents",
                subtitle: "Includes app version, macOS version, architecture, screen frames, current settings, and recent log messages.",
                status: "Local File",
                style: .info
            )

            ClearGlassDivider()

            PrivacyPermissionRow(
                systemImage: "eye.slash",
                title: "Excluded Data",
                subtitle: "Screenshots, screen contents, personal file paths, and network payloads are excluded.",
                status: "Excluded",
                style: .success
            )
        }
    }

    private var accessibilityStatusText: String {
        permissionService?.status.displayName
            ?? AccessibilityPermissionStatus.notRequested.displayName
    }

    private var accessibilityStatusStyle: ClearGlassStatusStyle {
        switch permissionService?.status ?? .notRequested {
        case .granted:
            .success
        case .denied:
            .danger
        case .notRequested:
            .warning
        case .unknown:
            .secondary
        }
    }

    private func enableProMode() {
        PrivacyProSetupActions.enableProMode(
            settingsStore: settingsStore,
            permissionService: permissionService
        )
        notifyPrivacyChanged()
    }

    private func notifyPrivacyChanged() {
        if let onChange {
            onChange()
        } else {
            scanCoordinator?.refreshAfterSettingsChanged()
        }
    }
}

@MainActor
enum PrivacyProSetupActions {
    static func enableProMode(
        settingsStore: SettingsStore,
        permissionService: AccessibilityPermissionService?
    ) {
        settingsStore.proModeEnabled = true
        permissionService?.refreshStatus()
    }

    static func disableProMode(settingsStore: SettingsStore) {
        settingsStore.proModeEnabled = false
        settingsStore.accessibilityDiscoveryEnabled = false
    }
}

private struct PrivacyStatusOverview: View {
    let proModeEnabled: Bool
    let accessibilityDiscoveryEnabled: Bool
    let accessibilityStatusText: String
    let accessibilityStatusStyle: ClearGlassStatusStyle

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            PrivacyOverviewPill(
                title: "Basic Mode",
                value: "Ready",
                systemImage: "checkmark.shield",
                style: .success
            )

            PrivacyOverviewPill(
                title: "Pro Mode",
                value: proModeEnabled ? "On" : "Off",
                systemImage: "star",
                style: proModeEnabled ? .info : .secondary
            )

            PrivacyOverviewPill(
                title: "Discovery",
                value: accessibilityDiscoveryEnabled ? "On" : "Off",
                systemImage: "figure.circle",
                style: accessibilityDiscoveryEnabled ? .info : .secondary
            )

            PrivacyOverviewPill(
                title: "Accessibility",
                value: accessibilityStatusText,
                systemImage: "hand.raised",
                style: accessibilityStatusStyle
            )
        }
    }
}

private struct PrivacyOverviewPill: View {
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

private struct PrivacyProModeRow: View {
    let isEnabled: Bool
    let enableAction: () -> Void

    var body: some View {
        PrivacyPermissionRow(
            systemImage: isEnabled ? "lock.open" : "star",
            title: isEnabled ? "Pro Mode Enabled" : "Pro Mode",
            subtitle: isEnabled
                ? "Advanced features can use local Accessibility discovery when discovery and permission are available."
                : "Enable only when you want Pro features that inspect menu bar metadata locally.",
            status: isEnabled ? "Enabled" : "Off",
            style: isEnabled ? .success : .secondary
        ) {
            if isEnabled {
                ClearGlassStatusValue(text: "Enabled", style: .success)
            } else {
                Button("Enable Pro Mode", systemImage: "lock.open", action: enableAction)
                    .controlSize(.small)
            }
        }
    }
}

private struct PrivacyPermissionRow<Accessory: View>: View {
    let systemImage: String
    let title: String
    let subtitle: String
    let status: String
    let style: ClearGlassStatusStyle
    @ViewBuilder let accessory: Accessory

    init(
        systemImage: String,
        title: String,
        subtitle: String,
        status: String,
        style: ClearGlassStatusStyle = .secondary,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.status = status
        self.style = style
        self.accessory = accessory()
    }

    var body: some View {
        ClearGlassControlRow(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            iconTint: style.tint
        ) {
            HStack(spacing: 12) {
                ClearGlassStatusValue(text: status, style: style)
                accessory
            }
        }
    }
}

private extension PrivacyPermissionRow where Accessory == EmptyView {
    init(
        systemImage: String,
        title: String,
        subtitle: String,
        status: String,
        style: ClearGlassStatusStyle = .secondary
    ) {
        self.init(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            status: status,
            style: style
        ) {
            EmptyView()
        }
    }
}

private struct PrivacyScanThrottleRow: View {
    @Binding var value: Double
    let isEnabled: Bool

    var body: some View {
        ClearGlassControlRow(
            systemImage: "clock",
            title: "Scan Throttle",
            subtitle: "Slow local discovery scans to reduce system impact.",
            iconTint: isEnabled ? .secondary : .secondary
        ) {
            HStack(spacing: 10) {
                Text(value, format: .number.precision(.fractionLength(1)))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 38, alignment: .trailing)

                Text("s")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Stepper(
                    "Scan Throttle",
                    value: $value,
                    in: AppConstants.minMenuBarScanIntervalSeconds...AppConstants.maxMenuBarScanIntervalSeconds,
                    step: 0.5
                )
                .labelsHidden()
            }
            .disabled(!isEnabled)
        }
        .opacity(isEnabled ? 1 : 0.55)
    }
}

private struct PrivacyLocalDataFlow: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                dataNode(systemImage: "macbook", title: "Your Mac", detail: "Settings")
                flowArrow
                dataNode(systemImage: "internaldrive", title: "Local Index", detail: "On disk")
                flowArrow
                dataNode(systemImage: "network.slash", title: "No Network", detail: "No telemetry")
            }
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .leading, spacing: 8) {
                dataNode(systemImage: "macbook", title: "Your Mac", detail: "Settings")
                dataNode(systemImage: "internaldrive", title: "Local Index", detail: "On disk")
                dataNode(systemImage: "network.slash", title: "No Network", detail: "No telemetry")
            }
        }
        .padding(.vertical, 8)
    }

    private var flowArrow: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(.tertiary)
    }

    private func dataNode(systemImage: String, title: String, detail: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color(nsColor: .textBackgroundColor))

                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.callout)
                    .foregroundStyle(.primary)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(minWidth: 170, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 0.5)
        }
    }
}

#Preview {
    PrivacySettingsPreviewFactory.make()
}

private enum PrivacySettingsPreviewFactory {
    @MainActor
    static func make() -> PrivacySettingsView {
        let store = SettingsStore()
        let logger = DiagnosticsLogger()
        let permissionService = AccessibilityPermissionService(
            settingsStore: store,
            diagnosticsLogger: logger,
            trustProvider: { false },
            promptTrustProvider: { false },
            systemSettingsOpener: { true }
        )
        return PrivacySettingsView(
            settingsStore: store,
            permissionService: permissionService,
            scanCoordinator: nil
        )
    }
}
