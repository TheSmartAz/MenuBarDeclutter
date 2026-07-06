import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DiagnosticsSettingsView: View {
    @Bindable var diagnosticsLogger: DiagnosticsLogger
    var liveStatus: LiveDiagnosticsStatus?
    let appSupportPaths: AppSupportPaths
    let exporter: DiagnosticsExporter
    @Bindable var dogfoodStore: DogfoodStore
    @Bindable var settingsStore: SettingsStore
    var launchAtLoginService: LaunchAtLoginService? = nil
    var scanCoordinator: MenuBarScanCoordinator?
    var onRunHealthCheck: (() -> Void)?
    var onFixHealthIssues: (() -> Void)?
    var onResetBasicMode: (() -> Void)?
    var onDisableProMode: (() -> Void)?
    var onEnterSafeModeNextLaunch: (() -> Void)?
    var secondBarReadinessDiagnosticsProvider: (() -> DiagnosticsExporter.SecondBarReadinessDiagnosticsSnapshot?)? = nil
    var secondBarRuntimeDiagnosticsProvider: (() -> DiagnosticsExporter.SecondBarRuntimeDiagnosticsSnapshot?)? = nil
    var workspacePreviewDiagnosticsProvider: (() -> DiagnosticsExporter.WorkspacePreviewDiagnosticsSnapshot?)? = nil

    @State private var exportFormat: DiagnosticsExporter.Format = .txt
    @State private var exportError: String?
    @State private var lastExportedURL: URL?
    @State private var severityFilter: DiagnosticSeverityFilter = .all
    @State private var selectedCategory: DiagnosticCategory?
    @State private var selectedEventID: DiagnosticEvent.ID?
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    private var filteredEvents: [DiagnosticEvent] {
        diagnosticsLogger.events.matching(
            severityFilter: severityFilter,
            selectedCategory: selectedCategory
        )
    }

    private var selectedEvent: DiagnosticEvent? {
        filteredEvents.first { $0.id == selectedEventID }
    }

    private var showsDogfoodPanel: Bool {
        settingsStore.dogfoodModeEnabled
            || settingsStore.dogfoodRunID != nil
            || dogfoodStore.currentRun != nil
    }

    private var pageSectionAnchors: [ClearGlassPageAnchor] {
        var anchors: [ClearGlassPageAnchor] = []

        if liveStatus != nil {
            anchors.append(ClearGlassPageAnchor("Summary", systemImage: "chart.bar.doc.horizontal"))
            anchors.append(ClearGlassPageAnchor("Health", systemImage: "stethoscope"))
        }

        anchors.append(ClearGlassPageAnchor("Screens", systemImage: "display.2"))

        if showsDogfoodPanel {
            anchors.append(ClearGlassPageAnchor("Dogfood", systemImage: "checklist"))
        }

        if liveStatus != nil {
            anchors.append(ClearGlassPageAnchor("Live Status", systemImage: "waveform.path.ecg"))
            anchors.append(ClearGlassPageAnchor("Items", systemImage: "menubar.rectangle", targetID: "Scanned Items"))
        }

        anchors.append(ClearGlassPageAnchor("Events", systemImage: "list.bullet.rectangle"))
        return anchors
    }

    var body: some View {
        VStack(spacing: 0) {
            DiagnosticsToolbar(
                diagnosticsLogger: diagnosticsLogger,
                clear: diagnosticsLogger.removeAll,
                exportFormat: $exportFormat,
                severityFilter: $severityFilter,
                selectedCategory: $selectedCategory,
                selectedEventID: $selectedEventID,
                onCopySelected: copySelectedEvent,
                onExport: exportCurrent
            )

            Divider()

            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    ClearGlassPageAnchorBar(anchors: pageSectionAnchors) { anchor in
                        scroll(to: anchor, using: proxy)
                    }
                    .padding(.horizontal, ClearGlassSettingsPageStyle.tool.horizontalPadding)
                    .padding(.vertical, 8)
                    .frame(maxWidth: ClearGlassSettingsPageStyle.tool.maxContentWidth, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: ClearGlassSettingsPageStyle.tool.contentSpacing) {
                            Color.clear
                                .frame(height: 0)
                                .id(ClearGlassPageAnchor.top.targetID)
                                .accessibilityHidden(true)

                            if let exportError {
                                ExportErrorBanner(message: exportError)
                            }

                            if let lastExportedURL {
                                ExportSuccessBanner(url: lastExportedURL)
                            }

                            if let liveStatus {
                                DiagnosticsSummaryStrip(liveStatus: liveStatus, settingsStore: settingsStore)
                                    .id("Summary")
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                if let liveStatus {
                                    HealthStatusSection(
                                        liveStatus: liveStatus,
                                        onRefresh: onRunHealthCheck,
                                        onFixAutomatically: onFixHealthIssues,
                                        onResetBasicMode: onResetBasicMode,
                                        onDisableProMode: onDisableProMode,
                                        onExportHealthReport: exportHealthReport,
                                        onEnterSafeModeNextLaunch: onEnterSafeModeNextLaunch
                                    )
                                    .id("Health")
                                }

                                ScreenStatusSection(screensProvider: exporter.screensProvider)
                                    .id("Screens")
                            }

                            if showsDogfoodPanel {
                                DiagnosticsPanel("Dogfood", systemImage: "checklist") {
                                    DogfoodNotesView(
                                        settingsStore: settingsStore,
                                        dogfoodStore: dogfoodStore,
                                        onExportBundle: exportDogfoodBundle
                                    )
                                }
                                .id("Dogfood")
                            }

                            if let liveStatus {
                                LiveStatusSection(
                                    liveStatus: liveStatus,
                                    settingsStore: settingsStore,
                                    launchAtLoginService: launchAtLoginService,
                                    scanCoordinator: scanCoordinator
                                )
                                .id("Live Status")
                            }

                            DiagnosticEventList(
                                diagnosticsLogger: diagnosticsLogger,
                                severityFilter: severityFilter,
                                selectedCategory: selectedCategory,
                                selectedEventID: $selectedEventID
                            )
                            .id("Events")
                        }
                        .padding(.horizontal, ClearGlassSettingsPageStyle.tool.horizontalPadding)
                        .padding(.top, ClearGlassSettingsPageStyle.tool.topPadding)
                        .padding(.bottom, ClearGlassSettingsPageStyle.tool.bottomPadding)
                        .frame(maxWidth: ClearGlassSettingsPageStyle.tool.maxContentWidth, alignment: .topLeading)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func scroll(to anchor: ClearGlassPageAnchor, using proxy: ScrollViewProxy) {
        if accessibilityReduceMotion {
            proxy.scrollTo(anchor.targetID, anchor: .top)
        } else {
            withAnimation(.easeInOut(duration: 0.22)) {
                proxy.scrollTo(anchor.targetID, anchor: .top)
            }
        }
    }

    private func exportCurrent() {
        // Ensure directories exist so a default save location works.
        let directory: URL
        do {
            try appSupportPaths.ensureDirectoriesExist()
            directory = appSupportPaths.diagnosticsDirectory
        } catch {
            exportError = "Could not prepare diagnostics directory: \(error.localizedDescription)"
            return
        }

        let timestamp = Self.filenameTimestamp()
        let suggestedName = "MenuBarDeclutter-diagnostics-\(timestamp).\(exportFormat.fileExtension)"

        let panel = NSSavePanel()
        panel.title = "Export Diagnostics"
        panel.allowedContentTypes = [Self.utType(for: exportFormat)]
        panel.nameFieldStringValue = suggestedName
        panel.directoryURL = directory

        presentSavePanel(panel) { url in
            guard let url else { return }

            let snapshot = exporter.makeSnapshot(
                settingsStore: settingsStore,
                logger: diagnosticsLogger,
                secondBarReadiness: secondBarReadinessDiagnosticsProvider?(),
                secondBarRuntime: secondBarRuntimeDiagnosticsProvider?(),
                workspacePreview: workspacePreviewDiagnosticsProvider?(),
                events: filteredEvents
            )
            do {
                let data = try exporter.serialize(
                    snapshot,
                    format: exportFormat,
                    includeAppSupportPath: false,
                    appSupportPath: nil
                )
                try data.write(to: url, options: .atomic)
                lastExportedURL = url
                exportError = nil
                diagnosticsLogger.log("Diagnostics exported to \(url.lastPathComponent).", level: .info)
            } catch {
                exportError = error.localizedDescription
                lastExportedURL = nil
                diagnosticsLogger.log("Diagnostics export failed: \(error.localizedDescription)", level: .error)
            }
        }
    }

    private func copySelectedEvent() {
        guard let selectedEvent else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(selectedEvent.formattedSummary, forType: .string)
        diagnosticsLogger.log("Diagnostic event copied.", level: .debug, category: .privacy)
    }

    private func exportHealthReport() {
        guard let report = liveStatus?.healthReport else {
            exportError = "No health report is available yet."
            return
        }

        let directory: URL
        do {
            try appSupportPaths.ensureDirectoriesExist()
            directory = appSupportPaths.diagnosticsDirectory
        } catch {
            exportError = "Could not prepare diagnostics directory: \(error.localizedDescription)"
            return
        }

        let timestamp = Self.filenameTimestamp()
        let suggestedName = "MenuBarDeclutter-health-\(timestamp).txt"

        let panel = NSSavePanel()
        panel.title = "Export Health Report"
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = suggestedName
        panel.directoryURL = directory

        presentSavePanel(panel) { url in
            guard let url else { return }

            do {
                try Data(report.plainText().utf8).write(to: url, options: .atomic)
                lastExportedURL = url
                exportError = nil
                diagnosticsLogger.log("Health report exported to \(url.lastPathComponent).", level: .info)
            } catch {
                exportError = error.localizedDescription
                lastExportedURL = nil
                diagnosticsLogger.log("Health report export failed: \(error.localizedDescription)", level: .error)
            }
        }
    }

    private func presentSavePanel(_ panel: NSSavePanel, completion: @escaping (URL?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) {
            let handler: (NSApplication.ModalResponse) -> Void = { response in
                completion(response == .OK ? panel.url : nil)
            }

            if let window = NSApplication.shared.keyWindow ?? NSApplication.shared.mainWindow {
                panel.beginSheetModal(for: window, completionHandler: handler)
            } else {
                panel.begin(completionHandler: handler)
            }
        }
    }

    private func exportDogfoodBundle() {
        do {
            try appSupportPaths.ensureDirectoriesExist()
            let snapshot = exporter.makeSnapshot(
                settingsStore: settingsStore,
                logger: diagnosticsLogger,
                secondBarReadiness: secondBarReadinessDiagnosticsProvider?(),
                secondBarRuntime: secondBarRuntimeDiagnosticsProvider?(),
                workspacePreview: workspacePreviewDiagnosticsProvider?()
            )
            let diagnosticsData = try exporter.serialize(snapshot, format: .txt)
            let metadata = DogfoodBundleMetadata(
                generatedAt: exporter.dateProvider(),
                appVersion: exporter.appVersionProvider(),
                marketingVersion: exporter.marketingVersionProvider(),
                buildNumber: exporter.buildNumberProvider(),
                bundleIdentifier: exporter.bundleIdentifierProvider(),
                macOSVersion: exporter.macOSVersionProvider(),
                architecture: exporter.architectureProvider(),
                screens: exporter.screensProvider()
            )
            let url = try dogfoodStore.exportBundle(
                diagnosticsData: diagnosticsData,
                healthReport: liveStatus?.healthReport,
                metadata: metadata
            )
            lastExportedURL = url
            exportError = nil
            diagnosticsLogger.log("Dogfood bundle exported to \(url.lastPathComponent).", level: .info)
        } catch {
            exportError = error.localizedDescription
            lastExportedURL = nil
            diagnosticsLogger.log("Dogfood bundle export failed: \(error.localizedDescription)", level: .error)
        }
    }

    private static func filenameTimestamp() -> String {
        filenameTimestampFormatter.string(from: Date())
    }

    @MainActor
    private static let filenameTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    private static func utType(for format: DiagnosticsExporter.Format) -> UTType {
        switch format {
        case .txt: return UTType.plainText
        case .json: return UTType.json
        }
    }
}

private enum DiagnosticSeverityFilter: String, CaseIterable, Identifiable {
    case all
    case warningsAndErrors

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:
            "All"
        case .warningsAndErrors:
            "Warnings/Errors"
        }
    }
}

