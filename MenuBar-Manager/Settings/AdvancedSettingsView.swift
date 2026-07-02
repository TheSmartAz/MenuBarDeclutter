import AppKit
import SwiftUI

/// Phase 3 "Advanced" settings: separator geometry tweaks, App Support
/// discovery, and read-only build/diagnostics metadata. Most users should not
/// need to touch this surface, which is why it lives behind its own tab.
struct AdvancedSettingsView: View {
    @Bindable var settingsStore: SettingsStore
    let appSupportPaths: AppSupportPaths
    var onChange: (() -> Void)? = nil
    var onAutomationChanged: (() -> Void)? = nil
    var onResetMovingWarnings: (() -> Void)? = nil
    var onOpenSection: ((SettingsSection) -> Void)? = nil

    @State private var showCollapsedOverride: Bool
    @State private var showIconMovingConfirmation = false

    init(
        settingsStore: SettingsStore,
        appSupportPaths: AppSupportPaths,
        onChange: (() -> Void)? = nil,
        onAutomationChanged: (() -> Void)? = nil,
        onResetMovingWarnings: (() -> Void)? = nil,
        onOpenSection: ((SettingsSection) -> Void)? = nil
    ) {
        self.settingsStore = settingsStore
        self.appSupportPaths = appSupportPaths
        self.onChange = onChange
        self.onAutomationChanged = onAutomationChanged
        self.onResetMovingWarnings = onResetMovingWarnings
        self.onOpenSection = onOpenSection
        _showCollapsedOverride = State(initialValue: settingsStore.collapsedSeparatorLengthOverride != nil)
    }

    var body: some View {
        ClearGlassSettingsPage(
            "Advanced",
            subtitle: "Low-level layout, diagnostics, and experimental automation controls.",
            badges: [.privacySafe, .diagnostics, .labs, .experimental]
        ) {
            AdvancedOverviewStrip(settingsStore: settingsStore)

            AdvancedFeatureDirectorySection(
                showDogfood: showsDogfoodDirectoryEntry,
                onOpenSection: onOpenSection
            )

            SeparatorGeometrySection(
                settingsStore: settingsStore,
                showCollapsedOverride: $showCollapsedOverride,
                onChange: onChange
            )

            RecoveryAndDiagnosticsSection(
                appSupportPaths: appSupportPaths,
                onRevealDiagnosticsFolder: revealDiagnosticsFolder
            )

            IconMovingLabsSection(
                settingsStore: settingsStore,
                iconMovingEnabled: iconMovingEnabledBinding,
                onAutomationChanged: onAutomationChanged,
                onResetMovingWarnings: onResetMovingWarnings
            )

            DeveloperNotesSection()
        }
        .onIconMovingSettingsChanges(from: settingsStore, perform: onChange)
        .confirmationDialog(
            "Enable experimental icon moving?",
            isPresented: $showIconMovingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Enable Experimental Icon Moving") {
                settingsStore.iconMovingEnabled = true
                onChange?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Experimental: uses simulated Command-drag and may fail depending on macOS, display layout, and third-party menu bar apps.")
        }
    }

    private var iconMovingEnabledBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.iconMovingEnabled },
            set: { newValue in
                if newValue {
                    showIconMovingConfirmation = true
                } else {
                    settingsStore.iconMovingEnabled = false
                    onChange?()
                }
            }
        )
    }

    private var showsDogfoodDirectoryEntry: Bool {
        settingsStore.dogfoodModeEnabled || settingsStore.dogfoodRunID != nil
    }

    private func revealDiagnosticsFolder() {
        do {
            try appSupportPaths.ensureDirectoriesExist()
            NSWorkspace.shared.activateFileViewerSelecting([appSupportPaths.diagnosticsDirectory])
        } catch {
            NSWorkspace.shared.open(appSupportPaths.diagnosticsDirectory.deletingLastPathComponent())
        }
    }
}

