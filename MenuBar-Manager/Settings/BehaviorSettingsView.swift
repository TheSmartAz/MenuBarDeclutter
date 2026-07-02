import SwiftUI

/// Phase 14 "Hide & Reveal" section in Settings: auto-rehide, hover reveal,
/// always-hidden zone, separator visuals, global hotkey, and Option-click.
struct BehaviorSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    /// Called whenever any Phase 2 setting changes so the AppEnvironment can
    /// apply the new value to the live services.
    var onChange: (() -> Void)? = nil

    var body: some View {
        ClearGlassSettingsPage(
            "Hide & Reveal",
            subtitle: "Control how hidden menu bar items reveal, collapse, and respond to shortcuts.",
            badges: [.stable, .privacySafe, .basicMode]
        ) {
            BehaviorSummaryStrip(
                autoRehideEnabled: settingsStore.autoRehideEnabled,
                autoRehideDelaySeconds: settingsStore.autoRehideDelaySeconds,
                hoverRevealEnabled: settingsStore.hoverRevealEnabled,
                alwaysHiddenEnabled: settingsStore.alwaysHiddenEnabled,
                globalHotkeyEnabled: settingsStore.globalHotkeyEnabled,
                hotkeyText: settingsStore.effectiveGlobalHotkey().displayName
            )

            revealSection
            hiddenZonesSection
            separatorsSection
            keyboardShortcutSection
        }
        .onBehaviorSettingsChanges(from: settingsStore, perform: onChange)
    }

    private var revealSection: some View {
        ClearGlassSection("Reveal", subtitle: "Choose how hidden items temporarily come back into view.") {
            BehaviorToggleRow(
                systemImage: "clock",
                title: "Re-hide after reveal",
                subtitle: "Collapse hidden items again after a short delay.",
                isOn: $settingsStore.autoRehideEnabled
            )

            ClearGlassDivider()

            ClearGlassSliderRow(
                "Delay",
                subtitle: settingsStore.autoRehideEnabled
                    ? "Countdown before hidden items collapse again."
                    : "Enable re-hide after reveal to use this delay.",
                value: $settingsStore.autoRehideDelaySeconds,
                in: 0...60,
                step: 1,
                valueSuffix: "s",
                valueFractionLength: 0
            )
            .disabled(!settingsStore.autoRehideEnabled)
            .opacity(settingsStore.autoRehideEnabled ? 1 : 0.55)

            ClearGlassDivider()

            BehaviorToggleRow(
                systemImage: "eye",
                title: "Reveal on hover",
                subtitle: "Show hidden items while the pointer is near the menu bar.",
                isOn: $settingsStore.hoverRevealEnabled
            )

            ClearGlassDivider()

            ClearGlassSliderRow(
                "Polling Interval",
                subtitle: settingsStore.hoverRevealEnabled
                    ? "Lower values feel more responsive and use slightly more CPU."
                    : "Enable reveal on hover to tune pointer polling.",
                value: $settingsStore.hoverRevealPollingIntervalSeconds,
                in: AppConstants.minHoverRevealPollingIntervalSeconds...1.0,
                step: 0.05,
                valueSuffix: "s",
                valueFractionLength: 2
            )
            .disabled(!settingsStore.hoverRevealEnabled)
            .opacity(settingsStore.hoverRevealEnabled ? 1 : 0.55)

            ClearGlassDivider()

            ClearGlassInlineMessage(
                text: "Reveal behavior stays in Basic Mode and does not use Accessibility, Screen Recording, Apple Events, Input Monitoring, or network access.",
                systemImage: "checkmark.shield",
                style: .success
            )
        }
    }

    private var hiddenZonesSection: some View {
        ClearGlassSection("Hidden Zones", subtitle: "Keep sensitive or noisy items separate from the main reveal group.") {
            BehaviorToggleRow(
                systemImage: "square.dashed",
                title: "Always-hidden zone",
                subtitle: "Items beyond the second separator stay hidden when the primary zone expands.",
                isOn: $settingsStore.alwaysHiddenEnabled
            )

            ClearGlassDivider()

            AlwaysHiddenZonePreview(isEnabled: settingsStore.alwaysHiddenEnabled)

            ClearGlassDivider()

            BehaviorToggleRow(
                systemImage: "cursorarrow.click",
                title: "Option-click reveals all",
                subtitle: "Temporarily reveal both primary hidden items and always-hidden items.",
                isOn: $settingsStore.revealAllOnOptionClick
            )
        }
    }

    private var separatorsSection: some View {
        ClearGlassSection("Separators", subtitle: "Control the visible marker for app-owned separator items.") {
            BehaviorToggleRow(
                systemImage: "parallelpipe",
                title: "Show separator markers",
                subtitle: "When off, separators remain in place but their icons disappear.",
                isOn: $settingsStore.showSeparators
            )

            ClearGlassDivider()

            ClearGlassInlineMessage(
                text: settingsStore.showSeparators
                    ? "Separator markers are visible and can be used as menu bar landmarks."
                    : "Separators remain in place while their marker icons are hidden.",
                systemImage: settingsStore.showSeparators ? "checkmark.circle" : "eye.slash",
                style: settingsStore.showSeparators ? .success : .secondary
            )
        }
    }

    private var keyboardShortcutSection: some View {
        ClearGlassSection("Keyboard Shortcut", subtitle: "Show or hide all hidden items without leaving the keyboard.") {
            BehaviorToggleRow(
                systemImage: "keyboard",
                title: "Global hotkey",
                subtitle: "The shortcut works without Accessibility, Screen Recording, Apple Events, or Input Monitoring.",
                isOn: $settingsStore.globalHotkeyEnabled
            )

            ClearGlassDivider()

            ClearGlassValueRow(
                "Current Hotkey",
                subtitle: settingsStore.globalHotkeyEnabled
                    ? "Active shortcut for toggling hidden items."
                    : "Enable the global hotkey to activate this shortcut."
            ) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        hotkeyControls
                    }

                    VStack(alignment: .trailing, spacing: 8) {
                        hotkeyControls
                    }
                }
            }
            .opacity(settingsStore.globalHotkeyEnabled ? 1 : 0.55)
        }
    }

    private var hotkeyControls: some View {
        Group {
            KeyboardShortcutToken(
                text: settingsStore.globalHotkeyEnabled
                    ? settingsStore.effectiveGlobalHotkey().displayName
                    : "Off"
            )
            .lineLimit(1)

            Button("Reset to Default", systemImage: "arrow.counterclockwise") {
                settingsStore.resetGlobalHotkeyToDefault()
                onChange?()
            }
            .disabled(!settingsStore.globalHotkeyEnabled)
        }
    }
}