private extension Array where Element == DiagnosticEvent {
    func matching(
        severityFilter: DiagnosticSeverityFilter,
        selectedCategory: DiagnosticCategory?
    ) -> [DiagnosticEvent] {
        filter { event in
            let severityMatches: Bool
            switch severityFilter {
            case .all:
                severityMatches = true
            case .warningsAndErrors:
                severityMatches = event.level == .warning || event.level == .error
            }

            let categoryMatches = selectedCategory.map { $0 == event.category } ?? true
            return severityMatches && categoryMatches
        }
    }
}

private struct DiagnosticsPanel<Accessory: View, Content: View>: View {
    let title: String
    let systemImage: String?
    let accessory: Accessory
    let content: Content

    init(
        _ title: String,
        systemImage: String? = nil,
        @ViewBuilder content: () -> Content
    ) where Accessory == EmptyView {
        self.title = title
        self.systemImage = systemImage
        self.accessory = EmptyView()
        self.content = content()
    }

    init(
        _ title: String,
        systemImage: String? = nil,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.accessory = accessory()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(.secondary)
                }

                Text(title)
                    .font(.headline)

                Spacer()

                accessory
            }

            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
        }
    }
}

private struct DiagnosticsStatusBadge: View {
    let title: String
    let systemImage: String
    var style: Color = .secondary

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .foregroundStyle(style)
            .background(style.opacity(0.12), in: .capsule)
            .overlay {
                Capsule()
                    .strokeBorder(style.opacity(0.25))
            }
    }
}

