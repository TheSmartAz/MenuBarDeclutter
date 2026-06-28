import SwiftUI

struct SecondBarSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    var permissionService: AccessibilityPermissionService?
    var onChange: (() -> Void)? = nil
    var onOpenPrivacySettings: (() -> Void)? = nil

    var body: some View {
        Form {
            Section("Second Bar") {
                Toggle("Enable Second Bar", isOn: $settingsStore.secondBarEnabled)
                Toggle("Show hidden items", isOn: $settingsStore.secondBarShowHiddenItems)
                    .disabled(!settingsStore.secondBarEnabled)
                Toggle("Show always-hidden items", isOn: $settingsStore.secondBarShowAlwaysHiddenItems)
                    .disabled(!settingsStore.secondBarEnabled)
                Toggle("Auto-close after selection", isOn: $settingsStore.secondBarAutoCloseAfterSelection)
                    .disabled(!settingsStore.secondBarEnabled)
                Toggle("Close when clicking outside", isOn: $settingsStore.secondBarCloseOnOutsideClick)
                    .disabled(!settingsStore.secondBarEnabled)
                Toggle("Bring owning app to front after selection", isOn: $settingsStore.secondBarActivateOwningAppOnSelection)
                    .disabled(!settingsStore.secondBarEnabled)

                Text("Second Bar uses Accessibility snapshots and app bundle icons. It does not use Screen Recording or captured menu bar pixels.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Position") {
                Picker("Position", selection: $settingsStore.secondBarPositionModeRaw) {
                    ForEach(SecondBarPositionMode.allCases) { mode in
                        Text(mode.displayName)
                            .tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!settingsStore.secondBarEnabled)
            }

            Section("Appearance") {
                LabeledSlider(
                    "Icon size",
                    value: $settingsStore.secondBarIconSize,
                    in: AppConstants.minSecondBarIconSize...AppConstants.maxSecondBarIconSize,
                    step: 2,
                    valueLabelWidth: 36,
                    valueFractionLength: 0
                )
                .disabled(!settingsStore.secondBarEnabled)

                Toggle("Show labels", isOn: $settingsStore.secondBarShowLabels)
                    .disabled(!settingsStore.secondBarEnabled)
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
        .onSecondBarSettingsChanges(from: settingsStore, perform: onChange)
    }
}

#Preview {
    SecondBarSettingsView(settingsStore: SettingsStore())
}
