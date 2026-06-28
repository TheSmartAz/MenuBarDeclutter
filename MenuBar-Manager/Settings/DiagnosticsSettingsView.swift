import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DiagnosticsSettingsView: View {
    @Bindable var diagnosticsLogger: DiagnosticsLogger
    var liveStatus: LiveDiagnosticsStatus?
    let appSupportPaths: AppSupportPaths
    let exporter: DiagnosticsExporter
    @Bindable var settingsStore: SettingsStore
    var launchAtLoginService: LaunchAtLoginService? = nil
    var scanCoordinator: MenuBarScanCoordinator?
    var onRunHealthCheck: (() -> Void)?
    var onFixHealthIssues: (() -> Void)?
    var onResetBasicMode: (() -> Void)?
    var onDisableProMode: (() -> Void)?
    var onEnterSafeModeNextLaunch: (() -> Void)?

    @State private var exportFormat: DiagnosticsExporter.Format = .txt
    @State private var exportError: String?
    @State private var lastExportedURL: URL?
    @State private var severityFilter: DiagnosticSeverityFilter = .all
    @State private var selectedCategory: DiagnosticCategory?
    @State private var selectedEventID: DiagnosticEvent.ID?

    private var filteredEvents: [DiagnosticEvent] {
        diagnosticsLogger.events.matching(
            severityFilter: severityFilter,
            selectedCategory: selectedCategory
        )
    }

    private var selectedEvent: DiagnosticEvent? {
        diagnosticsLogger.events.first { $0.id == selectedEventID }
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

            if let exportError {
                ExportErrorBanner(message: exportError)
                Divider()
            }

            if let lastExportedURL {
                ExportSuccessBanner(url: lastExportedURL)
                Divider()
            }

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
                Divider()
            }

            ScreenStatusSection(screensProvider: exporter.screensProvider)
            Divider()

            if let liveStatus {
                LiveStatusSection(
                    liveStatus: liveStatus,
                    settingsStore: settingsStore,
                    launchAtLoginService: launchAtLoginService,
                    scanCoordinator: scanCoordinator
                )
                Divider()
            }

            DiagnosticEventList(
                diagnosticsLogger: diagnosticsLogger,
                severityFilter: severityFilter,
                selectedCategory: selectedCategory,
                selectedEventID: $selectedEventID
            )
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

        let timestamp = Self.filenameTimestamp(exporter: exporter)
        let suggestedName = "MenuBarDeclutter-diagnostics-\(timestamp).\(exportFormat.fileExtension)"

        let panel = NSSavePanel()
        panel.title = "Export Diagnostics"
        panel.allowedContentTypes = [Self.utType(for: exportFormat)]
        panel.nameFieldStringValue = suggestedName
        panel.directoryURL = directory

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }

        let snapshot = exporter.makeSnapshot(
            settingsStore: settingsStore,
            logger: diagnosticsLogger,
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

        let timestamp = Self.filenameTimestamp(exporter: exporter)
        let suggestedName = "MenuBarDeclutter-health-\(timestamp).txt"

        let panel = NSSavePanel()
        panel.title = "Export Health Report"
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = suggestedName
        panel.directoryURL = directory

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }

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

    private static func filenameTimestamp(exporter: DiagnosticsExporter) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: Date())
    }

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
        return diagnosticsLogger.events.contains { $0.id == selectedEventID }
    }

    var body: some View {
        HStack {
            Text("Events")
                .font(.title3)
                .bold()

            Text("\(filteredEventCount) / \(eventCount)")
                .foregroundStyle(.secondary)

            Spacer()

            Picker("Severity", selection: $severityFilter) {
                ForEach(DiagnosticSeverityFilter.allCases) { filter in
                    Text(filter.displayName)
                        .tag(filter)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 180)

            Picker("Category", selection: $selectedCategory) {
                Text("All Categories")
                    .tag(Optional<DiagnosticCategory>.none)
                ForEach(DiagnosticCategory.allCases) { category in
                    Text(category.displayName)
                        .tag(Optional(category))
                }
            }
            .labelsHidden()
            .frame(width: 170)

            Picker("Export format", selection: $exportFormat) {
                ForEach(DiagnosticsExporter.Format.allCases) { format in
                    Text(format.fileExtension.uppercased())
                        .tag(format)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 90)

            Button("Copy Selected", systemImage: "doc.on.doc", action: onCopySelected)
                .disabled(!canCopySelected)

            Button("Export Filtered…", systemImage: "square.and.arrow.up", action: onExport)
                .disabled(filteredEventCount == 0)

            Button("Clear", systemImage: "trash", action: clear)
                .disabled(eventCount == 0)
        }
        .padding()
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

    var body: some View {
        if diagnosticsLogger.events.isEmpty {
            ContentUnavailableView("No Events", systemImage: "list.bullet.rectangle")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if filteredEvents.isEmpty {
            ContentUnavailableView("No Matching Events", systemImage: "line.3.horizontal.decrease.circle")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(selection: $selectedEventID) {
                ForEach(filteredEvents.reversed()) { event in
                    DiagnosticEventRow(event: event)
                        .tag(event.id)
                }
            }
        }
    }
}

private struct ExportErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .padding(.horizontal)
            .padding(.vertical, 8)
            .foregroundStyle(.red)
    }
}

private struct ExportSuccessBanner: View {
    let url: URL

    var body: some View {
        Label("Exported to \(url.lastPathComponent)", systemImage: "checkmark.circle")
            .padding(.horizontal)
            .padding(.vertical, 8)
            .foregroundStyle(.green)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label(statusTitle, systemImage: statusSymbol)
                    .font(.headline)
                    .foregroundStyle(statusStyle)

                if liveStatus.safeModeActive {
                    Label(liveStatus.safeModeReasonSummary, systemImage: "lifepreserver")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Spacer()

                Button("Refresh", systemImage: "arrow.clockwise") {
                    onRefresh?()
                }
                .buttonStyle(.borderless)
            }
            .padding(.top, 4)

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

            ViewThatFits(in: .horizontal) {
                HStack {
                    healthButtons
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        fixButton
                        resetButton
                        disableProButton
                    }
                    HStack {
                        exportButton
                        safeModeButton
                    }
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
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

    @ViewBuilder
    private var healthButtons: some View {
        fixButton
        resetButton
        disableProButton
        exportButton
        safeModeButton
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
        Button("Disable Pro Mode", systemImage: "hand.raised.slash") {
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
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(issue.severity.displayName.uppercased())
                    .font(.caption)
                    .bold()
                    .foregroundStyle(issue.severity == .critical ? .red : .orange)

                Text(issue.title)
                    .bold()

                Spacer()
            }

            Text(issue.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            if let action = issue.recoveryAction {
                Text(action.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct ScreenStatusSection: View {
    let screensProvider: () -> [DiagnosticsExporter.ScreenSnapshot]

    @State private var screens: [DiagnosticsExporter.ScreenSnapshot] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Screens")
                    .font(.headline)

                Text(screens.count, format: .number)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Refresh", systemImage: "arrow.clockwise", action: refreshScreens)
                    .buttonStyle(.borderless)
            }
            .padding(.top, 4)

            if screens.isEmpty {
                Text("No screens reported.")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                    ForEach(screens, id: \.index) { screen in
                        GridRow {
                            Text(screen.displayName)
                            Text(screen.frameSummary)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .padding(.horizontal)
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
        VStack(alignment: .leading, spacing: 6) {
            LiveStatusHeader(scanCoordinator: scanCoordinator)

            VStack(alignment: .leading, spacing: 4) {
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
        }
    }
}

private struct LiveStatusHeader: View {
    var scanCoordinator: MenuBarScanCoordinator?

    var body: some View {
        HStack {
            Text("Live Status")
                .font(.headline)

            Spacer()

            Button("Refresh AX Scan", systemImage: "arrow.clockwise") {
                scanCoordinator?.requestManualRefresh()
            }
            .disabled(scanCoordinator?.isManualRefreshAvailable != true)
        }
        .padding(.top, 4)
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

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
            ForEach(rows) { row in
                LiveStatusRow(row: row)
            }
        }
        .padding(.horizontal)
    }
}

private struct LiveStatusRow: View {
    let row: LiveStatusRowData

    var body: some View {
        GridRow {
            Text(row.label)
            valueText
            Spacer()
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
            LiveStatusRowData(label: "Scanned Items", value: liveStatus.scannedMenuBarItems.count.formatted(.number)),
            LiveStatusRowData(
                label: "Visible / Hidden / Always Hidden / Unknown",
                value: scanCountSummary
            ),
            LiveStatusRowData(label: "Last AX Scan", value: lastScanText),
            LiveStatusRowData(label: "AX Failures", value: liveStatus.menuBarScanFailuresCount.formatted(.number))
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
            LiveStatusRowData(label: "Last Search Query", value: liveStatus.lastSearchQuery.emptyPlaceholder),
            LiveStatusRowData(label: "Last Search Selection", value: liveStatus.lastSearchSelectedItem ?? "—"),
            LiveStatusRowData(label: "Last Search Activation", value: liveStatus.lastSearchActivationOutcome ?? "—")
        ]
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
            LiveStatusRowData(label: "Last Second Bar Selection", value: liveStatus.lastSecondBarSelectedItem ?? "—")
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
                label: "Experimental Icon Moving",
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
        Group {
            if liveStatus.scannedMenuBarItems.isEmpty {
                Text("No Accessibility snapshots yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                MenuBarSnapshotTable(snapshots: liveStatus.scannedMenuBarItems)
                    .frame(minHeight: 180, maxHeight: 240)
                    .padding(.horizontal)
            }
        }
        .padding(.bottom, 8)
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

private struct DiagnosticEventRow: View {
    let event: DiagnosticEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(event.level.rawValue.uppercased())
                    .font(.caption)
                    .bold()
                    .foregroundStyle(levelStyle)

                Text(event.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(event.timestamp, format: Date.FormatStyle(date: .omitted, time: .standard))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(event.message)
                .textSelection(.enabled)

            if !event.metadata.isEmpty {
                Text(event.metadata.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 4)
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
        settingsStore: SettingsStore(),
        scanCoordinator: nil
    )
}