private struct DiagnosticsSummaryStrip: View {
    let liveStatus: LiveDiagnosticsStatus
    let settingsStore: SettingsStore

    var body: some View {
        ClearGlassOverviewStrip([
            ClearGlassOverviewMetric(
                title: "Visibility",
                value: liveStatus.visibilityState.rawValue,
                systemImage: "eye",
                style: .secondary
            ),
            ClearGlassOverviewMetric(
                title: "Accessibility",
                value: liveStatus.accessibilityPermissionStatus.displayName,
                systemImage: "accessibility",
                style: liveStatus.accessibilityPermissionStatus == .granted ? .success : .warning
            ),
            ClearGlassOverviewMetric(
                title: "Scanned",
                value: liveStatus.scannedMenuBarItems.count.formatted(.number),
                systemImage: "menubar.rectangle",
                style: liveStatus.scannedMenuBarItems.isEmpty ? .secondary : .info
            ),
            ClearGlassOverviewMetric(
                title: "Search Index",
                value: liveStatus.searchIndexItemCount.formatted(.number),
                systemImage: "magnifyingglass",
                style: liveStatus.searchIndexItemCount == 0 ? .secondary : .info
            ),
            ClearGlassOverviewMetric(
                title: "Second Bar",
                value: liveStatus.secondBarVisible ? "Visible" : "Hidden",
                systemImage: "rectangle.bottomthird.inset.filled",
                style: liveStatus.secondBarVisible ? .info : .secondary
            ),
            ClearGlassOverviewMetric(
                title: "Automation",
                value: (settingsStore.automationPaused || liveStatus.automationPaused) ? "Paused" : "Ready",
                systemImage: "pause.circle",
                style: (settingsStore.automationPaused || liveStatus.automationPaused) ? .warning : .success
            )
        ], maximumColumnCount: 3)
    }
}

private struct DiagnosticsToolbar: View {
    @Bindable var diagnosticsLogger: DiagnosticsLogger
    let clear: () -> Void
    @Binding var exportFormat: DiagnosticsExporter.Format
    @Binding var severityFilter: DiagnosticSeverityFilter
    @Binding var selectedCategory: DiagnosticCategory?
    @Binding var selectedEventID: DiagnosticEvent.ID?
    let onCopySelected: () -> Void
    let onExport: () -> Void

    private var eventCount: Int {
        diagnosticsLogger.events.count
    }

    private var filteredEventCount: Int {
        diagnosticsLogger.events.matching(
            severityFilter: severityFilter,
            selectedCategory: selectedCategory
        ).count
    }

    private var canCopySelected: Bool {
        guard let selectedEventID else { return false }
        return diagnosticsLogger.events.matching(
            severityFilter: severityFilter,
            selectedCategory: selectedCategory
        ).contains { $0.id == selectedEventID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Diagnostics")
                            .font(.title2)
                            .bold()

                        Text("Health, recovery, and privacy-safe local logs.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "waveform.path.ecg")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    DiagnosticsStatusBadge(title: "Privacy Safe", systemImage: "checkmark.shield", style: .green)
                    DiagnosticsStatusBadge(title: "Accessibility Aware", systemImage: "accessibility", style: .blue)
                }
            }

            toolbarControls
        }
        .padding(.horizontal, 32)
        .padding(.top, 18)
        .padding(.bottom, 12)
        .frame(maxWidth: ClearGlassSettingsPageStyle.tool.maxContentWidth, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var toolbarControls: some View {
        ViewThatFits(in: .horizontal) {
            wideToolbar
            wrappedToolbar
        }
    }

    private var wideToolbar: some View {
        HStack(spacing: 10) {
            eventCounter
            Spacer()
            severityPicker
            categoryPicker
            exportFormatPicker

            Button("Copy Selected", systemImage: "doc.on.doc", action: onCopySelected)
                .disabled(!canCopySelected)
                .help(canCopySelected ? "Copy selected diagnostic events." : "Select one or more events before copying.")

            Button("Export Filtered…", systemImage: "square.and.arrow.up", action: onExport)
                .disabled(filteredEventCount == 0)
                .help(filteredEventCount == 0 ? "No diagnostic events match the current filters." : "Export the currently filtered diagnostic events.")

            Button("Clear", systemImage: "trash", action: clear)
                .disabled(eventCount == 0)
                .help(eventCount == 0 ? "There are no diagnostic events to clear." : "Clear diagnostic events from the current log view.")
        }
        .controlSize(.small)
    }

    private var wrappedToolbar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                eventCounter
                Spacer()
            }

