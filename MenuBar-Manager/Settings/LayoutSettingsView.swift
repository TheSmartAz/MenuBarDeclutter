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
        let estimate = layoutCoordinator?.currentCapacityEstimate()
        let suggestions = layoutCoordinator?.currentSuggestions() ?? []

        ClearGlassSettingsPage(
            "Layout",
            subtitle: "Manage capacity, reveal safeguards, spacer items, and spacing experiments.",
            badges: [.stable, .basicMode, .privacySafe]
        ) {
            LayoutOverviewStrip(
                settingsStore: settingsStore,
                estimate: estimate,
                suggestionCount: suggestions.count
            )

            CapacityAndSuggestionsSection(
                settingsStore: settingsStore,
                liveStatus: liveStatus,
                estimate: estimate,
                suggestions: suggestions
            )

            RevealModesSection(settingsStore: settingsStore)

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
                systemImage: "chart.bar",
                style: capacityStyle
            )

            LayoutOverviewPill(
                title: "Suggestions",
                value: settingsStore.layoutSuggestionsEnabled
                    ? "\(suggestionCount)"
                    : "Off",
                systemImage: "lightbulb",
                style: settingsStore.layoutSuggestionsEnabled ? .info : .secondary
            )

            LayoutOverviewPill(
                title: "Full Menu Bar",
                value: settingsStore.fullMenuBarModeEnabled ? "On" : "Off",
                systemImage: "rectangle.expand.vertical",
                style: settingsStore.fullMenuBarModeEnabled ? .success : .secondary
            )

            LayoutOverviewPill(
                title: "Spacers",
                value: settingsStore.spacerItemsEnabled ? "On" : "Off",
                systemImage: "line.vertical",
                style: settingsStore.spacerItemsEnabled ? .success : .secondary
            )
        }
    }

    private var capacityValue: String {
        guard let estimate else {
            return "Basic"
        }
        return estimate.usedCapacityRatio.formatted(.percent.precision(.fractionLength(0)))
    }

    private var capacityStyle: ClearGlassStatusStyle {
        guard let estimate else {
            return .secondary
        }
        return estimate.isLikelyCrowded ? .warning : .success
    }
}

private struct LayoutOverviewPill: View {
    let title: String
    let value: String
    let systemImage: String
    var style: ClearGlassStatusStyle = .secondary

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

// MARK: - Capacity

private struct CapacityAndSuggestionsSection: View {
    @Bindable var settingsStore: SettingsStore
    var liveStatus: LiveDiagnosticsStatus?
    var estimate: LayoutCapacityEstimate?
    let suggestions: [LayoutSuggestion]

    var body: some View {
        ClearGlassSection(
            "Capacity & Suggestions",
            subtitle: "Local crowding estimates and non-invasive recommendations."
        ) {
            VStack(spacing: 0) {
                ClearGlassControlRow(
                    systemImage: "chart.bar.fill",
                    title: "Show Capacity Warnings",
                    subtitle: "Show warnings when the menu bar appears crowded."
                ) {
                    Toggle("Show Capacity Warnings", isOn: $settingsStore.showCapacityWarnings)
                        .labelsHidden()
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "lightbulb",
                    title: "Layout Suggestions",
                    subtitle: "Receive privacy-safe suggestions for improving layout."
                ) {
                    Toggle("Layout Suggestions", isOn: $settingsStore.layoutSuggestionsEnabled)
                        .labelsHidden()
                }

                ClearGlassDivider()

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 12) {
                        CapacityInspectorPanel(
                            liveStatus: liveStatus,
                            estimate: estimate
                        )
                        .frame(minWidth: 320, maxWidth: .infinity)

                        SuggestionInspectorPanel(
                            isEnabled: settingsStore.layoutSuggestionsEnabled,
                            suggestions: suggestions
                        )
                        .frame(minWidth: 300, maxWidth: .infinity)
                    }

                    VStack(spacing: 12) {
                        CapacityInspectorPanel(
                            liveStatus: liveStatus,
                            estimate: estimate
                        )

                        SuggestionInspectorPanel(
                            isEnabled: settingsStore.layoutSuggestionsEnabled,
                            suggestions: suggestions
                        )
                    }
                }
                .padding(.vertical, 12)
            }
        }
    }
}

