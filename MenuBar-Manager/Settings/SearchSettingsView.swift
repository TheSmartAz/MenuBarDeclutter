import SwiftUI

struct SearchSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    var permissionService: AccessibilityPermissionService?
    var onChange: (() -> Void)? = nil
    var onOpenPrivacySettings: (() -> Void)? = nil

    var body: some View {
        Form {
            Section("Find Icon") {
                Toggle("Enable Find Icon", isOn: $settingsStore.searchEnabled)

                Toggle("Reveal item when selected", isOn: $settingsStore.searchRevealOnSelection)
                    .disabled(!settingsStore.searchEnabled)

                Toggle("Highlight selected item", isOn: $settingsStore.searchHighlightOnSelection)
                    .disabled(!settingsStore.searchEnabled)

                Text("Find Icon uses the local Accessibility discovery index only after Pro Mode is enabled. It does not click, drag, record the screen, or use the network.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Search Hotkey") {
                Toggle("Enable Find Icon hotkey", isOn: $settingsStore.searchHotkeyEnabled)
                    .disabled(!settingsStore.searchEnabled)

                if settingsStore.searchHotkeyEnabled {
                    LabeledContent("Current Hotkey") {
                        Text(settingsStore.effectiveSearchHotkey().displayName)
                            .font(.system(.body, design: .monospaced))
                    }

                    Button("Reset to Default") {
                        settingsStore.resetSearchHotkeyToDefault()
                        onChange?()
                    }
                }

                Text("Default: Option + Command + F. The hotkey is disabled until you turn it on.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Requirements") {
                SearchRequirementRow(
                    title: "Pro Mode",
                    status: settingsStore.proModeEnabled ? "Enabled" : "Disabled",
                    isSatisfied: settingsStore.proModeEnabled
                )
                SearchRequirementRow(
                    title: "Accessibility Discovery",
                    status: settingsStore.accessibilityDiscoveryEnabled ? "Enabled" : "Disabled",
                    isSatisfied: settingsStore.accessibilityDiscoveryEnabled
                )
                SearchRequirementRow(
                    title: "Accessibility Permission",
                    status: permissionService?.status.displayName ?? AccessibilityPermissionStatus.notRequested.displayName,
                    isSatisfied: permissionService?.status == .granted
                )

                Button("Open Privacy Settings") {
                    onOpenPrivacySettings?()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onSearchSettingsChanges(from: settingsStore, perform: onChange)
    }
}

struct SearchRequirementRow: View {
    let title: String
    let status: String
    let isSatisfied: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSatisfied ? "checkmark.circle" : "circle")
                .frame(width: 18)
                .foregroundStyle(isSatisfied ? .green : .secondary)

            Text(title)

            Spacer()

            Text(status)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SearchSettingsView(settingsStore: SettingsStore())
}