enum AdvancedFeatureDirectory {
    static let entries: [AdvancedFeatureDirectoryEntry] = [
        AdvancedFeatureDirectoryEntry(
            title: "Workspaces Preview",
            subtitle: "Local Workspaces, Function Bar, Set Builder, and Info Strip previews.",
            status: .experimental,
            systemImage: "rectangle.3.group",
            destination: .workspacesPreview
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Profiles",
            subtitle: "Saved configurations and manual profile application.",
            status: .preview,
            systemImage: "person.crop.rectangle.stack",
            destination: .profiles
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Smart Triggers",
            subtitle: "Optional automation that can apply profiles.",
            status: .preview,
            systemImage: "link",
            destination: .profiles
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Dynamic Hotkeys",
            subtitle: "Advanced command, group, and profile shortcuts.",
            status: .preview,
            systemImage: "keyboard",
            destination: .hotkeys
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Private Access",
            subtitle: "Local authentication for protected surfaces.",
            status: .preview,
            systemImage: "lock.fill",
            destination: .privateAccess
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Groups",
            subtitle: "Lightweight collections and protected group actions.",
            status: .preview,
            systemImage: "person.2",
            destination: .groups
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Automation",
            subtitle: "App Shortcuts and URL command controls.",
            status: .preview,
            systemImage: "app.connected.to.app.below.fill",
            destination: .automation
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Import / Export",
            subtitle: "Backups, migration, and privacy-safe transfer.",
            status: .preview,
            systemImage: "arrow.up.arrow.down",
            destination: .importExport
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Diagnostics",
            subtitle: "Health checks, logs, and local support export.",
            status: .stable,
            systemImage: "waveform.path.ecg",
            destination: .diagnostics
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Dogfood",
            subtitle: "Internal QA notes and local dogfood bundles.",
            status: .internal,
            systemImage: "checklist",
            destination: .diagnostics
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Spacing Labs",
            subtitle: "Separator geometry, spacer previews, and spacing experiments.",
            status: .labs,
            systemImage: "ruler",
            destination: .layout
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Icon Moving",
            subtitle: "Explicit, confirmed experimental assisted movement.",
            status: .experimental,
            systemImage: "arrow.up.left.and.arrow.down.right",
            destination: nil
        )
    ]

    static func visibleEntries(showDogfood: Bool) -> [AdvancedFeatureDirectoryEntry] {
        entries.filter { showDogfood || $0.title != "Dogfood" }
    }
}

struct AdvancedFeatureDirectoryEntry: Identifiable {
    let title: String
    let subtitle: String
    let status: ProductFeatureStatus
    let systemImage: String
    let destination: SettingsSection?

    var id: String { title }
}

private struct AdvancedFeatureDirectorySection: View {
    let showDogfood: Bool
    var onOpenSection: ((SettingsSection) -> Void)?

    private let columns = [
        GridItem(.adaptive(minimum: 230), spacing: 10)
    ]

    var body: some View {
        ClearGlassSection(
            "Advanced Feature Directory",
            subtitle: "Power-user and experimental surfaces stay available without crowding the main settings flow."
        ) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(AdvancedFeatureDirectory.visibleEntries(showDogfood: showDogfood)) { entry in
                    AdvancedFeatureDirectoryCard(entry: entry) {
                        if let destination = entry.destination {
                            onOpenSection?(destination)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .accessibilityIdentifier("advanced.featureDirectory")
    }
}

private struct AdvancedFeatureDirectoryCard: View {
    let entry: AdvancedFeatureDirectoryEntry
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: entry.systemImage)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(statusTint)
                        .frame(width: 22, height: 22)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(entry.title)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)

                            Text(entry.status.title)
                                .font(.caption2)
                                .foregroundStyle(statusTint)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(statusTint.opacity(0.12), in: .capsule)
                        }

                        Text(entry.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 6) {
                    Text(entry.destination == nil ? "Current Page" : "Open")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Image(systemName: entry.destination == nil ? "checkmark.circle" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
            .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.46), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .disabled(entry.destination == nil)
        .accessibilityLabel(entry.title)
    }

    private var statusTint: Color {
        switch entry.status {
        case .stable:
            .green
        case .preview:
            .blue
        case .labs:
            .purple
        case .experimental:
            .orange
        case .deferred:
            .secondary
        case .internal:
            .gray
        }
    }
}

