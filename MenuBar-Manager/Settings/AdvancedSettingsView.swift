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
            subtitle: "Low-level separator, local path, and Labs controls.",
            badges: [.privacySafe, .diagnostics, .labs],
            style: .tool,
            sectionAnchors: [
                ClearGlassPageAnchor("Advanced-only", systemImage: "list.bullet.rectangle", targetID: "Advanced-Only Controls"),
                ClearGlassPageAnchor("Separators", systemImage: "ruler", targetID: "Separator Geometry"),
                ClearGlassPageAnchor("Diagnostics", systemImage: "waveform.path.ecg", targetID: "Recovery & Diagnostics"),
                ClearGlassPageAnchor("Labs", systemImage: "testtube.2", targetID: "Labs"),
                ClearGlassPageAnchor("Notes", systemImage: "exclamationmark.triangle", targetID: "Developer Notes")
            ]
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
        .onChange(of: settingsStore.collapsedSeparatorLengthOverride) { _, newValue in
            let shouldShowOverride = newValue != nil
            if showCollapsedOverride != shouldShowOverride {
                showCollapsedOverride = shouldShowOverride
            }
        }
        .confirmationDialog(
            "Enable Labs icon moving?",
            isPresented: $showIconMovingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Enable Labs Icon Moving") {
                settingsStore.iconMovingEnabled = true
                onChange?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Labs: uses simulated Command-drag and may fail depending on macOS, display layout, and third-party menu bar apps.")
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
            title: "Workspaces",
            subtitle: "Local Workspaces, Function Bar, Set Builder, and Info Strip previews.",
            status: .preview,
            category: .previews,
            systemImage: "rectangle.3.group",
            destination: .workspacesPreview
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Profiles",
            subtitle: "Saved configurations and manual profile application.",
            status: .preview,
            category: .previews,
            systemImage: "person.crop.rectangle.stack",
            destination: .profiles
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Smart Triggers",
            subtitle: "Optional automation that can apply profiles.",
            status: .preview,
            category: .previews,
            systemImage: "link",
            destination: .profiles
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Dynamic Hotkeys",
            subtitle: "Advanced command, group, and profile shortcuts.",
            status: .preview,
            category: .previews,
            systemImage: "keyboard",
            destination: .hotkeys
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Private Access",
            subtitle: "Local authentication for protected surfaces.",
            status: .preview,
            category: .previews,
            systemImage: "lock.fill",
            destination: .privateAccess
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Groups",
            subtitle: "Lightweight collections and protected group actions.",
            status: .preview,
            category: .previews,
            systemImage: "person.2",
            destination: .groups
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Automation",
            subtitle: "App Shortcuts and URL command controls.",
            status: .preview,
            category: .previews,
            systemImage: "app.connected.to.app.below.fill",
            destination: .automation
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Import / Export",
            subtitle: "Backups, migration, and privacy-safe transfer.",
            status: .preview,
            category: .previews,
            systemImage: "arrow.up.arrow.down",
            destination: .importExport
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Diagnostics",
            subtitle: "Health checks, logs, and local support export.",
            status: .stable,
            category: .stable,
            systemImage: "waveform.path.ecg",
            destination: .diagnostics
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Dogfood",
            subtitle: "Internal QA notes and local dogfood bundles.",
            status: .labs,
            category: .labs,
            systemImage: "checklist",
            destination: .diagnostics
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Spacing Labs",
            subtitle: "Separator geometry, spacer previews, and spacing experiments.",
            status: .labs,
            category: .labs,
            systemImage: "ruler",
            destination: .layout
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Icon Moving",
            subtitle: "Explicit, confirmed Labs assisted movement.",
            status: .labs,
            category: .labs,
            systemImage: "arrow.up.left.and.arrow.down.right",
            destination: nil
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Stable Bulk Moving",
            subtitle: "Future hardened move orchestration once Labs behavior proves reliable.",
            status: .deferred,
            category: .deferred,
            systemImage: "arrow.left.arrow.right.square",
            destination: nil
        ),
        AdvancedFeatureDirectoryEntry(
            title: "Visual Item Capture",
            subtitle: "Deferred research. Not used by Basic Mode and not requested today.",
            status: .deferred,
            category: .deferred,
            systemImage: "camera.viewfinder",
            destination: nil
        )
    ]

    static func searchAliasEntries(showDogfood: Bool) -> [AdvancedFeatureDirectoryEntry] {
        entries.filter { showDogfood || $0.title != "Dogfood" }
    }

    static func visibleGroups(showDogfood: Bool) -> [AdvancedFeatureDirectoryGroup] {
        let visibleEntries = entries
            .filter { showDogfood || $0.title != "Dogfood" }
            .filter(\.belongsOnAdvancedPage)

        return AdvancedFeatureDirectoryCategory.allCases.compactMap { category in
            let categoryEntries = visibleEntries.filter { $0.category == category }
            guard categoryEntries.isEmpty == false else { return nil }
            return AdvancedFeatureDirectoryGroup(category: category, entries: categoryEntries)
        }
    }

    static func visibleEntries(showDogfood: Bool) -> [AdvancedFeatureDirectoryEntry] {
        visibleGroups(showDogfood: showDogfood).flatMap(\.entries)
    }
}

