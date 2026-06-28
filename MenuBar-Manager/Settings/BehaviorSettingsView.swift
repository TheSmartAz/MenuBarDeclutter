import SwiftUI

/// Phase 2 "Behavior" section in Settings: auto-rehide, hover reveal,
/// always-hidden zone, separator visuals, global hotkey, and Option-click.
struct BehaviorSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    /// Called whenever any Phase 2 setting changes so the AppEnvironment can
    /// apply the new value to the live services.
    var onChange: (() -> Void)? = nil

    var body: some View {
        Form {
            Section("Auto-Rehide") {
                Toggle("Re-hide automatically after delay", isOn: $settingsStore.autoRehideEnabled)

                if settingsStore.autoRehideEnabled {
                    LabeledSlider(
                        "Delay (seconds)",
                        value: $settingsStore.autoRehideDelaySeconds,
                        in: 0...60,
                        step: 1,
                        sliderLabel: "Auto-rehide delay",
                        minimumValueLabel: "0s",
                        maximumValueLabel: "60s"
                    )
                }
            }

            Section("Hover Reveal") {
                Toggle("Reveal hidden items on hover", isOn: $settingsStore.hoverRevealEnabled)

                if settingsStore.hoverRevealEnabled {
                    LabeledSlider(
                        "Polling interval (seconds)",
                        value: $settingsStore.hoverRevealPollingIntervalSeconds,
                        in: AppConstants.minHoverRevealPollingIntervalSeconds...1.0,
                        step: 0.05,
                        sliderLabel: "Hover polling interval",
                        minimumValueLabel: "Fast",
                        maximumValueLabel: "Slow"
                    )
                    Text("No sensitive permissions are used for hover reveal.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Always-Hidden Zone") {
                Toggle("Enable always-hidden separator", isOn: $settingsStore.alwaysHiddenEnabled)
                Text("Adds a second separator to its right. Items beyond it stay hidden even when the primary zone is expanded.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Separator Appearance") {
                Toggle("Show separator visual marker", isOn: $settingsStore.showSeparators)
                Text("When off, separators remain in place but their icons disappear.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Click Behavior") {
                Toggle("Option-click reveals all hidden items", isOn: $settingsStore.revealAllOnOptionClick)
            }

            Section("Global Hotkey") {
                Toggle("Enable global hotkey", isOn: $settingsStore.globalHotkeyEnabled)

                if settingsStore.globalHotkeyEnabled {
                    LabeledContent("Current Hotkey") {
                        Text(settingsStore.effectiveGlobalHotkey().displayName)
                            .font(.system(.body, design: .monospaced))
                    }

                    Button("Reset to Default") {
                        settingsStore.resetGlobalHotkeyToDefault()
                        onChange?()
                    }
                }

                Text("No Accessibility, Screen Recording, Apple Events, or Input Monitoring permission is required.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onChange(of: settingsStore.autoRehideEnabled) { _, _ in onChange?() }
        .onChange(of: settingsStore.autoRehideDelaySeconds) { _, _ in onChange?() }
        .onChange(of: settingsStore.hoverRevealEnabled) { _, _ in onChange?() }
        .onChange(of: settingsStore.hoverRevealPollingIntervalSeconds) { _, _ in onChange?() }
        .onChange(of: settingsStore.alwaysHiddenEnabled) { _, _ in onChange?() }
        .onChange(of: settingsStore.showSeparators) { _, _ in onChange?() }
        .onChange(of: settingsStore.globalHotkeyEnabled) { _, _ in onChange?() }
        .onChange(of: settingsStore.globalHotkeyKeyCode) { _, _ in onChange?() }
        .onChange(of: settingsStore.globalHotkeyModifiersRaw) { _, _ in onChange?() }
        .onChange(of: settingsStore.revealAllOnOptionClick) { _, _ in onChange?() }
    }
}

#Preview {
    BehaviorSettingsView(settingsStore: SettingsStore())
}