private struct AdvancedOverviewStrip: View {
    @Bindable var settingsStore: SettingsStore

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            AdvancedOverviewPill(
                title: "Expanded",
                value: settingsStore.expandedSeparatorLength.formatted(.number.precision(.fractionLength(0))) + " pt",
                systemImage: "ruler",
                style: .secondary
            )

            AdvancedOverviewPill(
                title: "Collapsed",
                value: settingsStore.collapsedSeparatorLengthOverride == nil ? "Auto" : "Custom",
                systemImage: "arrow.left.and.right",
                style: settingsStore.collapsedSeparatorLengthOverride == nil ? .success : .info
            )

            AdvancedOverviewPill(
                title: "Automation",
                value: settingsStore.automationPaused ? "Paused" : "Ready",
                systemImage: settingsStore.automationPaused ? "pause.circle" : "checkmark.circle",
                style: settingsStore.automationPaused ? .warning : .success
            )

            AdvancedOverviewPill(
                title: "Icon Moving",
                value: settingsStore.iconMovingEnabled ? "On" : "Off",
                systemImage: "arrow.up.left.and.arrow.down.right",
                style: settingsStore.iconMovingEnabled ? .warning : .secondary
            )
        }
    }
}

private struct AdvancedOverviewPill: View {
    let title: String
    let value: String
    let systemImage: String
    var style: ClearGlassStatusStyle

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

// MARK: - Separator Geometry

private struct SeparatorGeometrySection: View {
    @Bindable var settingsStore: SettingsStore
    @Binding var showCollapsedOverride: Bool
    var onChange: (() -> Void)?

    var body: some View {
        ClearGlassSection(
            "Separator Geometry",
            subtitle: "Fine-tune how separators are rendered in the menu bar."
        ) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    SeparatorControlsPanel(
                        settingsStore: settingsStore,
                        showCollapsedOverride: $showCollapsedOverride,
                        onChange: onChange
                    )
                    .frame(minWidth: 380, maxWidth: .infinity)

                    SeparatorPreviewPanel(
                        expandedLength: settingsStore.expandedSeparatorLength,
                        collapsedLength: settingsStore.collapsedSeparatorLengthOverride
                    )
                    .frame(width: 300)
                }
                .padding(.vertical, 8)

                VStack(spacing: 12) {
                    SeparatorControlsPanel(
                        settingsStore: settingsStore,
                        showCollapsedOverride: $showCollapsedOverride,
                        onChange: onChange
                    )

                    SeparatorPreviewPanel(
                        expandedLength: settingsStore.expandedSeparatorLength,
                        collapsedLength: settingsStore.collapsedSeparatorLengthOverride
                    )
                }
                .padding(.vertical, 8)
            }
        }
        .accessibilityIdentifier("advanced.separatorGeometry")
    }
}

private struct SeparatorControlsPanel: View {
    @Bindable var settingsStore: SettingsStore
    @Binding var showCollapsedOverride: Bool
    var onChange: (() -> Void)?

