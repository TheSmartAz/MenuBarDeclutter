import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DiagnosticsSettingsView: View {
    @Bindable var diagnosticsLogger: DiagnosticsLogger
    var liveStatus: LiveDiagnosticsStatus?
    let appSupportPaths: AppSupportPaths
    let exporter: DiagnosticsExporter
    @Bindable var settingsStore: SettingsStore
    var scanCoordinator: MenuBarScanCoordinator?
    var onRunHealthCheck: (() -> Void)?
    var onFixHealthIssues: (() -> Void)?
    var onResetBasicMode: (() -> Void)?
    var onDisableProMode: (() -> Void)?
    var onEnterSafeModeNextLaunch: (() -> Void)?

    @State private var exportFormat: DiagnosticsExporter.Format = .txt
    @State private var exportError: String?
    @State private var lastExportedURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            DiagnosticsToolbar(
                eventCount: diagnosticsLogger.events.count,
                clear: diagnosticsLogger.removeAll,
                exportFormat: $exportFormat,
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
                    scanCoordinator: scanCoordinator
                )
                Divider()
            }

            if diagnosticsLogger.events.isEmpty {
                ContentUnavailableView("No Events", systemImage: "list.bullet.rectangle")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(diagnosticsLogger.events.reversed()) { event in
                    DiagnosticEventRow(event: event)
                }
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

        let timestamp = Self.filenameTimestamp(exporter: exporter)
        let suggestedName = "MenuBarDeclutter-diagnostics-\(timestamp).\(exportFormat.fileExtension)"

        let panel = NSSavePanel()
        panel.title = "Export Diagnostics"
        panel.allowedContentTypes = [Self.utType(for: exportFormat)]
        panel.nameFieldStringValue = suggestedName
        panel.directoryURL = directory

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }

        let snapshot = exporter.makeSnapshot(settingsStore: settingsStore, logger: diagnosticsLogger)
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

private struct DiagnosticsToolbar: View {
    let eventCount: Int
    let clear: () -> Void
    @Binding var exportFormat: DiagnosticsExporter.Format
    let onExport: () -> Void

    var body: some View {
        HStack {
            Text("Events")
                .font(.title3)
                .bold()

            Text(eventCount, format: .number)
                .foregroundStyle(.secondary)

            Spacer()

            Picker("Export format", selection: $exportFormat) {
                ForEach(DiagnosticsExporter.Format.allCases) { format in
                    Text(format.fileExtension.uppercased())
                        .tag(format)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 90)

            Button("Export…", systemImage: "square.and.arrow.up", action: onExport)

            Button("Clear", systemImage: "trash", action: clear)
                .disabled(eventCount == 0)
        }
        .padding()
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
    @Bindable var liveStatus: LiveDiagnosticsStatus
    var scanCoordinator: MenuBarScanCoordinator?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                GridRow {
                    Text("Visibility State")
                    Text(liveStatus.visibilityState.rawValue)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Primary Separator Length")
                    Text(liveStatus.primarySeparatorLength, format: .number.precision(.fractionLength(0)))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Always-Hidden Separator Length")
                    Text(liveStatus.alwaysHiddenSeparatorLength, format: .number.precision(.fractionLength(0)))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Always-Hidden Installed")
                    Text(liveStatus.alwaysHiddenSeparatorInstalled ? "Yes" : "No")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Hotkey Registered")
                    Text(liveStatus.hotkeyRegistered ? "Yes" : "No")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Find Icon Hotkey")
                    Text(liveStatus.searchHotkeyRegistered ? "Registered" : "Not Registered")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Hover Polling")
                    Text(liveStatus.hoverPollingActive ? "Active" : "Inactive")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Auto-Rehide")
                    Text(liveStatus.autoRehideScheduled ? "Scheduled" : "Idle")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Last Rehide Reason")
                    Text(liveStatus.lastRehideReason ?? "—")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Accessibility Permission")
                    Text(liveStatus.accessibilityPermissionStatus.displayName)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Scanned Items")
                    Text(liveStatus.scannedMenuBarItems.count, format: .number)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Visible / Hidden / Always Hidden / Unknown")
                    Text("\(liveStatus.menuBarScanVisibleCount) / \(liveStatus.menuBarScanHiddenCount) / \(liveStatus.menuBarScanAlwaysHiddenCount) / \(liveStatus.menuBarScanUnknownCount)")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Last AX Scan")
                    if let lastMenuBarScanTime = liveStatus.lastMenuBarScanTime {
                        Text(lastMenuBarScanTime, format: Date.FormatStyle(date: .omitted, time: .standard))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("—")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                GridRow {
                    Text("AX Failures")
                    Text(liveStatus.menuBarScanFailuresCount, format: .number)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Search Index Items")
                    Text(liveStatus.searchIndexItemCount, format: .number)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Last Search Query")
                    Text(liveStatus.lastSearchQuery.isEmpty ? "—" : liveStatus.lastSearchQuery)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Last Search Selection")
                    Text(liveStatus.lastSearchSelectedItem ?? "—")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Last Search Activation")
                    Text(liveStatus.lastSearchActivationOutcome ?? "—")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Second Bar Visible")
                    Text(liveStatus.secondBarVisible ? "Yes" : "No")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Second Bar Items")
                    Text(liveStatus.secondBarItemCount, format: .number)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Second Bar Screen")
                    Text(liveStatus.secondBarCurrentScreen ?? "—")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Second Bar Position")
                    Text(liveStatus.secondBarLastPosition ?? "—")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Last Second Bar Selection")
                    Text(liveStatus.lastSecondBarSelectedItem ?? "—")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Icon Move In Progress")
                    Text(liveStatus.iconMoveInProgress ? "Yes" : "No")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Last Icon Move Result")
                    Text(liveStatus.lastIconMoveResult ?? "—")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Last Icon Move Error")
                    Text(liveStatus.lastIconMoveError ?? "—")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Last Drag Plan")
                    Text(liveStatus.lastIconMoveDragPlanSummary ?? "—")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Last Move Verification")
                    Text(liveStatus.lastIconMoveVerificationSummary ?? "—")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Move Retries")
                    Text(liveStatus.lastIconMoveRetriesCount, format: .number)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Active Profile")
                    Text(liveStatus.activeProfileName ?? "—")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Last Trigger Fired")
                    Text(liveStatus.lastTriggerFired ?? "—")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Profile Apply Log")
                    Text(liveStatus.lastProfileApplyLog.isEmpty ? "—" : liveStatus.lastProfileApplyLog)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                GridRow {
                    Text("Trigger Evaluation")
                    Text(liveStatus.triggerEvaluationLog.isEmpty ? "—" : liveStatus.triggerEvaluationLog)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .padding(.horizontal)

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

                Spacer()

                Text(event.timestamp, format: Date.FormatStyle(date: .omitted, time: .standard))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(event.message)
                .textSelection(.enabled)
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