private struct BehaviorSummaryStrip: View {
    let autoRehideEnabled: Bool
    let autoRehideDelaySeconds: Double
    let hoverRevealEnabled: Bool
    let alwaysHiddenEnabled: Bool
    let globalHotkeyEnabled: Bool
    let hotkeyText: String

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            BehaviorSummaryPill(
                title: "Auto-Rehide",
                value: autoRehideEnabled ? "\(Int(autoRehideDelaySeconds))s" : "Off",
                systemImage: "clock",
                style: autoRehideEnabled ? .info : .secondary
            )

            BehaviorSummaryPill(
                title: "Hover Reveal",
                value: hoverRevealEnabled ? "On" : "Off",
                systemImage: "eye",
                style: hoverRevealEnabled ? .info : .secondary
            )

            BehaviorSummaryPill(
                title: "Hidden Zone",
                value: alwaysHiddenEnabled ? "On" : "Off",
                systemImage: "square.dashed",
                style: alwaysHiddenEnabled ? .info : .secondary
            )

            BehaviorSummaryPill(
                title: "Shortcut",
                value: globalHotkeyEnabled ? hotkeyText : "Off",
                systemImage: "keyboard",
                style: globalHotkeyEnabled ? .info : .secondary
            )
        }
    }
}

private struct BehaviorSummaryPill: View {
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

private struct BehaviorToggleRow: View {
    let systemImage: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        ClearGlassControlRow(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            iconTint: isOn ? .accentColor : .secondary
        ) {
            HStack(spacing: 12) {
                ClearGlassStatusValue(
                    text: isOn ? "On" : "Off",
                    style: isOn ? .info : .secondary
                )

                Toggle(title, isOn: $isOn)
                    .labelsHidden()
            }
        }
    }
}

private struct AlwaysHiddenZonePreview: View {
    let isEnabled: Bool

    private let icons = ["apple.logo", "wifi", "battery.100", "cloud", "moon", "speaker.wave.2"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text("Primary")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                menuBarPreview

                Text("Always Hidden")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            ClearGlassInlineMessage(
                text: isEnabled
                    ? "The always-hidden zone stays collapsed until explicitly revealed."
                    : "Enable the always-hidden zone to keep a second group collapsed during normal reveals.",
                systemImage: isEnabled ? "checkmark.circle" : "square.dashed",
                style: isEnabled ? .success : .secondary
            )
        }
        .padding(.vertical, 8)
        .opacity(isEnabled ? 1 : 0.72)
    }

    private var menuBarPreview: some View {
        HStack(spacing: 12) {
            ForEach(icons, id: \.self) { icon in
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 18)

            Image(systemName: "lock")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(isEnabled ? .secondary : .tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(nsColor: .separatorColor).opacity(0.75), lineWidth: 0.5)
        }
    }
}

#Preview {
    BehaviorSettingsView(settingsStore: SettingsStore())
}