private struct CapacityInspectorPanel: View {
    var liveStatus: LiveDiagnosticsStatus?
    var estimate: LayoutCapacityEstimate?

    var body: some View {
        LayoutInspectorPanel(
            title: "Capacity Inspector",
            subtitle: estimate?.source.displayName ?? "Basic geometry fallback",
            systemImage: "menubar.rectangle"
        ) {
            if let estimate {
                CapacityGaugeView(estimate: estimate)

                LayoutInspectorDivider()

                LayoutInspectorRow(
                    "Used Capacity",
                    value: estimate.usedCapacityRatio.formatted(.percent.precision(.fractionLength(0))),
                    style: estimate.isLikelyCrowded ? .warning : .success
                )

                LayoutInspectorRow(
                    "Estimated Slots",
                    value: "\(estimate.estimatedUsedSlots) / \(estimate.estimatedItemSlots)"
                )

                LayoutInspectorRow(
                    "Known Items",
                    value: "\(estimate.knownVisibleItemCount) visible, \(estimate.knownHiddenItemCount) hidden"
                )

                if let scanTime = liveStatus?.lastMenuBarScanTime {
                    LayoutInspectorRow(
                        "Last AX Scan",
                        value: scanTime.formatted(date: .omitted, time: .standard)
                    )
                }

                if estimate.warnings.isEmpty == false {
                    LayoutInspectorDivider()

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(estimate.warnings, id: \.rawValue) { warning in
                            ClearGlassInlineMessage(
                                text: warning.displayMessage,
                                systemImage: "exclamationmark.triangle",
                                style: .warning
                            )
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Capacity Snapshot",
                    systemImage: "chart.bar",
                    description: Text("Basic Mode remains available. Optional Pro can improve estimates when Accessibility is enabled.")
                )
                .frame(maxWidth: .infinity, minHeight: 150)
            }

            ClearGlassInlineMessage(
                text: "Capacity estimates are more accurate with Optional Pro and Accessibility. Basic Mode uses approximate geometry.",
                systemImage: "checkmark.shield",
                style: .success
            )
        }
    }
}

private struct CapacityGaugeView: View {
    let estimate: LayoutCapacityEstimate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Menu Bar Load")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Spacer()

                ClearGlassStatusValue(
                    text: estimate.isLikelyCrowded ? "Crowded" : "Healthy",
                    style: estimate.isLikelyCrowded ? .warning : .success
                )
            }

            ProgressView(value: clampedRatio)
                .progressViewStyle(.linear)
                .tint(gaugeStyle.tint)
            .accessibilityLabel("Used capacity")
            .accessibilityValue(estimate.usedCapacityRatio.formatted(.percent.precision(.fractionLength(0))))

            HStack {
                Text(estimate.source.displayName)
                Spacer()
                Text(estimate.usedCapacityRatio, format: .number.precision(.fractionLength(2)))
                    .font(.system(.caption, design: .monospaced))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var clampedRatio: Double {
        min(max(estimate.usedCapacityRatio, 0), 1)
    }

    private var gaugeStyle: ClearGlassStatusStyle {
        estimate.isLikelyCrowded ? .warning : .success
    }
}

private struct SuggestionInspectorPanel: View {
    let isEnabled: Bool
    let suggestions: [LayoutSuggestion]

