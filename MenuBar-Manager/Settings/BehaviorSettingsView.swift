import SwiftUI

/// Phase 2 "Behavior" section in Settings: auto-rehide, hover reveal,
/// always-hidden zone, separator visuals, global hotkey, and Option-click.
struct BehaviorSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    /// Called whenever any Phase 2 setting changes so the AppEnvironment can
    /// apply the new value to the live services.
    var onChange: (() -> Void)? = nil

    var body: some View {
        ClearGlassSettingsPage(
            "Behavior",
            subtitle: "Tune the Basic Mode interactions that hide and reveal menu bar items.",
            badges: [.privacySafe]
        ) {
            ClearGlassSection("Auto-Rehide", subtitle: "Automatically rehide shown items after a delay.") {
                ClearGlassControlRow(
                    systemImage: "clock",
                    title: "Re-hide automatically after delay",
                    subtitle: "Collapse again after you reveal hidden items."
                ) {
                    Toggle("Re-hide automatically after delay", isOn: $settingsStore.autoRehideEnabled)
                        .labelsHidden()
                }

                if settingsStore.autoRehideEnabled {
                    ClearGlassDivider()

                    ClearGlassSliderRow(
                        "Delay",
                        value: $settingsStore.autoRehideDelaySeconds,
                        in: 0...60,
                        step: 1,
                        valueSuffix: "s",
                        valueFractionLength: 0
                    )
                }
            }

            ClearGlassSection("Hover Reveal", subtitle: "Reveal hidden items while hovering near the menu bar.") {
                ClearGlassControlRow(
                    systemImage: "eye",
                    title: "Reveal hidden items on hover",
                    subtitle: "Temporarily expand the bar when hover reveal is active."
                ) {
                    Toggle("Reveal hidden items on hover", isOn: $settingsStore.hoverRevealEnabled)
                        .labelsHidden()
                }

                if settingsStore.hoverRevealEnabled {
                    ClearGlassDivider()

                    ClearGlassSliderRow(
                        "Polling Interval",
                        subtitle: "Lower values feel more responsive and use slightly more CPU.",
                        value: $settingsStore.hoverRevealPollingIntervalSeconds,
                        in: AppConstants.minHoverRevealPollingIntervalSeconds...1.0,
                        step: 0.05,
                        valueSuffix: "s",
                        valueFractionLength: 2
                    )
                }

                ClearGlassInlineMessage(
                    text: "No sensitive permissions are used for hover reveal.",
                    systemImage: "checkmark.shield",
                    style: .success
                )
            }

            ClearGlassSection("Always-Hidden Zone", subtitle: "Keep selected items hidden even when the main group is revealed.") {
                ClearGlassControlRow(
                    systemImage: "square.dashed",
                    title: "Enable always-hidden separator",
                    subtitle: "Adds a second separator to the right. Items beyond it stay hidden when the primary zone expands."
                ) {
                    Toggle("Enable always-hidden separator", isOn: $settingsStore.alwaysHiddenEnabled)
                        .labelsHidden()
                }

                if settingsStore.alwaysHiddenEnabled {
                    ClearGlassDivider()
                    AlwaysHiddenZonePreview()
                }
            }

            ClearGlassSection("Separator Appearance", subtitle: "Control the visible marker for menu bar separators.") {
                ClearGlassControlRow(
                    systemImage: "parallelpipe",
                    title: "Show separator visual marker",
                    subtitle: "When off, separators remain in place but their icons disappear."
                ) {
                    Toggle("Show separator visual marker", isOn: $settingsStore.showSeparators)
                        .labelsHidden()
                }
            }

            ClearGlassSection("Click Behavior", subtitle: "Shortcut behavior for quickly revealing hidden items.") {
                ClearGlassControlRow(
                    systemImage: "cursorarrow.click",
                    title: "Option-click reveals all hidden items",
                    subtitle: "Temporarily reveal both primary hidden items and always-hidden items."
                ) {
                    Toggle("Option-click reveals all hidden items", isOn: $settingsStore.revealAllOnOptionClick)
                        .labelsHidden()
                }
            }

            ClearGlassSection("Global Hotkey", subtitle: "Show or hide all hidden items using a keyboard shortcut.") {
                ClearGlassControlRow(
                    systemImage: "keyboard",
                    title: "Enable global hotkey",
                    subtitle: "The hotkey works without Accessibility, Screen Recording, Apple Events, or Input Monitoring."
                ) {
                    Toggle("Enable global hotkey", isOn: $settingsStore.globalHotkeyEnabled)
                        .labelsHidden()
                }

                if settingsStore.globalHotkeyEnabled {
                    ClearGlassDivider()

                    ClearGlassValueRow("Current Hotkey") {
                        HStack(spacing: 10) {
                            Text(settingsStore.effectiveGlobalHotkey().displayName)
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(.thinMaterial, in: .rect(cornerRadius: 7))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 7)
                                        .stroke(.primary.opacity(0.12), lineWidth: 1)
                                }

                            Button("Reset to Default") {
                                settingsStore.resetGlobalHotkeyToDefault()
                                onChange?()
                            }
                        }
                    }
                }
            }
        }
        .onBehaviorSettingsChanges(from: settingsStore, perform: onChange)
    }
}

private struct AlwaysHiddenZonePreview: View {
    private let icons = ["apple.logo", "wifi", "battery.100", "cloud", "moon", "speaker.wave.2"]

    var body: some View {
        HStack(spacing: 10) {
            Text("Left Zone")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 14) {
                ForEach(icons, id: \.self) { icon in
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: .rect(cornerRadius: 7))
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(.primary.opacity(0.12), lineWidth: 1)
            }

            Text("Right Zone")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    BehaviorSettingsView(settingsStore: SettingsStore())
}