struct AdvancedFeatureDirectoryEntry: Identifiable {
    let title: String
    let subtitle: String
    let status: ProductFeatureStatus
    let category: AdvancedFeatureDirectoryCategory
    let systemImage: String
    let destination: SettingsSection?

    var id: String { title }

    var belongsOnAdvancedPage: Bool {
        guard let destination else { return true }
        let sidebarSections = SettingsSection.visibleSidebarSections + SettingsSection.moreSidebarSections
        return !sidebarSections.contains(destination)
    }
}

struct AdvancedFeatureDirectoryGroup: Identifiable {
    let category: AdvancedFeatureDirectoryCategory
    let entries: [AdvancedFeatureDirectoryEntry]

    var id: String { category.id }
}

enum AdvancedFeatureDirectoryCategory: String, CaseIterable, Identifiable {
    case stable
    case previews
    case labs
    case deferred

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stable:
            "Stable"
        case .previews:
            "Preview"
        case .labs:
            "Labs"
        case .deferred:
            "Deferred"
        }
    }

    var subtitle: String {
        switch self {
        case .stable:
            "Ready support and diagnostic surfaces."
        case .previews:
            "Opt-in surfaces that stay local and reversible."
        case .labs:
            "Labs controls for advanced users."
        case .deferred:
            "Tracked ideas with no active control surface yet."
        }
    }
}

private struct AdvancedFeatureDirectorySection: View {
    let showDogfood: Bool
    var onOpenSection: ((SettingsSection) -> Void)?