    var body: some View {
        LayoutInspectorPanel(
            title: "Suggestions",
            subtitle: isEnabled ? "\(suggestions.count) current" : "Turned off",
            systemImage: "lightbulb",
            iconTint: isEnabled ? .blue : .secondary
        ) {
            if !isEnabled {
                ClearGlassInlineMessage(
                    text: "Layout suggestions are off. Existing Basic Mode layout controls still work.",
                    systemImage: "lightbulb.slash",
                    style: .secondary
                )
            } else if suggestions.isEmpty {
                ClearGlassInlineMessage(
                    text: "No layout suggestions right now.",
                    systemImage: "checkmark.circle",
                    style: .success
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(suggestions) { suggestion in
                        LayoutSuggestionRow(suggestion: suggestion)
                    }
                }
            }
        }
    }
}

private struct LayoutSuggestionRow: View {
    let suggestion: LayoutSuggestion

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: suggestion.severity.systemImage)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(suggestion.severity.tint)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(suggestion.message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    if suggestion.requiresProMode {
                        ClearGlassBadge(style: .proMode)
                    }
                    if suggestion.requiresAccessibility {
                        ClearGlassBadge(style: .accessibilityRequired)
                    }
                    if suggestion.isExperimental {
                        ClearGlassBadge(style: .experimental)
                    }
                    if suggestion.requiresManualAction {
                        ClearGlassBadge(style: .actionNeeded)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.42), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(nsColor: .separatorColor).opacity(0.30), lineWidth: 0.5)
        }
    }
}

// MARK: - Reveal Modes

private struct RevealModesSection: View {
    @Bindable var settingsStore: SettingsStore

    var body: some View {
        ClearGlassSection(
            "Reveal Modes",
            subtitle: "Temporary reveal behavior and crowded menu bar rescue."
        ) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    FullMenuBarModePanel(settingsStore: settingsStore)
                        .frame(minWidth: 320, maxWidth: .infinity)

                    CrowdedRevealPanel(settingsStore: settingsStore)
                        .frame(minWidth: 320, maxWidth: .infinity)
                }
                .padding(.vertical, 8)

                VStack(spacing: 12) {
                    FullMenuBarModePanel(settingsStore: settingsStore)
                    CrowdedRevealPanel(settingsStore: settingsStore)
                }
                .padding(.vertical, 8)
            }
        }
    }
}

private struct FullMenuBarModePanel: View {
    @Bindable var settingsStore: SettingsStore

    var body: some View {
        LayoutInspectorPanel(
            title: "Full Menu Bar Mode",
            subtitle: "Reveal every app-owned status item temporarily.",
            systemImage: "rectangle.expand.vertical",
            iconTint: settingsStore.fullMenuBarModeEnabled ? .green : .secondary
        ) {
            VStack(spacing: 0) {
                ClearGlassControlRow(
                    systemImage: "rectangle.expand.vertical",
                    title: "Enable Full Menu Bar Mode",
                    subtitle: "Allow entering a temporary full reveal mode."
                ) {
                    Toggle("Enable Full Menu Bar Mode", isOn: $settingsStore.fullMenuBarModeEnabled)
                        .labelsHidden()
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "clock",
                    title: "Auto-Exit",
                    subtitle: "Automatically exit Full Menu Bar Mode after a timeout."
                ) {
                    Toggle("Auto-Exit", isOn: $settingsStore.fullMenuBarModeAutoExitEnabled)
                        .labelsHidden()
                }

                if settingsStore.fullMenuBarModeAutoExitEnabled {
                    ClearGlassDivider()

                    ClearGlassSliderRow(
                        "Auto-Exit Delay",
                        subtitle: "Seconds before auto-exit.",
                        value: $settingsStore.fullMenuBarModeAutoExitSeconds,
                        in: AppConstants.minFullMenuBarModeAutoExitSeconds...AppConstants.maxFullMenuBarModeAutoExitSeconds,
                        step: 5,
                        valueSuffix: "s"
                    )
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "menubar.rectangle",
                    title: "Show Second Bar",
                    subtitle: "Open Second Bar when entering Full Menu Bar Mode."
                ) {
                    Toggle("Show Second Bar", isOn: $settingsStore.fullMenuBarModeShowsSecondBar)
                        .labelsHidden()
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "pause.circle",
                    title: "Suspend Auto-Rehide",
                    subtitle: "Prevent auto-rehide while Full Menu Bar Mode is active."
                ) {
                    Toggle("Suspend Auto-Rehide", isOn: $settingsStore.fullMenuBarModeSuspendsAutoRehide)
                        .labelsHidden()
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "line.vertical",
                    title: "Show Spacer Markers",
                    subtitle: "Show spacer markers while in Full Menu Bar Mode."
                ) {
                    Toggle("Show Spacer Markers", isOn: $settingsStore.fullMenuBarModeShowsSpacerMarkers)
                        .labelsHidden()
                }
            }
        }
    }
}