            HStack(spacing: 10) {
                severityPicker
                categoryPicker
                Spacer()
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    exportFormatPicker
                    Spacer()
                    ClearGlassAccessoryCluster {
                        actionButtons
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    exportFormatPicker
                    ClearGlassAccessoryCluster(alignment: .leading, width: .flexible) {
                        actionButtons
                    }
                }
            }
        }
        .controlSize(.small)
    }

    private var actionButtons: some View {
        Group {
            Button("Copy Selected", systemImage: "doc.on.doc", action: onCopySelected)
                .disabled(!canCopySelected)
                .help(canCopySelected ? "Copy selected diagnostic events." : "Select one or more events before copying.")
            Button("Export Filtered…", systemImage: "square.and.arrow.up", action: onExport)
                .disabled(filteredEventCount == 0)
                .help(filteredEventCount == 0 ? "No diagnostic events match the current filters." : "Export the currently filtered diagnostic events.")
            Button("Clear", systemImage: "trash", action: clear)
                .disabled(eventCount == 0)
                .help(eventCount == 0 ? "There are no diagnostic events to clear." : "Clear diagnostic events from the current log view.")
        }
    }

    private var eventCounter: some View {
        HStack(spacing: 8) {
            Text("Events")
                .font(.callout)
                .bold()

            Text("\(filteredEventCount) / \(eventCount)")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary, in: .capsule)
        }
    }

    private var severityPicker: some View {
        Picker("Severity", selection: $severityFilter) {
            ForEach(DiagnosticSeverityFilter.allCases) { filter in
                Text(filter.displayName)
                    .tag(filter)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .frame(minWidth: 120, idealWidth: 180, maxWidth: 200)
        .help("Filter diagnostic events by severity.")
    }

    private var categoryPicker: some View {
        Picker("Category", selection: $selectedCategory) {
            Text("All Categories")
                .tag(Optional<DiagnosticCategory>.none)
            ForEach(DiagnosticCategory.allCases) { category in
                Text(category.displayName)
                    .tag(Optional(category))
            }
        }
        .labelsHidden()
        .frame(minWidth: 120, idealWidth: 170, maxWidth: 220)
        .help("Filter diagnostic events by category.")
    }

    private var exportFormatPicker: some View {
        Picker("Export format", selection: $exportFormat) {
            ForEach(DiagnosticsExporter.Format.allCases) { format in
                Text(format.fileExtension.uppercased())
                    .tag(format)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .frame(minWidth: 70, idealWidth: 90, maxWidth: 100)
        .help("Choose the export format for diagnostic events.")
    }
}

private struct DiagnosticEventList: View {
    @Bindable var diagnosticsLogger: DiagnosticsLogger
    let severityFilter: DiagnosticSeverityFilter
    let selectedCategory: DiagnosticCategory?
    @Binding var selectedEventID: DiagnosticEvent.ID?

    private var filteredEvents: [DiagnosticEvent] {
        diagnosticsLogger.events.matching(
            severityFilter: severityFilter,
            selectedCategory: selectedCategory
        )
    }

    private var newestEventsFirst: [DiagnosticEvent] {
        Array(filteredEvents.reversed())
    }

    var body: some View {
        DiagnosticsPanel("Diagnostic Events", systemImage: "list.bullet.rectangle") {
            if diagnosticsLogger.events.isEmpty {
                SettingsUnavailableGate(
                    .emptyData,
                    title: "No Events",
                    message: "Diagnostics events will appear here as the app runs.",
                    systemImage: "list.bullet.rectangle",
                    minHeight: 160,
                    nextSteps: ["Use the app normally.", "Run Health to produce diagnostic context."]
                )
                .frame(maxWidth: .infinity, minHeight: 160)
            } else if filteredEvents.isEmpty {
                SettingsUnavailableGate(
                    .noMatches,
                    title: "No Matching Events",
                    message: "Adjust the severity or category filters to show more events.",
                    systemImage: "line.3.horizontal.decrease.circle",
                    minHeight: 160,
                    nextSteps: ["Choose All severities.", "Clear the category filter."]
                )
                .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                VStack(spacing: 0) {
                    DiagnosticEventTableHeader()
                        .accessibilityHidden(true)

                    LazyVStack(spacing: 0) {
                        ForEach(newestEventsFirst) { event in
                            Button {
                                selectedEventID = event.id
                            } label: {
                                DiagnosticEventRow(
                                    event: event,
                                    isSelected: selectedEventID == event.id
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(event.accessibilitySummary)
                            .accessibilityValue(selectedEventID == event.id ? "Selected" : "")
                            .accessibilityHint("Selects this diagnostics event.")
                        }
                    }
                }
                .clipShape(.rect(cornerRadius: 7))
                .overlay {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(Color(nsColor: .separatorColor).opacity(0.35))
                }
            }
        }
    }
}

private struct ExportErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.callout)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.red)
            .background(.red.opacity(0.08), in: .rect(cornerRadius: 8))
    }
}

private struct ExportSuccessBanner: View {
    let url: URL

    var body: some View {
        Label("Exported to \(url.lastPathComponent)", systemImage: "checkmark.circle")
            .font(.callout)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.green)
            .background(.green.opacity(0.08), in: .rect(cornerRadius: 8))
    }
}