    var body: some View {
        let groups = AdvancedFeatureDirectory.visibleGroups(showDogfood: showDogfood)

        ClearGlassSection(
            "Advanced-Only Controls",
            subtitle: "Sidebar pages now live in their canonical locations; this page keeps only Advanced-owned controls."
        ) {
            VStack(spacing: 0) {
                ForEach(Array(groups.enumerated()), id: \.element.id) { offset, group in
                    AdvancedFeatureDirectoryGroupView(group: group, onOpenSection: onOpenSection)

                    if offset < groups.count - 1 {
                        AdvancedPanelDivider()
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityIdentifier("advanced.featureDirectory")
    }
}

private struct AdvancedFeatureDirectoryGroupView: View {
    let group: AdvancedFeatureDirectoryGroup
    var onOpenSection: ((SettingsSection) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(group.category.title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Text(group.category.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 2)
            .padding(.top, 6)

            VStack(spacing: 0) {
                ForEach(group.entries) { entry in
                    AdvancedFeatureDirectoryRow(entry: entry, onOpenSection: onOpenSection)

                    if entry.id != group.entries.last?.id {
                        AdvancedPanelDivider()
                    }
                }
            }
        }
    }
}

private struct AdvancedFeatureDirectoryRow: View {
    let entry: AdvancedFeatureDirectoryEntry
    var onOpenSection: ((SettingsSection) -> Void)?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 12) {
                rowLabel

                Spacer(minLength: 16)

                ClearGlassAccessoryCluster {
                    actionView
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                rowLabel
                ClearGlassAccessoryCluster {
                    actionView
                }
            }
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .contain)
    }

    private var rowLabel: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: entry.systemImage)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(entry.status.directoryTint)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(entry.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    AdvancedDirectoryStatusBadge(status: entry.status)
                }

                Text(entry.subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var actionView: some View {
        if let destination = entry.destination {
            Button("Open", systemImage: "arrow.up.right") {
                onOpenSection?(destination)
            }
            .controlSize(.small)
        } else if entry.status == .deferred {
            Label("Deferred", systemImage: "clock")
                .font(.callout)
                .foregroundStyle(.secondary)
        } else {
            Label("Current Page", systemImage: "checkmark.circle")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

private struct AdvancedDirectoryStatusBadge: View {
    let status: ProductFeatureStatus

    var body: some View {
        Label(status.title, systemImage: status.directorySystemImage)
            .font(.caption2)
            .foregroundStyle(status.directoryTint)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(status.directoryTint.opacity(0.10), in: .capsule)
            .overlay {
                Capsule()
                    .stroke(status.directoryTint.opacity(0.22), lineWidth: 0.5)
            }
            .fixedSize()
    }
}

private extension ProductFeatureStatus {
    var directoryTint: Color {
        switch self {
        case .stable:
            .green
        case .preview:
            .blue
        case .labs:
            .purple
        case .experimental:
            .purple
        case .deferred:
            .secondary
        case .internal:
            .gray
        }
    }

    var directorySystemImage: String {
        switch self {
        case .stable:
            "checkmark.circle"
        case .preview:
            "sparkles"
        case .labs:
            "testtube.2"
        case .experimental:
            "exclamationmark.triangle"
        case .deferred:
            "clock"
        case .internal:
            "checklist"
        }
    }
}

private struct AdvancedOverviewStrip: View {
    @Bindable var settingsStore: SettingsStore

    var body: some View {
        ClearGlassOverviewStrip([
            ClearGlassOverviewMetric(
                title: "Expanded",
                value: settingsStore.expandedSeparatorLength.formatted(.number.precision(.fractionLength(0))) + " pt",
                systemImage: "ruler",
                style: .secondary
            ),
            ClearGlassOverviewMetric(
                title: "Collapsed",
                value: settingsStore.collapsedSeparatorLengthOverride == nil ? "Auto" : "Custom",
                systemImage: "arrow.left.and.right",
                style: settingsStore.collapsedSeparatorLengthOverride == nil ? .success : .info
            ),
            ClearGlassOverviewMetric(
                title: "Automation",
                value: settingsStore.automationPaused ? "Paused" : "Ready",
                systemImage: settingsStore.automationPaused ? "pause.circle" : "checkmark.circle",
                style: settingsStore.automationPaused ? .warning : .success
            ),
            ClearGlassOverviewMetric(
                title: "Icon Moving",
                value: settingsStore.iconMovingEnabled ? "On" : "Off",
                systemImage: "arrow.up.left.and.arrow.down.right",
                style: settingsStore.iconMovingEnabled ? .warning : .secondary
            )
        ])
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
        ClearGlassInspectorPanel(
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
        ClearGlassInspectorPanel(
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
        ClearGlassInspectorPanel(
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
        ClearGlassInspectorPanel(
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
            "Labs",
            subtitle: "Automation features that may fail depending on system state."
        ) {
            VStack(spacing: 0) {
                FeatureGateNotice(
                    .experimental,
                    text: "Icon Moving is in Labs for v0.1.3. It is disabled by default and only runs from explicit user action after confirmation."
                )

                ClearGlassDivider()

                ClearGlassInlineMessage(
                    text: "These Labs features may change or break in future updates. Use at your own risk.",
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
        ClearGlassInspectorPanel(
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
        ClearGlassInspectorPanel(
            title: "Icon Moving",
            subtitle: settingsStore.iconMovingEnabled ? "Labs moving controls are enabled." : "Disabled until confirmed.",
            systemImage: "arrow.up.left.and.arrow.down.right",
            iconTint: settingsStore.iconMovingEnabled ? .purple : .secondary
        ) {
            VStack(spacing: 0) {
                ClearGlassControlRow(
                    systemImage: "arrow.up.left.and.arrow.down.right",
                    title: "Enable icon moving",
                    subtitle: "Allow explicit simulated Command-drag moves between menu bar locations.",
                    iconTint: .purple
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
                .opacity(settingsStore.iconMovingEnabled ? 1 : 0.72)

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
                .opacity(settingsStore.iconMovingEnabled ? 1 : 0.72)

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
                .opacity(settingsStore.iconMovingEnabled ? 1 : 0.72)

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
                .opacity(settingsStore.iconMovingEnabled ? 1 : 0.72)
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
                text: "Icon moving is Optional Pro and only runs after an explicit menu action. It simulates Command-drag and may fail for some apps or system items.",
                systemImage: "exclamationmark.triangle",
                style: .warning
            )
        }
        .accessibilityIdentifier("advanced.developerNotes")
    }
}

// MARK: - Shared Advanced Helpers

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
