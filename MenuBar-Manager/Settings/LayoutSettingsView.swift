import Observation
import SwiftUI

/// Phase 10 Layout settings view.
///
/// Shows capacity, suggestions, Full Menu Bar Mode, Crowded Reveal Rescue,
/// Spacer Items, and Menu Bar Spacing Labs sections.
struct LayoutSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    let diagnosticsLogger: DiagnosticsLogger
    var liveStatus: LiveDiagnosticsStatus?
    var layoutCoordinator: LayoutCoordinator?

    var body: some View {
        ClearGlassSettingsPage(
            "Layout",
            subtitle: "Manage capacity, reveal safeguards, spacer items, and spacing experiments.",
            badges: [.stable, .basicMode, .privacySafe]
        ) {
            LayoutOverviewStrip(
                settingsStore: settingsStore,
                estimate: layoutCoordinator?.currentCapacityEstimate(),
                suggestionCount: layoutCoordinator?.currentSuggestions().count ?? 0
            )

            CapacitySection(
                settingsStore: settingsStore,
                liveStatus: liveStatus,
                estimate: layoutCoordinator?.currentCapacityEstimate()
            )

            SuggestionsSection(suggestions: layoutCoordinator?.currentSuggestions() ?? [])

            FullMenuBarModeSection(settingsStore: settingsStore)

            CrowdedRevealSection(settingsStore: settingsStore)

            SpacerItemsSection(
                settingsStore: settingsStore,
                spacerStore: layoutCoordinator?.spacerStore,
                spacerController: layoutCoordinator?.spacerController
            )

            MenuBarSpacingLabsSection(settingsStore: settingsStore)
        }
    }
}

private struct LayoutOverviewStrip: View {
    @Bindable var settingsStore: SettingsStore
    var estimate: LayoutCapacityEstimate?
    var suggestionCount: Int

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            LayoutOverviewPill(
                title: "Capacity",
                value: capacityValue,
                systemImage: "chart.bar"
            )

            LayoutOverviewPill(
                title: "Suggestions",
                value: settingsStore.layoutSuggestionsEnabled
                    ? "\(suggestionCount)"
                    : "Off",
                systemImage: "lightbulb"
            )

            LayoutOverviewPill(
                title: "Full Menu Bar",
                value: settingsStore.fullMenuBarModeEnabled ? "On" : "Off",
                systemImage: "rectangle.expand.vertical"
            )

            LayoutOverviewPill(
                title: "Spacers",
                value: settingsStore.spacerItemsEnabled ? "On" : "Off",
                systemImage: "line.vertical"
            )
        }
    }

    private var capacityValue: String {
        guard let estimate else {
            return "Basic"
        }
        return estimate.usedCapacityRatio.formatted(.percent.precision(.fractionLength(0)))
    }
}

private struct LayoutOverviewPill: View {
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

// MARK: - Capacity Section

private struct CapacitySection: View {
    @Bindable var settingsStore: SettingsStore
    var liveStatus: LiveDiagnosticsStatus?
    var estimate: LayoutCapacityEstimate?