private struct CrowdedRevealPanel: View {
    @Bindable var settingsStore: SettingsStore

    var body: some View {
        LayoutInspectorPanel(
            title: "Crowded Reveal Rescue",
            subtitle: "Fail closed into Second Bar when inline reveal is risky.",
            systemImage: "shield.lefthalf.filled",
            iconTint: settingsStore.crowdedRevealRescueEnabled ? .green : .secondary
        ) {
            FeatureGateNotice(
                .preview,
                text: "Preview in v0.1.3. Fails closed when capacity or Pro estimates are unavailable."
            )

            LayoutInspectorDivider()

            VStack(spacing: 0) {
                ClearGlassControlRow(
                    systemImage: "shield.lefthalf.filled",
                    title: "Enable Crowded Reveal Rescue",
                    subtitle: "Intercept reveals when the menu bar is crowded."
                ) {
                    Toggle("Enable Crowded Reveal Rescue", isOn: $settingsStore.crowdedRevealRescueEnabled)
                        .labelsHidden()
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "menubar.rectangle",
                    title: "Auto-Open Second Bar",
                    subtitle: "Automatically open Second Bar when crowded."
                ) {
                    Toggle("Auto-Open Second Bar", isOn: $settingsStore.crowdedRevealAutoOpenSecondBar)
                        .labelsHidden()
                }

                ClearGlassDivider()

                ClearGlassSliderRow(
                    "Crowded Threshold",
                    subtitle: "Capacity ratio above which the menu bar is considered crowded.",
                    value: $settingsStore.crowdedRevealThresholdRatio,
                    in: AppConstants.minCrowdedRevealThresholdRatio...AppConstants.maxCrowdedRevealThresholdRatio,
                    step: 0.05,
                    valueSuffix: "",
                    valueFractionLength: 2
                )

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "star",
                    title: "Require Pro Estimate",
                    subtitle: "Only trigger rescue when a Pro AX estimate is available."
                ) {
                    Toggle("Require Pro Estimate", isOn: $settingsStore.crowdedRevealRequireProEstimate)
                        .labelsHidden()
                }
            }
        }
    }
}

// MARK: - Spacer Items

private struct SpacerItemsSection: View {
    @Bindable var settingsStore: SettingsStore
    var spacerStore: SpacerItemStore?
    var spacerController: SpacerStatusItemController?

