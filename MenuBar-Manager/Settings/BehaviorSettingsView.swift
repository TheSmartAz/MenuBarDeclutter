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
            subtitle: "Control how hidden menu bar items reveal, collapse, and respond to shortcuts.",
            badges: [.stable, .privacySafe]
        ) {
            BehaviorSummaryStrip(settingsStore: settingsStore)

            ClearGlassSection("Reveal", subtitle: "Choose how hidden items temporarily come back into view.") {
                ClearGlassControlRow(
                    systemImage: "clock",
                    title: "Re-hide after reveal",
                    subtitle: "Collapse hidden items again after a short delay."
                ) {
                    Toggle("Re-hide after reveal", isOn: $settingsStore.autoRehideEnabled)
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

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "eye",
                    title: "Reveal on hover",
                    subtitle: "Show hidden items while the pointer is near the menu bar."
                ) {
                    Toggle("Reveal on hover", isOn: $settingsStore.hoverRevealEnabled)
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
                    text: "Reveal behavior stays in Basic Mode and does not use Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.",
                    systemImage: "checkmark.shield",
                    style: .success
                )
            }

            ClearGlassSection("Hidden Zones", subtitle: "Keep sensitive or noisy items separate from the main reveal group.") {
                ClearGlassControlRow(
                    systemImage: "square.dashed",
                    title: "Always-hidden zone",
                    subtitle: "Items beyond the second separator stay hidden when the primary zone expands."
                ) {
                    Toggle("Always-hidden zone", isOn: $settingsStore.alwaysHiddenEnabled)
                        .labelsHidden()
                }

                if settingsStore.alwaysHiddenEnabled {
                    ClearGlassDivider()
                    AlwaysHiddenZonePreview()
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "cursorarrow.click",
                    title: "Option-click reveals all",
                    subtitle: "Temporarily reveal both primary hidden items and always-hidden items."
                ) {
                    Toggle("Option-click reveals all", isOn: $settingsStore.revealAllOnOptionClick)
                        .labelsHidden()
                }
            }

            ClearGlassSection("Separators", subtitle: "Control the visible marker for app-owned separator items.") {
                ClearGlassControlRow(
                    systemImage: "parallelpipe",
                    title: "Show separator markers",
                    subtitle: "When off, separators remain in place but their icons disappear."
                ) {
                    Toggle("Show separator markers", isOn: $settingsStore.showSeparators)
                        .labelsHidden()
                }
            }

            ClearGlassSection("Keyboard Shortcut", subtitle: "Show or hide all hidden items without leaving the keyboard.") {
                ClearGlassControlRow(
                    systemImage: "keyboard",
                    title: "Global hotkey",
                    subtitle: "The shortcut works without Accessibility, Screen Recording, Apple Events, or Input Monitoring."
                ) {
                    Toggle("Global hotkey", isOn: $settingsStore.globalHotkeyEnabled)
                        .labelsHidden()
                }

                if settingsStore.globalHotkeyEnabled {
                    ClearGlassDivider()

                    ClearGlassValueRow("Current Hotkey") {
                        HStack(spacing: 10) {
                            KeyboardShortcutToken(text: settingsStore.effectiveGlobalHotkey().displayName)

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

private struct BehaviorSummaryStrip: View {
    @Bindable var settingsStore: SettingsStore

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            BehaviorSummaryPill(
                title: "Auto-Rehide",
                value: settingsStore.autoRehideEnabled
                    ? "\(Int(settingsStore.autoRehideDelaySeconds))s"
                    : "Off",
                systemImage: "clock"
            )

            BehaviorSummaryPill(
                title: "Hover Reveal",
                value: settingsStore.hoverRevealEnabled ? "On" : "Off",
                systemImage: "eye"
            )

            BehaviorSummaryPill(
                title: "Hidden Zone",
                value: settingsStore.alwaysHiddenEnabled ? "On" : "Off",
                systemImage: "square.dashed"
            )

            BehaviorSummaryPill(
                title: "Shortcut",
                value: settingsStore.globalHotkeyEnabled
                    ? settingsStore.effectiveGlobalHotkey().displayName
                    : "Off",
                systemImage: "keyboard"
            )
        }
    }
}

private struct BehaviorSummaryPill: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.secondary)
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
            .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 7))
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.75), lineWidth: 1)
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