private struct HealthStatusSection: View {
    @Bindable var liveStatus: LiveDiagnosticsStatus
    let onRefresh: (() -> Void)?
    let onFixAutomatically: (() -> Void)?
    let onResetBasicMode: (() -> Void)?
    let onDisableProMode: (() -> Void)?
    let onExportHealthReport: (() -> Void)?
    let onEnterSafeModeNextLaunch: (() -> Void)?

    var body: some View {
        DiagnosticsPanel("Health", systemImage: "stethoscope") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Label(statusTitle, systemImage: statusSymbol)
                        .font(.title3)
                        .bold()
                        .foregroundStyle(statusStyle)

                    if liveStatus.safeModeActive {
                        DiagnosticsStatusBadge(
                            title: liveStatus.safeModeReasonSummary,
                            systemImage: "lifepreserver",
                            style: .orange
                        )
                    }

                    Spacer()

                    Button("Refresh", systemImage: "arrow.clockwise") {
                        onRefresh?()
                    }
                }

                if let report = liveStatus.healthReport {
                    if report.sortedIssues.isEmpty {
                        Label("No health issues detected.", systemImage: "checkmark.circle")
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(report.sortedIssues) { issue in
                                HealthIssueRow(issue: issue)
                            }
                        }
                    }
                } else {
                    Label("Health has not run yet.", systemImage: "stethoscope")
                        .foregroundStyle(.secondary)
                }

                ClearGlassActionStrip(
                    "Health Recovery Actions",
                    subtitle: "Apply focused repairs first; keep mode changes, exports, and safe launch tools in More.",
                    systemImage: "wrench.and.screwdriver",
                    statusText: liveStatus.healthReport?.status.displayName ?? "Unknown",
                    statusStyle: liveStatus.healthReport == nil ? .secondary : (liveStatus.healthReport?.isHealthy == false ? .warning : .success)
                ) {
                    fixButton
                        .buttonStyle(.borderedProminent)

                    resetButton

                    Menu("More", systemImage: "ellipsis.circle") {
                        disableProButton

                        Divider()

                        exportButton
                        safeModeButton
                    }
                }
            }
        }
    }

    private var statusTitle: String {
        "Health: \(liveStatus.healthReport?.status.displayName ?? "Unknown")"
    }

    private var statusSymbol: String {
        switch liveStatus.healthReport?.status {
        case .ok:
            "checkmark.circle"
        case .warning:
            "exclamationmark.triangle"
        case .critical:
            "xmark.octagon"
        case nil:
            "stethoscope"
        }
    }

    private var statusStyle: Color {
        switch liveStatus.healthReport?.status {
        case .ok:
            .green
        case .warning:
            .orange
        case .critical:
            .red
        case nil:
            .secondary
        }
    }

    private var fixButton: some View {
        Button("Fix Automatically", systemImage: "wrench.and.screwdriver") {
            onFixAutomatically?()
        }
        .disabled(liveStatus.healthReport?.isHealthy != false)
    }

    private var resetButton: some View {
        Button("Reset Basic Mode", systemImage: "arrow.counterclockwise") {
            onResetBasicMode?()
        }
    }

    private var disableProButton: some View {
        Button("Disable Optional Pro", systemImage: "hand.raised.slash") {
            onDisableProMode?()
        }
    }

    private var exportButton: some View {
        Button("Export Health Report", systemImage: "square.and.arrow.up") {
            onExportHealthReport?()
        }
        .disabled(liveStatus.healthReport == nil)
    }

    private var safeModeButton: some View {
        Button("Safe Mode Next Launch", systemImage: "lifepreserver") {
            onEnterSafeModeNextLaunch?()
        }
    }
}

private struct HealthIssueRow: View {
    let issue: HealthIssue

    var body: some View {
        ClearGlassRowAnatomy(
            systemImage: issueIcon,
            iconTint: issueStyle.tint,
            iconStyle: .tile,
            title: issue.title,
            subtitle: issueDetailText,
            titleFont: .body.weight(.semibold),
            subtitleFont: .caption,
            subtitleLineLimit: 3,
            statusText: issue.severity.displayName,
            statusStyle: issueStyle
        )
        .padding(.vertical, 6)
        .clearGlassInteractionFeedback(.row, help: "\(issue.title). \(issueDetailText)")
    }

    private var issueStyle: ClearGlassStatusStyle {
        issue.severity == .critical ? .danger : .warning
    }

    private var issueIcon: String {
        issue.severity == .critical ? "xmark.octagon" : "exclamationmark.triangle"
    }

    private var issueDetailText: String {
        if let action = issue.recoveryAction {
            return "\(issue.detail) Recovery: \(action.displayName)."
        }

        return issue.detail
    }
}

private struct ScreenStatusSection: View {
    let screensProvider: () -> [DiagnosticsExporter.ScreenSnapshot]

    @State private var screens: [DiagnosticsExporter.ScreenSnapshot] = []

    var body: some View {
        DiagnosticsPanel(
            "Screens",
            systemImage: "display",
            accessory: {
                Button("Refresh", systemImage: "arrow.clockwise", action: refreshScreens)
            },
            content: {
                if screens.isEmpty {
                    SettingsUnavailableGate(
                        .emptyData,
                        title: "No Screens Reported",
                        message: "Display snapshots will appear after the screen list refreshes.",
                        systemImage: "display",
                        minHeight: 130,
                        nextSteps: ["Click Refresh above.", "Check the exported diagnostics if the list stays empty."]
                    )
                    .frame(maxWidth: .infinity, minHeight: 130)
                } else {
                    VStack(spacing: 0) {
                        ScreenTableHeader()

                        ForEach(screens, id: \.index) { screen in
                            HStack(spacing: 10) {
                                Text(screen.index, format: .number)
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28, alignment: .leading)

                                Text(screen.displayName)
                                    .lineLimit(1)
                                    .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)

                                Text(screen.frameSummary)
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)

                                DiagnosticsStatusBadge(
                                    title: screen.isMain ? "Main" : "Active",
                                    systemImage: screen.isMain ? "checkmark.circle" : "circle",
                                    style: screen.isMain ? .green : .secondary
                                )
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.28))
                            Divider()
                        }
                    }
                    .clipShape(.rect(cornerRadius: 7))
                    .overlay {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(Color(nsColor: .separatorColor).opacity(0.35))
                    }
                }
            }
        )
        .onAppear(perform: refreshScreens)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            refreshScreens()
        }
    }

    private func refreshScreens() {
        let next = screensProvider()
        if next != screens {
            screens = next
        }
    }
}

