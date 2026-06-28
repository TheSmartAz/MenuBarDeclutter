import SwiftUI

struct PrivacySettingsView: View {
    @Bindable var settingsStore: SettingsStore
    var permissionService: AccessibilityPermissionService?
    var scanCoordinator: MenuBarScanCoordinator?
    var onChange: (() -> Void)? = nil

    var body: some View {
        Form {
            Section("Basic Mode (default, fully usable)") {
                PrivacyCapabilityRow(
                    title: "Accessibility",
                    status: settingsStore.proModeEnabled ? accessibilityStatusText : "Not Requested",
                    systemImage: "hand.raised"
                )
                PrivacyCapabilityRow(
                    title: "Screen Recording",
                    status: "Not Requested",
                    systemImage: "rectangle.on.rectangle"
                )
                PrivacyCapabilityRow(
                    title: "Apple Events",
                    status: "Not Requested",
                    systemImage: "apple.terminal"
                )
                PrivacyCapabilityRow(
                    title: "Input Monitoring",
                    status: "Not Requested",
                    systemImage: "keyboard"
                )
                PrivacyCapabilityRow(
                    title: "Network Access",
                    status: "Not Used",
                    systemImage: "network"
                )

                Text("Basic Mode is fully usable without any of these permissions. Your menu bar hiding setup never sends anything off your Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Pro Mode (optional, opt-in)") {
                if settingsStore.proModeEnabled {
                    Label("Pro Mode Enabled", systemImage: "lock.open")
                        .foregroundStyle(.green)
                } else {
                    Button("Enable Pro Mode", systemImage: "lock.open") {
                        settingsStore.proModeEnabled = true
                        settingsStore.accessibilityDiscoveryEnabled = true
                        permissionService?.refreshStatus()
                        notifyPrivacyChanged()
                    }
                }

                Toggle("Accessibility Discovery", isOn: $settingsStore.accessibilityDiscoveryEnabled)
                    .disabled(!settingsStore.proModeEnabled)
                    .onChange(of: settingsStore.accessibilityDiscoveryEnabled) {
                        notifyPrivacyChanged()
                    }

                HStack {
                    PrivacyCapabilityRow(
                        title: "Accessibility",
                        status: accessibilityStatusText,
                        systemImage: "hand.raised"
                    )

                    Spacer()

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

                Stepper(
                    value: $settingsStore.menuBarScanIntervalSeconds,
                    in: AppConstants.minMenuBarScanIntervalSeconds...AppConstants.maxMenuBarScanIntervalSeconds,
                    step: 0.5
                ) {
                    Text("Scan throttle: \(settingsStore.menuBarScanIntervalSeconds, format: .number.precision(.fractionLength(1))) seconds")
                }
                .disabled(!settingsStore.proModeEnabled || !settingsStore.accessibilityDiscoveryEnabled)
                .onChange(of: settingsStore.menuBarScanIntervalSeconds) {
                    notifyPrivacyChanged()
                }

                Button("Disable Pro Mode", systemImage: "lock", role: .destructive) {
                    settingsStore.proModeEnabled = false
                    settingsStore.accessibilityDiscoveryEnabled = false
                    notifyPrivacyChanged()
                }
                .disabled(!settingsStore.proModeEnabled)

                Text("Accessibility discovery reads menu bar item frames and labels so future Pro features can support search and a second bar. It does not use screen recording, keylogging, network access, Apple Events, or Input Monitoring.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Diagnostics Export") {
                Text("The exported diagnostics bundle contains app version, macOS version, machine architecture, screen frames, current settings, and recent log messages. It excludes screenshots, screen contents, personal file paths, and network data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var accessibilityStatusText: String {
        permissionService?.status.displayName
            ?? AccessibilityPermissionStatus.notRequested.displayName
    }

    private func notifyPrivacyChanged() {
        if let onChange {
            onChange()
        } else {
            scanCoordinator?.refreshAfterSettingsChanged()
        }
    }
}

private struct PrivacyCapabilityRow: View {
    let title: String
    let status: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .frame(width: 18)
                .foregroundStyle(.secondary)

            Text(title)

            Spacer()

            Text(status)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
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