    var body: some View {
        AdvancedInspectorPanel(
            title: "Geometry Controls",
            subtitle: "Point values used by app-owned separator items.",
            systemImage: "ruler"
        ) {
            VStack(spacing: 0) {
                ClearGlassSliderRow(
                    "Expanded separator length",
                    value: $settingsStore.expandedSeparatorLength,
                    in: 1...200,
                    step: 1,
                    valueSuffix: "pt",
                    valueFractionLength: 0
                )

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "arrow.left.and.right",
                    title: "Use custom collapsed separator length",
                    subtitle: "Override the automatic collapsed length computed from the widest screen."
                ) {
                    Toggle("Use custom collapsed separator length", isOn: $showCollapsedOverride)
                        .labelsHidden()
                        .onChange(of: showCollapsedOverride) { _, newValue in
                            if newValue {
                                settingsStore.collapsedSeparatorLengthOverride = 2000
                            } else {
                                settingsStore.collapsedSeparatorLengthOverride = nil
                            }
                            onChange?()
                        }
                }

                if showCollapsedOverride {
                    ClearGlassDivider()

                    ClearGlassSliderRow(
                        "Custom collapsed length",
                        value: Binding(
                            get: { settingsStore.collapsedSeparatorLengthOverride ?? 2000 },
                            set: { settingsStore.collapsedSeparatorLengthOverride = $0 }
                        ),
                        in: AppConstants.collapsedSeparatorMinimumLength...AppConstants.collapsedSeparatorMaximumLength,
                        step: 50,
                        valueSuffix: "pt",
                        valueFractionLength: 0,
                        valueWidth: 78
                    )
                    .onChange(of: settingsStore.collapsedSeparatorLengthOverride) { _, _ in onChange?() }
                }
            }

            AdvancedPanelDivider()

            ClearGlassInlineMessage(
                text: "When the override is disabled, the collapsed length recomputes from the widest screen.",
                systemImage: "info.circle",
                style: .secondary
            )
        }
    }
}

private struct SeparatorPreviewPanel: View {
    let expandedLength: Double
    let collapsedLength: Double?

    var body: some View {
        AdvancedInspectorPanel(
            title: "Preview",
            subtitle: "Measured in menu bar points.",
            systemImage: "menubar.rectangle"
        ) {
            SeparatorGeometryPreview(
                expandedLength: expandedLength,
                collapsedLength: collapsedLength
            )
        }
    }
}

private struct SeparatorGeometryPreview: View {
    let expandedLength: Double
    let collapsedLength: Double?

    private let icons = ["wifi", "battery.100", "cloud", "magnifyingglass"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            geometryLine("Expanded", length: expandedLength, icons: icons)

            AdvancedPanelDivider()

            geometryLine(
                "Collapsed",
                length: collapsedLength ?? AppConstants.collapsedSeparatorMinimumLength,
                icons: Array(icons.prefix(3))
            )
        }
        .accessibilityElement(children: .combine)
    }

    private func geometryLine(_ title: String, length: Double, icons: [String]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(length, format: .number.precision(.fractionLength(0))) pt")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                ForEach(icons, id: \.self) { icon in
                    Image(systemName: icon)
                        .foregroundStyle(.secondary)
                }

                Rectangle()
                    .fill(.blue)
                    .frame(width: 2, height: 22)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.55), in: .rect(cornerRadius: 7))
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.36), lineWidth: 0.5)
            }
        }
    }
}

// MARK: - Recovery and Diagnostics

private struct RecoveryAndDiagnosticsSection: View {
    let appSupportPaths: AppSupportPaths
    let onRevealDiagnosticsFolder: () -> Void

    var body: some View {
        ClearGlassSection(
            "Recovery & Diagnostics",
            subtitle: "Read-only paths and identifiers used for support."
        ) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ApplicationSupportPanel(
                        appSupportPaths: appSupportPaths,
                        onRevealDiagnosticsFolder: onRevealDiagnosticsFolder
                    )
                    .frame(minWidth: 360, maxWidth: .infinity)

                    DiagnosticsMetadataPanel()
                        .frame(minWidth: 300, maxWidth: .infinity)
                }
                .padding(.vertical, 8)

                VStack(spacing: 12) {
                    ApplicationSupportPanel(
                        appSupportPaths: appSupportPaths,
                        onRevealDiagnosticsFolder: onRevealDiagnosticsFolder
                    )

                    DiagnosticsMetadataPanel()
                }
                .padding(.vertical, 8)
            }
        }
    }
}

private struct ApplicationSupportPanel: View {
    let appSupportPaths: AppSupportPaths
    let onRevealDiagnosticsFolder: () -> Void

    var body: some View {
        AdvancedInspectorPanel(
            title: "Application Support",
            subtitle: "File system locations used by the app.",
            systemImage: "folder"
        ) {
            AdvancedInspectorRow("Diagnostics Directory") {
                Text(appSupportPaths.diagnosticsDirectory.path)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                    .multilineTextAlignment(.trailing)
                    .help(appSupportPaths.diagnosticsDirectory.path)
            }

            AdvancedPanelDivider()

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Reveal Diagnostics Folder")
                        .font(.body)

                    Text("Open the diagnostics directory in Finder.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Button("Reveal", systemImage: "folder", action: onRevealDiagnosticsFolder)
            }
        }
    }
}