private struct LiveStatusSection: View {
    let liveStatus: LiveDiagnosticsStatus
    let settingsStore: SettingsStore
    var launchAtLoginService: LaunchAtLoginService?
    var scanCoordinator: MenuBarScanCoordinator?

    var body: some View {
        DiagnosticsPanel(
            "Live Status",
            systemImage: "waveform.path.ecg",
            accessory: {
                Button("Refresh AX Scan", systemImage: "arrow.clockwise") {
                    scanCoordinator?.requestManualRefresh()
                }
                .disabled(scanCoordinator?.isManualRefreshAvailable != true)
            },
            content: {
                VStack(alignment: .leading, spacing: 8) {
                    LiveStatusCoreGrid(liveStatus: liveStatus)
                    LiveStatusAccessibilityGrid(liveStatus: liveStatus)
                    LiveStatusSearchGrid(liveStatus: liveStatus)
                    LiveStatusSecondBarGrid(liveStatus: liveStatus)
                    LiveStatusIconMoveGrid(liveStatus: liveStatus, settingsStore: settingsStore)
                    LiveStatusAutomationGrid(
                        liveStatus: liveStatus,
                        settingsStore: settingsStore,
                        launchAtLoginService: launchAtLoginService
                    )
                }

                LiveMenuBarSnapshotSection(liveStatus: liveStatus)
                    .id("Scanned Items")
            }
        )
    }
}

private enum LiveStatusValueStyle {
    case secondary
    case warning
}

private struct LiveStatusRowData: Identifiable {
    let label: String
    let value: String
    var valueStyle: LiveStatusValueStyle = .secondary

    var id: String {
        label
    }
}

private struct LiveStatusGrid: View {
    let rows: [LiveStatusRowData]

    private let columns = [
        GridItem(.adaptive(minimum: 260), spacing: 8, alignment: .top)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(rows) { row in
                LiveStatusRow(row: row)
            }
        }
    }
}

private struct LiveStatusRow: View {
    let row: LiveStatusRowData

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(row.label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            valueText
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.45), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.25))
        }
    }

    @ViewBuilder
    private var valueText: some View {
        switch row.valueStyle {
        case .secondary:
            Text(row.value)
                .foregroundStyle(.secondary)
        case .warning:
            Text(row.value)
                .foregroundStyle(.orange)
        }
    }
}

private extension Bool {
    var yesNoText: String {
        self ? "Yes" : "No"
    }
}

private extension String {
    var emptyPlaceholder: String {
        isEmpty ? "—" : self
    }
}

private struct LiveStatusCoreGrid: View {
    let liveStatus: LiveDiagnosticsStatus

    private var rows: [LiveStatusRowData] {
        [
            LiveStatusRowData(label: "Visibility State", value: liveStatus.visibilityState.rawValue),
            LiveStatusRowData(
                label: "Primary Separator Length",
                value: liveStatus.primarySeparatorLength.formatted(.number.precision(.fractionLength(0)))
            ),
            LiveStatusRowData(
                label: "Always-Hidden Separator Length",
                value: liveStatus.alwaysHiddenSeparatorLength.formatted(.number.precision(.fractionLength(0)))
            ),
            LiveStatusRowData(label: "Always-Hidden Installed", value: liveStatus.alwaysHiddenSeparatorInstalled.yesNoText),
            LiveStatusRowData(label: "Hotkey Registered", value: liveStatus.hotkeyRegistered.yesNoText),
            LiveStatusRowData(
                label: "Find Icon Hotkey",
                value: liveStatus.searchHotkeyRegistered ? "Registered" : "Not Registered"
            ),
            LiveStatusRowData(label: "Hover Polling", value: liveStatus.hoverPollingActive ? "Active" : "Inactive"),
            LiveStatusRowData(label: "Auto-Rehide", value: liveStatus.autoRehideScheduled ? "Scheduled" : "Idle"),
            LiveStatusRowData(label: "Last Rehide Reason", value: liveStatus.lastRehideReason ?? "—")
        ]
    }

    var body: some View {
        LiveStatusGrid(rows: rows)
    }
}

private struct LiveStatusAccessibilityGrid: View {
    let liveStatus: LiveDiagnosticsStatus

    private var rows: [LiveStatusRowData] {
        [
            LiveStatusRowData(
                label: "Accessibility Permission",
                value: liveStatus.accessibilityPermissionStatus.displayName
            ),
            LiveStatusRowData(label: "AX Scan State", value: liveStatus.menuBarScanLifecycleState.rawValue),
            LiveStatusRowData(label: "AX Scan Reason", value: liveStatus.menuBarScanLastReason ?? "—"),
            LiveStatusRowData(label: "AX Skip Reason", value: liveStatus.menuBarScanLastSkipReason ?? "—"),
            LiveStatusRowData(label: "Scanned Items", value: liveStatus.scannedMenuBarItems.count.formatted(.number)),
            LiveStatusRowData(
                label: "Visible / Hidden / Always Hidden / Unknown",
                value: scanCountSummary
            ),
            LiveStatusRowData(label: "Last AX Scan", value: lastScanText),
            LiveStatusRowData(label: "AX Failures", value: liveStatus.menuBarScanFailuresCount.formatted(.number)),
            LiveStatusRowData(label: "AX Failure Summary", value: liveStatus.menuBarScanFailureSummary ?? "—")
        ]
    }

    private var scanCountSummary: String {
        [
            liveStatus.menuBarScanVisibleCount,
            liveStatus.menuBarScanHiddenCount,
            liveStatus.menuBarScanAlwaysHiddenCount,
            liveStatus.menuBarScanUnknownCount
        ]
            .map { String($0) }
            .joined(separator: " / ")
    }

