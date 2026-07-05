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
            badges: [.stable, .privacySafe, .basicMode],
            sectionAnchors: [
                ClearGlassPageAnchor("Reveal", systemImage: "eye"),
                ClearGlassPageAnchor("Hidden Zones", systemImage: "square.dashed"),
                ClearGlassPageAnchor("Separators", systemImage: "parallelpipe"),
                ClearGlassPageAnchor("Keyboard Shortcut", systemImage: "keyboard")
            ]
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
            BehaviorControlGroup(
                "Auto-Rehide",
                subtitle: "Collapse hidden items again after a timed reveal.",
                systemImage: "clock",
                statusText: settingsStore.autoRehideEnabled ? "On" : "Off",
                statusStyle: settingsStore.autoRehideEnabled ? .info : .secondary
            ) {
                BehaviorToggleRow(
                    systemImage: "power",
                    title: "Enable Auto-Rehide",
                    subtitle: "Collapse hidden items again after a short delay.",
                    isOn: $settingsStore.autoRehideEnabled
                )

                ClearGlassDivider()

                ClearGlassSliderRow(
                    "Delay",
                    subtitle: settingsStore.autoRehideEnabled
                        ? "Countdown before hidden items collapse again."
                        : "Enable auto-rehide to use this delay.",
                    value: $settingsStore.autoRehideDelaySeconds,
                    in: 0...60,
                    step: 1,
                    valueSuffix: "s",
                    valueFractionLength: 0
                )
                .disabled(!settingsStore.autoRehideEnabled)
                .opacity(settingsStore.autoRehideEnabled ? 1 : 0.72)
            }

            ClearGlassDivider()

            BehaviorControlGroup(
                "Hover Reveal",
                subtitle: "Reveal hidden items while the pointer is near the menu bar.",
                systemImage: "eye",
                statusText: settingsStore.hoverRevealEnabled ? "On" : "Off",
                statusStyle: settingsStore.hoverRevealEnabled ? .info : .secondary
            ) {
                BehaviorToggleRow(
                    systemImage: "cursorarrow.motionlines",
                    title: "Enable Hover Reveal",
                    subtitle: "Show hidden items while the pointer is near the menu bar.",
                    isOn: $settingsStore.hoverRevealEnabled
                )

                ClearGlassDivider()

                ClearGlassSliderRow(
                    "Polling Interval",
                    subtitle: settingsStore.hoverRevealEnabled
                        ? "Lower values feel more responsive and use slightly more CPU."
                        : "Enable hover reveal to tune pointer polling.",
                    value: $settingsStore.hoverRevealPollingIntervalSeconds,
                    in: AppConstants.minHoverRevealPollingIntervalSeconds...1.0,
                    step: 0.05,
                    valueSuffix: "s",
                    valueFractionLength: 2
                )
                .disabled(!settingsStore.hoverRevealEnabled)
                .opacity(settingsStore.hoverRevealEnabled ? 1 : 0.72)
            }

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
            BehaviorControlGroup(
                "Always-Hidden Zone",
                subtitle: "Keep a second group collapsed during normal reveals.",
                systemImage: "square.dashed",
                statusText: settingsStore.alwaysHiddenEnabled ? "On" : "Off",
                statusStyle: settingsStore.alwaysHiddenEnabled ? .info : .secondary
            ) {
                BehaviorToggleRow(
                    systemImage: "square.dashed",
                    title: "Enable Always-Hidden Zone",
                    subtitle: "Items beyond the second separator stay hidden when the primary zone expands.",
                    isOn: $settingsStore.alwaysHiddenEnabled
                )

                ClearGlassDivider()

                AlwaysHiddenZonePreview(isEnabled: settingsStore.alwaysHiddenEnabled)
            }

            ClearGlassDivider()

            BehaviorControlGroup(
                "Reveal Override",
                subtitle: "Allow an intentional temporary reveal of both hidden groups.",
                systemImage: "cursorarrow.click",
                statusText: settingsStore.revealAllOnOptionClick ? "On" : "Off",
                statusStyle: settingsStore.revealAllOnOptionClick ? .info : .secondary
            ) {
                BehaviorToggleRow(
                    systemImage: "option",
                    title: "Option-click reveals all",
                    subtitle: "Temporarily reveal both primary hidden items and always-hidden items.",
                    isOn: $settingsStore.revealAllOnOptionClick
                )
            }
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
            BehaviorControlGroup(
                "Global Shortcut",
                subtitle: "Toggle hidden items from the keyboard without elevated permissions.",
                systemImage: "keyboard",
                statusText: settingsStore.globalHotkeyEnabled ? "On" : "Off",
                statusStyle: settingsStore.globalHotkeyEnabled ? .info : .secondary
            ) {
                BehaviorToggleRow(
                    systemImage: "keyboard",
                    title: "Enable Global Hotkey",
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
                    ClearGlassAccessoryCluster(spacing: 10) {
                        hotkeyControls
                    }
                }
                .opacity(settingsStore.globalHotkeyEnabled ? 1 : 0.72)
            }
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
            .help(settingsStore.globalHotkeyEnabled ? "Reset the global hotkey to the default shortcut." : "Enable the global hotkey before resetting it.")
        }
    }
}

private struct BehaviorControlGroup<Content: View>: View {
    private let title: String
    private let subtitle: String
    private let systemImage: String
    private let statusText: String
    private let statusStyle: ClearGlassStatusStyle
    @ViewBuilder private let content: Content

    init(
        _ title: String,
        subtitle: String,
        systemImage: String,
        statusText: String,
        statusStyle: ClearGlassStatusStyle,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.statusText = statusText
        self.statusStyle = statusStyle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 10) {
                    header
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ClearGlassStatusValue(text: statusText, style: statusStyle)
                        .padding(.top, 1)
                }

                VStack(alignment: .leading, spacing: 6) {
                    header
                    ClearGlassStatusValue(text: statusText, style: statusStyle)
                }
            }
            .padding(.horizontal, 2)

            VStack(spacing: 0) {
                content
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(statusStyle.tint)
                .frame(width: 18)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
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

    var body: some View {
        ClearGlassOverviewStrip([
            ClearGlassOverviewMetric(
                title: "Auto-Rehide",
                value: autoRehideEnabled ? "\(Int(autoRehideDelaySeconds))s" : "Off",
                systemImage: "clock",
                style: autoRehideEnabled ? .info : .secondary
            ),
            ClearGlassOverviewMetric(
                title: "Hover Reveal",
                value: hoverRevealEnabled ? "On" : "Off",
                systemImage: "eye",
                style: hoverRevealEnabled ? .info : .secondary
            ),
            ClearGlassOverviewMetric(
                title: "Hidden Zone",
                value: alwaysHiddenEnabled ? "On" : "Off",
                systemImage: "square.dashed",
                style: alwaysHiddenEnabled ? .info : .secondary
            ),
            ClearGlassOverviewMetric(
                title: "Shortcut",
                value: globalHotkeyEnabled ? hotkeyText : "Off",
                systemImage: "keyboard",
                style: globalHotkeyEnabled ? .info : .secondary
            )
        ])
    }
}

private struct BehaviorToggleRow: View {
    let systemImage: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        ClearGlassStatusControlRow(
            systemImage: systemImage,
            title: title,
            subtitle: subtitle,
            iconTint: isOn ? .accentColor : .secondary,
            statusText: isOn ? "On" : "Off",
            statusStyle: isOn ? .info : .secondary
        ) {
            Toggle(title, isOn: $isOn)
                .labelsHidden()
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