private struct DiagnosticsMetadataPanel: View {
    var body: some View {
        AdvancedInspectorPanel(
            title: "Diagnostics",
            subtitle: "Build and logging metadata.",
            systemImage: "waveform.path.ecg"
        ) {
            AdvancedInspectorRow("Ring Buffer Capacity", subtitle: "Maximum log events kept in memory.") {
                Text("\(AppConstants.diagnosticsRingBufferLimit) events")
                    .font(.system(.body, design: .monospaced))
            }

            AdvancedPanelDivider()

            AdvancedInspectorRow("Bundle Identifier", subtitle: "Used in logs and diagnostics.") {
                Text(AppConstants.bundleIdentifier)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                    .multilineTextAlignment(.trailing)
                    .help(AppConstants.bundleIdentifier)
            }
        }
    }
}

// MARK: - Labs

private struct IconMovingLabsSection: View {
    @Bindable var settingsStore: SettingsStore
    @Binding var iconMovingEnabled: Bool
    var onAutomationChanged: (() -> Void)?
    var onResetMovingWarnings: (() -> Void)?

    var body: some View {
        ClearGlassSection(
            "Labs / Experimental",
            subtitle: "Automation features that may fail depending on system state."
        ) {
            VStack(spacing: 0) {
                FeatureGateNotice(
                    .experimental,
                    text: "Icon Moving is Experimental in v0.1.3. It is disabled by default and only runs from explicit user action after confirmation."
                )

                ClearGlassDivider()

                ClearGlassInlineMessage(
                    text: "These features are experimental and may change or break in future updates. Use at your own risk.",
                    systemImage: "testtube.2",
                    style: .warning
                )
                .padding(.vertical, 10)

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 12) {
                        AutomationRecoveryPanel(
                            automationPaused: $settingsStore.automationPaused,
                            onAutomationChanged: onAutomationChanged,
                            onResetMovingWarnings: onResetMovingWarnings
                        )
                        .frame(minWidth: 300, maxWidth: .infinity)

                        IconMovingControlsPanel(
                            settingsStore: settingsStore,
                            iconMovingEnabled: $iconMovingEnabled
                        )
                        .frame(minWidth: 360, maxWidth: .infinity)
                    }

                    VStack(spacing: 12) {
                        AutomationRecoveryPanel(
                            automationPaused: $settingsStore.automationPaused,
                            onAutomationChanged: onAutomationChanged,
                            onResetMovingWarnings: onResetMovingWarnings
                        )

                        IconMovingControlsPanel(
                            settingsStore: settingsStore,
                            iconMovingEnabled: $iconMovingEnabled
                        )
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .accessibilityIdentifier("advanced.labs")
    }
}

private struct AutomationRecoveryPanel: View {
    @Binding var automationPaused: Bool
    var onAutomationChanged: (() -> Void)?
    var onResetMovingWarnings: (() -> Void)?

    var body: some View {
        AdvancedInspectorPanel(
            title: "Recovery",
            subtitle: "Pause automation or clear moving warnings.",
            systemImage: "wrench.and.screwdriver"
        ) {
            ClearGlassControlRow(
                systemImage: "pause.circle",
                title: "Pause all automation",
                subtitle: "Temporarily stop all automation actions."
            ) {
                Toggle("Pause all automation", isOn: $automationPaused)
                    .labelsHidden()
                    .onChange(of: automationPaused) { _, _ in onAutomationChanged?() }
            }

            AdvancedPanelDivider()

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Reset moving warnings")
                        .font(.body)

                    Text("Clear all icon-moving warning suppressions.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Button("Reset", systemImage: "arrow.counterclockwise") {
                    onResetMovingWarnings?()
                }
            }
            .padding(.vertical, 9)
        }
    }
}

private struct IconMovingControlsPanel: View {
    @Bindable var settingsStore: SettingsStore
    @Binding var iconMovingEnabled: Bool