    private var lastScanText: String {
        guard let lastMenuBarScanTime = liveStatus.lastMenuBarScanTime else {
            return "—"
        }
        return lastMenuBarScanTime.formatted(Date.FormatStyle(date: .omitted, time: .standard))
    }

    var body: some View {
        LiveStatusGrid(rows: rows)
    }
}

private struct LiveStatusSearchGrid: View {
    let liveStatus: LiveDiagnosticsStatus

    private var rows: [LiveStatusRowData] {
        [
            LiveStatusRowData(label: "Search Index Items", value: liveStatus.searchIndexItemCount.formatted(.number)),
            LiveStatusRowData(label: "Last Result Count", value: liveStatus.searchLastResultCount.formatted(.number)),
            LiveStatusRowData(label: "Index Rebuild", value: millisecondsText(liveStatus.searchIndexRebuildDurationMilliseconds)),
            LiveStatusRowData(label: "Ranking Time", value: millisecondsText(liveStatus.searchRankingDurationMilliseconds)),
            LiveStatusRowData(label: "Panel Open", value: millisecondsText(liveStatus.searchPanelOpenDurationMilliseconds)),
            LiveStatusRowData(label: "Latest Scan Age", value: secondsText(liveStatus.searchLatestScanAgeSeconds)),
            LiveStatusRowData(label: "Last Search Activation", value: liveStatus.lastSearchActivationOutcome ?? "—")
        ]
    }

    private func millisecondsText(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(value.formatted(.number.precision(.fractionLength(2)))) ms"
    }

    private func secondsText(_ value: Double?) -> String {
        guard let value else { return "No scan" }
        return "\(value.formatted(.number.precision(.fractionLength(0)))) s"
    }

    var body: some View {
        LiveStatusGrid(rows: rows)
    }
}

private struct LiveStatusSecondBarGrid: View {
    let liveStatus: LiveDiagnosticsStatus

    private var rows: [LiveStatusRowData] {
        [
            LiveStatusRowData(label: "Second Bar Visible", value: liveStatus.secondBarVisible.yesNoText),
            LiveStatusRowData(label: "Second Bar Items", value: liveStatus.secondBarItemCount.formatted(.number)),
            LiveStatusRowData(label: "Second Bar Screen", value: liveStatus.secondBarCurrentScreen ?? "—"),
            LiveStatusRowData(label: "Second Bar Position", value: liveStatus.secondBarLastPosition ?? "—"),
            LiveStatusRowData(label: "Last Compact Visible", value: liveStatus.secondBarLastCompactVisibleItemCount.formatted(.number)),
            LiveStatusRowData(label: "Last Compact Overflow", value: liveStatus.secondBarLastCompactOverflowItemCount.formatted(.number)),
            LiveStatusRowData(label: "Last Compact Fallback Icons", value: liveStatus.secondBarLastCompactFallbackIconCount.formatted(.number)),
            LiveStatusRowData(label: "Last Compact Scan", value: liveStatus.secondBarLastCompactScanState ?? "—"),
            LiveStatusRowData(label: "Icon Warm-up Running", value: liveStatus.secondBarIconWarmUpInProgress.yesNoText),
            LiveStatusRowData(label: "Last Icon Warm-up", value: liveStatus.secondBarLastIconWarmUpResult ?? "—")
        ]
    }

    var body: some View {
        LiveStatusGrid(rows: rows)
    }
}

private struct LiveStatusIconMoveGrid: View {
    let liveStatus: LiveDiagnosticsStatus
    let settingsStore: SettingsStore

    private var rows: [LiveStatusRowData] {
        [
            LiveStatusRowData(label: "Icon Move In Progress", value: liveStatus.iconMoveInProgress.yesNoText),
            LiveStatusRowData(label: "Last Icon Move Result", value: liveStatus.lastIconMoveResult ?? "—"),
            LiveStatusRowData(label: "Last Icon Move Error", value: liveStatus.lastIconMoveError ?? "—"),
            LiveStatusRowData(label: "Last Drag Plan", value: liveStatus.lastIconMoveDragPlanSummary ?? "—"),
            LiveStatusRowData(
                label: "Last Move Verification",
                value: liveStatus.lastIconMoveVerificationSummary ?? "—"
            ),
            LiveStatusRowData(label: "Move Retries", value: liveStatus.lastIconMoveRetriesCount.formatted(.number)),
            LiveStatusRowData(
                label: "Labs Icon Moving",
                value: settingsStore.iconMovingEnabled ? "Enabled" : "Disabled",
                valueStyle: settingsStore.iconMovingEnabled ? .warning : .secondary
            )
        ]
    }

    var body: some View {
        LiveStatusGrid(rows: rows)
    }
}

private struct LiveStatusAutomationGrid: View {
    let liveStatus: LiveDiagnosticsStatus
    let settingsStore: SettingsStore
    var launchAtLoginService: LaunchAtLoginService?

    private var isAutomationPaused: Bool {
        settingsStore.automationPaused || liveStatus.automationPaused
    }

    private var rows: [LiveStatusRowData] {
        [
            LiveStatusRowData(label: "Bundle Path", value: Bundle.main.bundleURL.path),
            LiveStatusRowData(label: "Running From /Applications", value: Bundle.main.bundleURL.path.hasPrefix("/Applications/").yesNoText),
            LiveStatusRowData(
                label: "Smart Triggers",
                value: settingsStore.smartTriggersEnabled ? "Enabled" : "Disabled"
            ),
            LiveStatusRowData(
                label: "Automation Paused",
                value: isAutomationPaused.yesNoText,
                valueStyle: isAutomationPaused ? .warning : .secondary
            ),
            LiveStatusRowData(
                label: "Launch at Login Status",
                value: launchAtLoginService?.statusDisplayName ?? "Unavailable"
            ),
            LiveStatusRowData(
                label: "Last Login Item Action",
                value: launchAtLoginService?.lastRegistrationResult?.displayName ?? "—"
            ),
            LiveStatusRowData(label: "Active Profile", value: liveStatus.activeProfileName ?? "—"),
            LiveStatusRowData(label: "Last Trigger Fired", value: liveStatus.lastTriggerFired ?? "—"),
            LiveStatusRowData(label: "Profile Apply Log", value: liveStatus.lastProfileApplyLog.emptyPlaceholder),
            LiveStatusRowData(label: "Trigger Evaluation", value: liveStatus.triggerEvaluationLog.emptyPlaceholder)
        ]
    }