    var body: some View {
        ClearGlassSection(
            "Spacer & Divider Items",
            subtitle: "App-owned NSStatusItem spacers for organizing dense menu bars."
        ) {
            VStack(spacing: 0) {
                ClearGlassControlRow(
                    systemImage: "line.vertical",
                    title: "Enable Spacer Items",
                    subtitle: "Allow adding app-owned spacer and divider status items."
                ) {
                    Toggle("Enable Spacer Items", isOn: $settingsStore.spacerItemsEnabled)
                        .labelsHidden()
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "eye",
                    title: "Show Spacer Markers",
                    subtitle: "Show visual markers on spacer items."
                ) {
                    Toggle("Show Spacer Markers", isOn: $settingsStore.showSpacerMarkers)
                        .labelsHidden()
                }

                ClearGlassDivider()

                ClearGlassInlineMessage(
                    text: "Spacer items are app-owned NSStatusItem instances. You can Command-drag them like other menu bar items.",
                    systemImage: "checkmark.shield",
                    style: .success
                )
                .padding(.vertical, 10)

                LayoutInspectorPanel(
                    title: "Spacer Inspector",
                    subtitle: settingsStore.spacerItemsEnabled ? "Add, edit, hide, or reset spacers." : "Spacer controls are disabled.",
                    systemImage: "sidebar.right",
                    iconTint: settingsStore.spacerItemsEnabled ? .blue : .secondary
                ) {
                    if let spacerStore {
                        SpacerItemListView(
                            store: spacerStore,
                            controller: spacerController
                        )
                        .disabled(!settingsStore.spacerItemsEnabled)
                        .opacity(settingsStore.spacerItemsEnabled ? 1 : 0.72)
                    } else {
                        ContentUnavailableView(
                            "Spacer Store Unavailable",
                            systemImage: "line.vertical",
                            description: Text("Spacer items appear here once layout services are attached.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 160)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }
}

// MARK: - Menu Bar Spacing Labs

private struct MenuBarSpacingLabsSection: View {
    @Bindable var settingsStore: SettingsStore

    var body: some View {
        ClearGlassSection(
            "Menu Bar Spacing Labs",
            subtitle: "Labs global menu bar spacing, only after explicit opt-in."
        ) {
            VStack(spacing: 0) {
                FeatureGateNotice(
                    .labs,
                    text: "Labs in v0.1.3. Off by default and never restarts system processes automatically."
                )

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "testtube.2",
                    title: "Enable Spacing Labs",
                    subtitle: "Enable the Labs spacing manager. Off by default.",
                    iconTint: settingsStore.menuBarSpacingLabsEnabled ? .purple : .secondary
                ) {
                    Toggle("Enable Spacing Labs", isOn: $settingsStore.menuBarSpacingLabsEnabled)
                        .labelsHidden()
                }

                if settingsStore.menuBarSpacingLabsEnabled {
                    ClearGlassDivider()

                    MenuBarSpacingPresetPanel(settingsStore: settingsStore)
                        .padding(.vertical, 12)

                    ClearGlassInlineMessage(
                        text: "This is a Labs feature. Menu bar apps, SystemUIServer, ControlCenter, logout, or reboot may be needed for full effect. Never automatically restarts system processes.",
                        systemImage: "exclamationmark.triangle",
                        style: .warning
                    )
                    .padding(.bottom, 8)
                }
            }
        }
    }
}

private struct MenuBarSpacingPresetPanel: View {
    @Bindable var settingsStore: SettingsStore

    var body: some View {
        LayoutInspectorPanel(
            title: "Spacing Inspector",
            subtitle: selectedPreset.displayName,
            systemImage: "slider.horizontal.3",
            iconTint: .purple
        ) {
            VStack(spacing: 0) {
                ClearGlassValueRow("Preset", subtitle: "Current spacing preset.") {
                    Picker("Preset", selection: $settingsStore.menuBarSpacingPreset) {
                        ForEach(MenuBarSpacingPreset.allCases) { preset in
                            Text(preset.displayName).tag(preset.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: 300)
                }

                if settingsStore.menuBarSpacingPreset == MenuBarSpacingPreset.custom.rawValue {
                    ClearGlassDivider()

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

                    ClearGlassDivider()

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
            }

            if settingsStore.menuBarSpacingHasBackup {
                LayoutInspectorDivider()

                ClearGlassInlineMessage(
                    text: "A backup of your previous spacing values exists. You can restore it.",
                    systemImage: "checkmark.circle",
                    style: .success
                )
            }

            if let status = settingsStore.menuBarSpacingLastApplyStatus {
                LayoutInspectorDivider()

                LayoutInspectorRow("Last Apply Status", value: status)
            }
        }
    }

    private var selectedPreset: MenuBarSpacingPreset {
        MenuBarSpacingPreset(rawValue: settingsStore.menuBarSpacingPreset) ?? .system
    }
}

// MARK: - Shared Layout Helpers

private struct LayoutInspectorPanel<Content: View>: View {
    let title: String
    var subtitle: String?
    let systemImage: String
    var iconTint: Color = .secondary
    @ViewBuilder let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        iconTint: Color = .secondary,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.iconTint = iconTint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(iconTint)
                    .frame(width: 22, height: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.46), lineWidth: 0.5)
        }
    }
}

private struct LayoutInspectorRow: View {
    let title: String
    let value: String
    var style: ClearGlassStatusStyle?

    init(_ title: String, value: String, style: ClearGlassStatusStyle? = nil) {
        self.title = title
        self.value = value
        self.style = style
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            if let style {
                ClearGlassStatusValue(text: value, style: style)
            } else {
                Text(value)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
                    .truncationMode(.middle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LayoutInspectorDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor).opacity(0.42))
            .frame(height: 0.5)
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
