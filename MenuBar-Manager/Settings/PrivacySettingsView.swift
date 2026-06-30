import SwiftUI

struct PrivacySettingsView: View {
    @Bindable var settingsStore: SettingsStore
    var permissionService: AccessibilityPermissionService?
    var scanCoordinator: MenuBarScanCoordinator?
    var onChange: (() -> Void)? = nil

    var body: some View {
        ClearGlassSettingsPage(
            "Privacy",
            subtitle: "Basic Mode is fully usable without sensitive permissions. Pro Mode is optional.",
            badges: [.stable, .privacySafe, .accessibilityRequired, .diagnostics]
        ) {
            PrivacyOverviewStrip(
                proModeEnabled: settingsStore.proModeEnabled,
                accessibilityStatusText: accessibilityStatusText,
                accessibilityStatusStyle: accessibilityStatusStyle
            )

            ClearGlassSection("Basic Mode", subtitle: "Fully usable without permissions.") {
                PrivacyCapabilityRow(
                    title: "Accessibility",
                    status: settingsStore.proModeEnabled ? accessibilityStatusText : "Not Requested",
                    systemImage: "hand.raised"
                )

                ClearGlassDivider()

                PrivacyCapabilityRow(
                    title: "Screen Recording",
                    status: "Not Requested",
                    systemImage: "rectangle.on.rectangle"
                )

                ClearGlassDivider()

                PrivacyCapabilityRow(
                    title: "Apple Events",
                    status: "Not Requested",
                    systemImage: "apple.terminal"
                )

                ClearGlassDivider()

                PrivacyCapabilityRow(
                    title: "Input Monitoring",
                    status: "Not Requested",
                    systemImage: "keyboard"
                )

                ClearGlassDivider()

                PrivacyCapabilityRow(
                    title: "Network Access",
                    status: "Not Used",
                    systemImage: "network"
                )

                ClearGlassInlineMessage(
                    text: "Basic Mode is fully usable without any of these permissions. Your menu bar hiding setup never sends anything off your Mac.",
                    systemImage: "checkmark.shield",
                    style: .success
                )
            }
            .accessibilityIdentifier("privacy.basicMode.section")

            ClearGlassSection("Pro Mode", subtitle: "Unlock advanced features with opt-in permissions.") {
                if settingsStore.proModeEnabled {
                    ClearGlassControlRow(
                        systemImage: "lock.open",
                        title: "Pro Mode Enabled",
                        subtitle: "Disable Pro Mode at any time.",
                        iconTint: .green
                    ) {
                        ClearGlassStatusValue(text: "Enabled", style: .success)
                    }
                } else {
                    ClearGlassControlRow(
                        systemImage: "star",
                        title: "Pro Mode",
                        subtitle: "Optional features that depend on local Accessibility discovery."
                    ) {
                        Button("Enable Pro Mode", systemImage: "lock.open") {
                            settingsStore.proModeEnabled = true
                            settingsStore.accessibilityDiscoveryEnabled = true
                            permissionService?.refreshStatus()
                            notifyPrivacyChanged()
                        }
                    }
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "figure.circle",
                    title: "Accessibility Discovery",
                    subtitle: "Read menu bar item frames and labels locally for Pro features.",
                    iconTint: .blue
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

                ClearGlassControlRow(
                    systemImage: "hand.raised",
                    title: "Accessibility",
                    subtitle: "Required only for Pro discovery, Search, and Second Bar.",
                    iconTint: accessibilityStatusStyle.tint
                ) {
                    HStack(spacing: 10) {
                        ClearGlassStatusValue(
                            text: accessibilityStatusText,
                            style: accessibilityStatusStyle
                        )

                        Button("Request Permission") {
                            permissionService?.requestPromptFromUserAction()
                            notifyPrivacyChanged()
                        }
                        .disabled(!settingsStore.proModeEnabled || permissionService?.status == .granted)

                        Button("Open Settings") {
                            permissionService?.openSystemSettingsPrivacyPane()
                        }
                        .disabled(!settingsStore.proModeEnabled)
                    }
                }
                .opacity(settingsStore.proModeEnabled ? 1 : 0.55)

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "clock",
                    title: "Scan throttle",
                    subtitle: "Reduce system impact by slowing discovery scans."
                ) {
                    HStack(spacing: 10) {
                        Text("\(settingsStore.menuBarScanIntervalSeconds, format: .number.precision(.fractionLength(1)))s")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 54, alignment: .trailing)

                        Stepper(
                            "Scan throttle",
                            value: $settingsStore.menuBarScanIntervalSeconds,
                            in: AppConstants.minMenuBarScanIntervalSeconds...AppConstants.maxMenuBarScanIntervalSeconds,
                            step: 0.5
                        )
                        .labelsHidden()
                    }
                    .disabled(!settingsStore.proModeEnabled || !settingsStore.accessibilityDiscoveryEnabled)
                }
                .opacity(settingsStore.proModeEnabled && settingsStore.accessibilityDiscoveryEnabled ? 1 : 0.55)
                .onChange(of: settingsStore.menuBarScanIntervalSeconds) {
                    notifyPrivacyChanged()
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "lock",
                    title: "Disable Pro Mode",
                    subtitle: "Turn off Pro Mode and Accessibility Discovery.",
                    iconTint: .red
                ) {
                    Button("Disable Pro Mode", systemImage: "lock", role: .destructive) {
                        settingsStore.proModeEnabled = false
                        settingsStore.accessibilityDiscoveryEnabled = false
                        notifyPrivacyChanged()
                    }
                    .disabled(!settingsStore.proModeEnabled)
                }
            }

            ClearGlassSection("Your Data Stays Local", subtitle: "All data is processed on your Mac and never leaves your device.") {
                HStack(spacing: 12) {
                    localDataStep(systemImage: "macbook", title: "Your Mac")
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                    localDataStep(systemImage: "internaldrive", title: "Local Index")
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                    localDataStep(systemImage: "network.slash", title: "No Network")
                }
                .frame(maxWidth: .infinity, alignment: .center)

                ClearGlassInlineMessage(
                    text: "Privacy by design: MenuBarDeclutter does not collect, store, or transmit personal data.",
                    systemImage: "checkmark.shield",
                    style: .success
                )
            }

            ClearGlassSection("Diagnostics Export", subtitle: "Privacy notes for support bundles.") {
                ClearGlassInlineMessage(
                    text: "The exported diagnostics bundle contains app version, macOS version, machine architecture, screen frames, current settings, and recent log messages. It excludes screenshots, screen contents, personal file paths, and network data.",
                    systemImage: "doc.zipper",
                    style: .info
                )
            }
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

    private func localDataStep(systemImage: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.callout)
                .foregroundStyle(.primary)
        }
        .frame(width: 120)
    }

    private func notifyPrivacyChanged() {
        if let onChange {
            onChange()
        } else {
            scanCoordinator?.refreshAfterSettingsChanged()
        }
    }
}

private struct PrivacyOverviewStrip: View {
    let proModeEnabled: Bool
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
                title: "Accessibility",
                value: accessibilityStatusText,
                systemImage: "hand.raised",
                style: accessibilityStatusStyle
            )

            PrivacyOverviewPill(
                title: "Network",
                value: "Not Used",
                systemImage: "network.slash",
                style: .success
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
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 1)
        }
    }
}

private struct PrivacyCapabilityRow: View {
    let title: String
    let status: String
    let systemImage: String

    var body: some View {
        ClearGlassControlRow(
            systemImage: systemImage,
            title: title,
            iconTint: .secondary
        ) {
            ClearGlassStatusValue(text: status, style: statusStyle)
        }
    }

    private var statusStyle: ClearGlassStatusStyle {
        switch status {
        case "Granted":
            .success
        case "Denied":
            .danger
        case "Unknown":
            .secondary
        default:
            .success
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