    var body: some View {
        LiveStatusGrid(rows: rows)
    }
}

private struct LiveMenuBarSnapshotSection: View {
    let liveStatus: LiveDiagnosticsStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Scanned Items")
                    .font(.subheadline)
                    .bold()

                Text(liveStatus.scannedMenuBarItems.count, format: .number)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Spacer()
            }

            if liveStatus.scannedMenuBarItems.isEmpty {
                SettingsUnavailableGate(
                    .emptyData,
                    title: "No Accessibility Snapshots",
                    message: "Menu bar item snapshots appear after an Optional Pro Accessibility scan.",
                    systemImage: "menubar.rectangle",
                    minHeight: 130,
                    nextSteps: ["Enable Optional Pro Discovery.", "Refresh Menu Bar Items after permission is granted."]
                )
                .frame(maxWidth: .infinity, minHeight: 130)
            } else {
                MenuBarSnapshotTable(snapshots: liveStatus.scannedMenuBarItems)
                    .frame(minHeight: 180, maxHeight: 240)
            }
        }
        .padding(.top, 8)
    }
}

private struct MenuBarSnapshotTable: View {
    let snapshots: [MenuBarItemSnapshot]

    var body: some View {
        Table(snapshots) {
            TableColumn("Title") { snapshot in
                Text(snapshot.title ?? "—")
            }
            TableColumn("App") { snapshot in
                Text(snapshot.owningApplicationName ?? "—")
            }
            TableColumn("Bundle") { snapshot in
                Text(snapshot.bundleIdentifier ?? "—")
            }
            TableColumn("Role") { snapshot in
                Text(snapshot.role ?? "—")
            }
            TableColumn("Zone") { snapshot in
                Text(snapshot.zone.displayName)
            }
            TableColumn("Frame") { snapshot in
                Text(frameText(snapshot.frame))
                    .font(.system(.caption, design: .monospaced))
            }
            TableColumn("System") { snapshot in
                Text(snapshot.isLikelySystemItem ? "Yes" : "No")
            }
        }
    }

    private func frameText(_ frame: CGRect?) -> String {
        guard let frame else { return "—" }
        return "\(Int(frame.origin.x)),\(Int(frame.origin.y)) \(Int(frame.width))x\(Int(frame.height))"
    }
}

private extension DiagnosticsExporter.ScreenSnapshot {
    var displayName: String {
        isMain ? "Screen \(index) (main)" : "Screen \(index)"
    }

    var frameSummary: String {
        "x \(Int(x)), y \(Int(y)), \(Int(width)) x \(Int(height))"
    }
}

private struct ScreenTableHeader: View {
    var body: some View {
        HStack(spacing: 10) {
            Text("#")
                .frame(width: 28, alignment: .leading)
            Text("Display")
                .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)
            Text("Frame")
                .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)
            Text("Active")
                .frame(width: 80, alignment: .leading)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.quaternary)
    }
}

private struct DiagnosticEventTableHeader: View {
    var body: some View {
        HStack(spacing: 10) {
            Text("Time")
                .frame(width: 96, alignment: .leading)
            Text("Level")
                .frame(width: 82, alignment: .leading)
            Text("Category")
                .frame(width: 110, alignment: .leading)
            Text("Message")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.quaternary)
    }
}

private struct DiagnosticEventRow: View {
    let event: DiagnosticEvent
    var isSelected = false

    var body: some View {
        VStack(spacing: 0) {
            rowContent
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(rowBackground)

            Divider()
        }
    }

    private var rowContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(event.timestamp, format: Date.FormatStyle(date: .omitted, time: .standard))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 96, alignment: .leading)

                Text(event.level.rawValue.uppercased())
                    .font(.caption)
                    .bold()
                    .foregroundStyle(levelStyle)
                    .frame(width: 82, alignment: .leading)

                Text(event.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 110, alignment: .leading)

                Text(event.message)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !event.metadata.isEmpty {
                HStack(spacing: 10) {
                    Color.clear
                        .frame(width: 96)
                    Color.clear
                        .frame(width: 82)
                    Color.clear
                        .frame(width: 110)
                    Text(event.metadata.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var rowBackground: Color {
        if isSelected {
            Color.accentColor.opacity(0.14)
        } else {
            Color(nsColor: .controlBackgroundColor).opacity(0.22)
        }
    }

    private var levelStyle: Color {
        switch event.level {
        case .debug:
            .secondary
        case .info:
            .blue
        case .warning:
            .orange
        case .error:
            .red
        }
    }
}

#Preview {
    DiagnosticsSettingsPreviewFactory.make()
}

private enum DiagnosticsSettingsPreviewFactory {
    @MainActor
    static func make() -> DiagnosticsSettingsView {
    let logger = DiagnosticsLogger()
    logger.log("Preview event created.", level: .info)
    let live = LiveDiagnosticsStatus()
    live.visibilityState = .revealAll
    live.primarySeparatorLength = 20
    live.alwaysHiddenSeparatorLength = 5120
    live.lastRehideReason = "timerExpired"
    return DiagnosticsSettingsView(
        diagnosticsLogger: logger,
        liveStatus: live,
        appSupportPaths: AppSupportPaths(),
        exporter: DiagnosticsExporter(),
        dogfoodStore: DogfoodStore(appSupportPaths: AppSupportPaths()),
        settingsStore: SettingsStore(),
        scanCoordinator: nil
    )
    }
}