    var body: some View {
        AdvancedInspectorPanel(
            title: "Icon Moving",
            subtitle: settingsStore.iconMovingEnabled ? "Experimental moving controls are enabled." : "Disabled until confirmed.",
            systemImage: "arrow.up.left.and.arrow.down.right",
            iconTint: settingsStore.iconMovingEnabled ? .orange : .secondary
        ) {
            VStack(spacing: 0) {
                ClearGlassControlRow(
                    systemImage: "arrow.up.left.and.arrow.down.right",
                    title: "Enable icon moving",
                    subtitle: "Allow explicit simulated Command-drag moves between menu bar locations.",
                    iconTint: .orange
                ) {
                    Toggle("Enable icon moving", isOn: $iconMovingEnabled)
                        .labelsHidden()
                }

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "checkmark.shield",
                    title: "Require confirmation before moving",
                    subtitle: "Ask before completing a move."
                ) {
                    Toggle("Require confirmation before moving", isOn: $settingsStore.iconMovingRequireConfirmation)
                        .labelsHidden()
                        .disabled(!settingsStore.iconMovingEnabled)
                }
                .opacity(settingsStore.iconMovingEnabled ? 1 : 0.55)

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "arrow.clockwise",
                    title: "Max retries",
                    subtitle: "Attempts to complete a move before giving up."
                ) {
                    HStack(spacing: 10) {
                        Text("\(settingsStore.iconMovingMaxRetries)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .trailing)

                        Stepper(
                            "Max retries",
                            value: $settingsStore.iconMovingMaxRetries,
                            in: AppConstants.minIconMovingMaxRetries...AppConstants.maxIconMovingMaxRetries
                        )
                        .labelsHidden()
                    }
                    .disabled(!settingsStore.iconMovingEnabled)
                }
                .opacity(settingsStore.iconMovingEnabled ? 1 : 0.55)

                ClearGlassDivider()

                ClearGlassSliderRow(
                    "Drag duration",
                    subtitle: "Duration of the drag animation.",
                    value: $settingsStore.iconMovingDragDuration,
                    in: AppConstants.minIconMovingDragDuration...AppConstants.maxIconMovingDragDuration,
                    step: 0.05,
                    valueSuffix: "s",
                    valueFractionLength: 2
                )
                .disabled(!settingsStore.iconMovingEnabled)
                .opacity(settingsStore.iconMovingEnabled ? 1 : 0.55)

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "apple.logo",
                    title: "Allow moving system items",
                    subtitle: "Allow moving menu bar items provided by macOS."
                ) {
                    Toggle("Allow moving system items", isOn: $settingsStore.iconMovingAllowSystemItems)
                        .labelsHidden()
                        .disabled(!settingsStore.iconMovingEnabled)
                }
                .opacity(settingsStore.iconMovingEnabled ? 1 : 0.55)
            }
        }
    }
}

private struct DeveloperNotesSection: View {
    var body: some View {
        ClearGlassSection(
            "Developer Notes",
            subtitle: "Advanced settings are intended for advanced users and developers."
        ) {
            ClearGlassInlineMessage(
                text: "Icon moving is Pro-only and only runs after an explicit menu action. It simulates Command-drag and may fail for some apps or system items.",
                systemImage: "exclamationmark.triangle",
                style: .warning
            )
        }
        .accessibilityIdentifier("advanced.developerNotes")
    }
}

// MARK: - Shared Advanced Helpers

private struct AdvancedInspectorPanel<Content: View>: View {
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

private struct AdvancedInspectorRow<Value: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let value: Value

    init(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder value: () -> Value
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 12)

            value
                .foregroundStyle(.secondary)
                .frame(maxWidth: 340, alignment: .trailing)
        }
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AdvancedPanelDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor).opacity(0.42))
            .frame(height: 0.5)
    }
}

#Preview {
    AdvancedSettingsView(
        settingsStore: SettingsStore(),
        appSupportPaths: AppSupportPaths()
    )
}