    var body: some View {
        ClearGlassSection("Capacity", subtitle: "Estimate how crowded your menu bar is.") {
            ClearGlassControlRow(
                systemImage: "chart.bar.fill",
                title: "Show Capacity Warnings",
                subtitle: "Show warnings when the menu bar appears crowded."
            ) {
                Toggle("", isOn: $settingsStore.showCapacityWarnings)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            ClearGlassControlRow(
                systemImage: "lightbulb",
                title: "Layout Suggestions",
                subtitle: "Receive non-invasive suggestions for improving layout."
            ) {
                Toggle("", isOn: $settingsStore.layoutSuggestionsEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            if let liveStatus, let scanTime = liveStatus.lastMenuBarScanTime {
                ClearGlassValueRow("Last AX Scan", subtitle: "Pro Mode snapshot timestamp") {
                    Text(scanTime, style: .time)
                }
            }

            if let estimate {
                ClearGlassDivider()

                ClearGlassValueRow("Capacity Ratio", subtitle: estimate.source.displayName) {
                    Text(estimate.usedCapacityRatio, format: .number.precision(.fractionLength(2)))
                        .font(.system(.body, design: .monospaced))
                }

                ClearGlassValueRow("Estimated Slots") {
                    Text("\(estimate.estimatedUsedSlots) / \(estimate.estimatedItemSlots)")
                        .font(.system(.body, design: .monospaced))
                }

                ClearGlassValueRow("Known Items") {
                    Text("\(estimate.knownVisibleItemCount) visible, \(estimate.knownHiddenItemCount) hidden")
                        .foregroundStyle(.secondary)
                }

                ForEach(estimate.warnings, id: \.rawValue) { warning in
                    ClearGlassInlineMessage(
                        text: warning.displayMessage,
                        systemImage: "exclamationmark.triangle",
                        style: .warning
                    )
                }
            }

            ClearGlassInlineMessage(
                text: "Capacity estimates are more accurate with Pro Mode and Accessibility. Basic Mode uses approximate geometry.",
                systemImage: "info.circle"
            )
        }
    }
}

private struct SuggestionsSection: View {
    let suggestions: [LayoutSuggestion]

    var body: some View {
        ClearGlassSection("Suggestions", subtitle: "Non-invasive recommendations based on current layout state.") {
            if suggestions.isEmpty {
                ClearGlassInlineMessage(
                    text: "No layout suggestions right now.",
                    systemImage: "checkmark.circle",
                    style: .success
                )
            } else {
                ForEach(suggestions) { suggestion in
                    ClearGlassControlRow(
                        systemImage: suggestion.severity.systemImage,
                        title: suggestion.title,
                        subtitle: suggestion.message,
                        iconTint: suggestion.severity.tint
                    ) {
                        HStack(spacing: 6) {
                            if suggestion.requiresProMode {
                                ClearGlassBadge(style: .proMode)
                            }
                            if suggestion.isExperimental {
                                ClearGlassBadge(style: .experimental)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Full Menu Bar Mode Section

private struct FullMenuBarModeSection: View {
    @Bindable var settingsStore: SettingsStore

    var body: some View {
        ClearGlassSection("Full Menu Bar Mode", subtitle: "Temporarily reveal all items for easier access.") {
            ClearGlassControlRow(
                systemImage: "rectangle.expand.vertical",
                title: "Enable Full Menu Bar Mode",
                subtitle: "Allow entering a temporary full reveal mode."
            ) {
                Toggle("", isOn: $settingsStore.fullMenuBarModeEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            ClearGlassControlRow(
                systemImage: "clock",
                title: "Auto-Exit",
                subtitle: "Automatically exit Full Menu Bar Mode after a timeout."
            ) {
                Toggle("", isOn: $settingsStore.fullMenuBarModeAutoExitEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            if settingsStore.fullMenuBarModeAutoExitEnabled {
                ClearGlassSliderRow(
                    "Auto-Exit Delay",
                    subtitle: "Seconds before auto-exit.",
                    value: $settingsStore.fullMenuBarModeAutoExitSeconds,
                    in: AppConstants.minFullMenuBarModeAutoExitSeconds...AppConstants.maxFullMenuBarModeAutoExitSeconds,
                    step: 5,
                    valueSuffix: "s"
                )
            }

            ClearGlassControlRow(
                systemImage: "menubar.rectangle",
                title: "Show Second Bar",
                subtitle: "Open Second Bar when entering Full Menu Bar Mode."
            ) {
                Toggle("", isOn: $settingsStore.fullMenuBarModeShowsSecondBar)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            ClearGlassControlRow(
                systemImage: "pause.circle",
                title: "Suspend Auto-Rehide",
                subtitle: "Prevent auto-rehide while Full Menu Bar Mode is active."
            ) {
                Toggle("", isOn: $settingsStore.fullMenuBarModeSuspendsAutoRehide)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            ClearGlassControlRow(
                systemImage: "line.vertical",
                title: "Show Spacer Markers",
                subtitle: "Show spacer markers while in Full Menu Bar Mode."
            ) {
                Toggle("", isOn: $settingsStore.fullMenuBarModeShowsSpacerMarkers)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
        }
    }
}

// MARK: - Crowded Reveal Section

private struct CrowdedRevealSection: View {
    @Bindable var settingsStore: SettingsStore

    var body: some View {
        ClearGlassSection("Crowded Reveal Rescue", subtitle: "Open Second Bar instead of a bad inline reveal.") {
            FeatureGateNotice(
                .preview,
                text: "Preview in v0.1.1. Fails closed when capacity or Pro estimates are unavailable."
            )

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "shield.lefthalf.filled",
                title: "Enable Crowded Reveal Rescue",
                subtitle: "Intercept reveals when the menu bar is crowded."
            ) {
                Toggle("", isOn: $settingsStore.crowdedRevealRescueEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            ClearGlassControlRow(
                systemImage: "menubar.rectangle",
                title: "Auto-Open Second Bar",
                subtitle: "Automatically open Second Bar when crowded."
            ) {
                Toggle("", isOn: $settingsStore.crowdedRevealAutoOpenSecondBar)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            ClearGlassSliderRow(
                "Crowded Threshold",
                subtitle: "Capacity ratio above which the menu bar is considered crowded.",
                value: $settingsStore.crowdedRevealThresholdRatio,
                in: AppConstants.minCrowdedRevealThresholdRatio...AppConstants.maxCrowdedRevealThresholdRatio,
                step: 0.05,
                valueSuffix: "",
                valueFractionLength: 2
            )

            ClearGlassControlRow(
                systemImage: "star",
                title: "Require Pro Estimate",
                subtitle: "Only trigger rescue when a Pro AX estimate is available."
            ) {
                Toggle("", isOn: $settingsStore.crowdedRevealRequireProEstimate)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
        }
    }
}

// MARK: - Spacer Items Section

private struct SpacerItemsSection: View {
    @Bindable var settingsStore: SettingsStore
    var spacerStore: SpacerItemStore?
    var spacerController: SpacerStatusItemController?

    var body: some View {
        ClearGlassSection("Spacer & Divider Items", subtitle: "Add app-owned spacer and divider items to organize your menu bar.") {
            ClearGlassControlRow(
                systemImage: "line.vertical",
                title: "Enable Spacer Items",
                subtitle: "Allow adding app-owned spacer/divider status items."
            ) {
                Toggle("", isOn: $settingsStore.spacerItemsEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            ClearGlassControlRow(
                systemImage: "eye",
                title: "Show Spacer Markers",
                subtitle: "Show visual markers on spacer items."
            ) {
                Toggle("", isOn: $settingsStore.showSpacerMarkers)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            ClearGlassInlineMessage(
                text: "Spacer items are app-owned NSStatusItem instances. You can Command-drag them like other menu bar items.",
                systemImage: "info.circle"
            )

            if let spacerStore {
                ClearGlassDivider()

                SpacerItemListView(
                    store: spacerStore,
                    controller: spacerController
                )
                .disabled(!settingsStore.spacerItemsEnabled)
                .opacity(settingsStore.spacerItemsEnabled ? 1 : 0.55)
            }
        }
    }
}

private extension LayoutCapacitySource {
    var displayName: String {
        switch self {
        case .basicGeometryOnly:
            "Basic geometry estimate"
        case .proAXSnapshot:
            "Pro AX snapshot"
        case .mixed:
            "Mixed estimate"
        }
    }
}

private extension LayoutCapacityWarning {
    var displayMessage: String {
        message
    }
}

private extension LayoutSuggestionSeverity {
    var systemImage: String {
        switch self {
        case .info:
            "info.circle"
        case .warning:
            "exclamationmark.triangle"
        case .critical:
            "exclamationmark.octagon"
        }
    }

    var tint: Color {
        switch self {
        case .info:
            .blue
        case .warning:
            .orange
        case .critical:
            .red
        }
    }
}

// MARK: - Menu Bar Spacing Labs Section

private struct MenuBarSpacingLabsSection: View {
    @Bindable var settingsStore: SettingsStore

    var body: some View {
        ClearGlassSection(
            "Menu Bar Spacing Labs",
            subtitle: "Labs: adjust global menu bar item spacing only after explicit opt-in."
        ) {
            FeatureGateNotice(
                .labs,
                text: "Labs in v0.1.1. Off by default and never restarts system processes automatically."
            )

            ClearGlassDivider()

            ClearGlassControlRow(
                systemImage: "testtube.2",
                title: "Enable Spacing Labs",
                subtitle: "Enable the experimental spacing manager. Off by default."
            ) {
                Toggle("", isOn: $settingsStore.menuBarSpacingLabsEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            if settingsStore.menuBarSpacingLabsEnabled {
                ClearGlassControlRow(
                    systemImage: "slider.horizontal.3",
                    title: "Preset",
                    subtitle: "Current spacing preset."
                ) {
                    Picker("", selection: $settingsStore.menuBarSpacingPreset) {
                        ForEach(MenuBarSpacingPreset.allCases) { preset in
                            Text(preset.displayName).tag(preset.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 280)
                }

                if settingsStore.menuBarSpacingPreset == MenuBarSpacingPreset.custom.rawValue {
                    ClearGlassSliderRow(
                        "Custom Item Spacing",
                        value: Binding(
                            get: { Double(settingsStore.menuBarSpacingCustomItemSpacing) },
                            set: { settingsStore.menuBarSpacingCustomItemSpacing = Int($0) }
                        ),
                        in: Double(AppConstants.minMenuBarSpacingCustomItemSpacing)...Double(AppConstants.maxMenuBarSpacingCustomItemSpacing),
                        step: 1,
                        valueSuffix: "pt"
                    )

                    ClearGlassSliderRow(
                        "Custom Selection Padding",
                        value: Binding(
                            get: { Double(settingsStore.menuBarSpacingCustomSelectionPadding) },
                            set: { settingsStore.menuBarSpacingCustomSelectionPadding = Int($0) }
                        ),
                        in: Double(AppConstants.minMenuBarSpacingCustomSelectionPadding)...Double(AppConstants.maxMenuBarSpacingCustomSelectionPadding),
                        step: 1,
                        valueSuffix: "pt"
                    )
                }

                if settingsStore.menuBarSpacingHasBackup {
                    ClearGlassInlineMessage(
                        text: "A backup of your previous spacing values exists. You can restore it.",
                        systemImage: "checkmark.circle",
                        style: .success
                    )
                }

                if let status = settingsStore.menuBarSpacingLastApplyStatus {
                    ClearGlassValueRow("Last Apply Status") {
                        Text(status)
                    }
                }

                ClearGlassInlineMessage(
                    text: "This is experimental. Menu bar apps, SystemUIServer, ControlCenter, logout, or reboot may be needed for full effect. Never automatically restarts system processes.",
                    systemImage: "exclamationmark.triangle",
                    style: .warning
                )
            }
        }
    }
}
