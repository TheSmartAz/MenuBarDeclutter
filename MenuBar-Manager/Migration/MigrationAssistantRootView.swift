import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct MigrationAssistantRootView: View {
    @Bindable var settingsStore: SettingsStore
    let appSupportPaths: AppSupportPaths
    let diagnosticsLogger: DiagnosticsLogger
    let profileStore: ProfileStore?
    let groupStore: IconGroupStore?
    let hotkeyBindingStore: HotkeyBindingStore?
    let spacerItemStore: SpacerItemStore?
    let workspaceSwitchingService: WorkspaceSwitchingService?
    var onImportApplied: (() -> Void)?

    @State private var selectedWorkflow: MigrationWorkflow = .importReview
    @State private var statusMessage: String?
    @State private var dryRun: SettingsImportDryRun?
    @State private var pendingPackage: SettingsExportPackage?
    @State private var lastApplyResult: SettingsImportApplyResult?
    @State private var backupCount = 0

    private var exportService: SettingsExportService {
        SettingsExportService(settingsStore: settingsStore, diagnosticsLogger: diagnosticsLogger)
    }

    private var importService: SettingsImportService {
        SettingsImportService(diagnosticsLogger: diagnosticsLogger)
    }

    private var backupService: ImportBackupService {
        ImportBackupService(backupsDirectory: appSupportPaths.backupsDirectory, diagnosticsLogger: diagnosticsLogger)
    }

    private var exportCounts: MigrationPackageCounts {
        MigrationPackageCounts(
            profiles: profileStore?.profiles.count ?? 0,
            groups: groupStore?.groups.count ?? 0,
            hotkeys: hotkeyBindingStore?.bindings.count ?? 0,
            spacers: spacerItemStore?.items.count ?? 0,
            workspaces: workspaceSwitchingService?.currentSnapshot().workspaces.count ?? 0
        )
    }

    private var pageSectionAnchors: [ClearGlassPageAnchor] {
        var anchors = [
            ClearGlassPageAnchor("Transfer Assistant", systemImage: "arrow.left.arrow.right")
        ]

        if statusMessage != nil {
            anchors.append(ClearGlassPageAnchor("Status", systemImage: "info.circle"))
        }

        return anchors
    }

    var body: some View {
        ClearGlassSettingsPage(
            "Import / Export",
            subtitle: "Move local MenuBarDeclutter configuration explicitly and safely.",
            badges: [.preview, .privacySafe],
            style: .tool,
            sectionAnchors: pageSectionAnchors
        ) {
            MigrationOverviewStrip(
                hasPendingImport: pendingPackage != nil,
                backupCount: backupCount,
                lastApplyResult: lastApplyResult
            )

            ClearGlassSection("Transfer Assistant", subtitle: "Export, review, apply, and restore local JSON packages.") {
                MigrationAssistantPanel(
                    selectedWorkflow: $selectedWorkflow,
                    exportCounts: exportCounts,
                    dryRun: dryRun,
                    pendingPackageAvailable: pendingPackage != nil,
                    hasUnsupportedSchema: dryRun.map { hasUnsupportedSchema($0) } ?? false,
                    lastApplyResult: lastApplyResult,
                    backupCount: backupCount,
                    onExport: exportPackage,
                    onImport: importPackage,
                    onApply: applyPendingImport,
                    onClearPendingImport: clearPendingImport,
                    onRefreshBackups: refreshBackups,
                    onRestoreLatestBackup: restoreLatestBackup
                )
            }

            if let statusMessage {
                ClearGlassSection("Status") {
                    ClearGlassInlineMessage(text: statusMessage, systemImage: "info.circle")
                }
            }
        }
        .onAppear {
            refreshBackups()
        }
    }

    private func exportPackage() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "MenuBarDeclutter-settings.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let package = exportService.createExportPackage(
                profiles: profileStore?.profiles ?? [],
                groups: groupStore?.groups ?? [],
                hotkeyBindings: hotkeyBindingStore?.bindings ?? [],
                spacerItems: spacerItemStore?.items ?? [],
                workspaceSnapshot: workspaceSwitchingService?.currentSnapshot()
            )
            let data = try exportService.encode(package)
            try data.write(to: url, options: .atomic)
            selectedWorkflow = .export
            statusMessage = "Exported settings package."
        } catch {
            statusMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    private func importPackage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try Data(contentsOf: url)
            let package = try importService.decode(data: data)
            pendingPackage = package
            lastApplyResult = nil
            dryRun = importService.dryRun(
                package: package,
                existingHotkeyBindings: hotkeyBindingStore?.bindings ?? [],
                importExperimentalSettings: false
            )
            selectedWorkflow = .importReview
            refreshBackups()
            statusMessage = "Dry-run complete. Review the package; a backup will be created before apply."
        } catch {
            statusMessage = "Import dry-run failed: \(error.localizedDescription)"
        }
    }

    private func applyPendingImport() {
        guard let pendingPackage else {
            statusMessage = "Choose a package before applying import."
            return
        }

        do {
            let result = try importService.applyWithBackup(
                package: pendingPackage,
                currentPackage: currentExportPackage(),
                backupService: backupService,
                settingsStore: settingsStore,
                profileStore: profileStore,
                groupStore: groupStore,
                hotkeyBindingStore: hotkeyBindingStore,
                spacerItemStore: spacerItemStore,
                workspaceImportHandler: { snapshot in
                    if let workspaceSwitchingService {
                        try workspaceSwitchingService.importSnapshot(snapshot)
                    }
                },
                importExperimentalSettings: false,
                selectedSections: SettingsExportSection.restorableSections,
                backupLabel: "pre-import"
            )
            lastApplyResult = result
            self.pendingPackage = nil
            selectedWorkflow = .importReview
            onImportApplied?()
            refreshBackups()
            statusMessage = "Safe import applied."
        } catch {
            statusMessage = "Import apply failed: \(error.localizedDescription)"
        }
    }

    private func clearPendingImport() {
        pendingPackage = nil
        dryRun = nil
        lastApplyResult = nil
        selectedWorkflow = .importReview
        statusMessage = "Pending import cleared."
    }

    private func restoreLatestBackup() {
        guard let backupURL = backupService.latestBackup() else {
            statusMessage = "No import backup is available to restore."
            return
        }

        do {
            let data = try backupService.readBackup(at: backupURL)
            let package = try importService.decode(data: data)
            let result = try importService.applyWithBackup(
                package: package,
                currentPackage: currentExportPackage(),
                backupService: backupService,
                settingsStore: settingsStore,
                profileStore: profileStore,
                groupStore: groupStore,
                hotkeyBindingStore: hotkeyBindingStore,
                spacerItemStore: spacerItemStore,
                workspaceImportHandler: { snapshot in
                    if let workspaceSwitchingService {
                        try workspaceSwitchingService.importSnapshot(snapshot)
                    }
                },
                importExperimentalSettings: true,
                selectedSections: SettingsExportSection.restorableSections,
                backupLabel: "pre-restore"
            )
            pendingPackage = nil
            dryRun = nil
            lastApplyResult = result
            selectedWorkflow = .backups
            onImportApplied?()
            refreshBackups()
            statusMessage = "Latest backup restored."
        } catch {
            statusMessage = "Backup restore failed: \(error.localizedDescription)"
        }
    }

    private func refreshBackups() {
        backupCount = backupService.listBackups().count
    }

    private func hasUnsupportedSchema(_ dryRun: SettingsImportDryRun) -> Bool {
        dryRun.conflicts.contains { $0.kind == .schemaMismatch }
    }

    private func currentExportPackage() -> SettingsExportPackage {
        exportService.createExportPackage(
            profiles: profileStore?.profiles ?? [],
            groups: groupStore?.groups ?? [],
            hotkeyBindings: hotkeyBindingStore?.bindings ?? [],
            spacerItems: spacerItemStore?.items ?? [],
            workspaceSnapshot: workspaceSwitchingService?.currentSnapshot()
        )
    }
}

private enum MigrationWorkflow: String, CaseIterable, Identifiable {
    case export
    case importReview
    case backups

    var id: String { rawValue }

    var title: String {
        switch self {
        case .export:
            "Export"
        case .importReview:
            "Import"
        case .backups:
            "Backups"
        }
    }

    var systemImage: String {
        switch self {
        case .export:
            "square.and.arrow.up"
        case .importReview:
            "doc.text.magnifyingglass"
        case .backups:
            "arrow.uturn.backward.circle"
        }
    }
}

private struct MigrationPackageCounts: Equatable {
    let profiles: Int
    let groups: Int
    let hotkeys: Int
    let spacers: Int
    let workspaces: Int

    var objectCount: Int {
        profiles + groups + hotkeys + spacers + workspaces
    }
}

private struct MigrationOverviewStrip: View {
    let hasPendingImport: Bool
    let backupCount: Int
    let lastApplyResult: SettingsImportApplyResult?

    var body: some View {
        ClearGlassOverviewStrip([
            ClearGlassOverviewMetric(
                title: "Pending Import",
                value: hasPendingImport ? "Review" : "None",
                systemImage: hasPendingImport ? "doc.text.magnifyingglass" : "checkmark.circle",
                style: hasPendingImport ? .warning : .secondary
            ),
            ClearGlassOverviewMetric(
                title: "Backups",
                value: "\(backupCount)",
                systemImage: "externaldrive",
                style: backupCount > 0 ? .success : .secondary
            ),
            ClearGlassOverviewMetric(
                title: "Last Apply",
                value: lastApplyResult == nil ? "None" : "Applied",
                systemImage: lastApplyResult == nil ? "clock" : "checkmark.shield",
                style: lastApplyResult == nil ? .secondary : .success
            ),
            ClearGlassOverviewMetric(
                title: "Import Mode",
                value: "Safe Apply",
                systemImage: "lock.shield",
                style: .success
            )
        ])
    }
}

private struct MigrationAssistantPanel: View {
    @Binding var selectedWorkflow: MigrationWorkflow

    let exportCounts: MigrationPackageCounts
    let dryRun: SettingsImportDryRun?
    let pendingPackageAvailable: Bool
    let hasUnsupportedSchema: Bool
    let lastApplyResult: SettingsImportApplyResult?
    let backupCount: Int
    let onExport: () -> Void
    let onImport: () -> Void
    let onApply: () -> Void
    let onClearPendingImport: () -> Void
    let onRefreshBackups: () -> Void
    let onRestoreLatestBackup: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Label("Assistant", systemImage: selectedWorkflow.systemImage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Picker("Workflow", selection: $selectedWorkflow) {
                    ForEach(MigrationWorkflow.allCases) { workflow in
                        Text(workflow.title).tag(workflow)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 320)
            }

            FeatureGateNotice(
                .preview,
                text: "Preview in v0.1.3. Export writes local JSON; import dry-runs first, then creates a backup immediately before confirmed apply."
            )

            switch selectedWorkflow {
            case .export:
                MigrationExportWorkflowView(
                    counts: exportCounts,
                    onExport: onExport
                )
            case .importReview:
                MigrationImportWorkflowView(
                    dryRun: dryRun,
                    pendingPackageAvailable: pendingPackageAvailable,
                    hasUnsupportedSchema: hasUnsupportedSchema,
                    lastApplyResult: lastApplyResult,
                    onImport: onImport,
                    onApply: onApply,
                    onClearPendingImport: onClearPendingImport
                )
            case .backups:
                MigrationBackupWorkflowView(
                    backupCount: backupCount,
                    onRefreshBackups: onRefreshBackups,
                    onRestoreLatestBackup: onRestoreLatestBackup
                )
            }
        }
    }
}

private struct MigrationExportWorkflowView: View {
    let counts: MigrationPackageCounts
    let onExport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MigrationWorkflowHeader(
                title: "Export Settings Package",
                subtitle: "Create a local JSON package with volatile support data omitted.",
                systemImage: "square.and.arrow.up",
                statusText: "Privacy Safe",
                statusStyle: .success
            )

            ClearGlassGroupedList("Package Contents", subtitle: "The package reflects the settings stores currently attached to this window.") {
                MigrationPackageScopeGrid(counts: counts)

                ClearGlassDivider()

                ClearGlassStatusControlRow(
                    systemImage: "doc.badge.gearshape",
                    title: "Export Settings Package",
                    subtitle: "Includes user settings, groups, hotkeys, spacers, profiles, and Private Access policy.",
                    statusStyle: .info
                ) {
                    Button("Export Package", systemImage: "square.and.arrow.up", action: onExport)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }

            ClearGlassInlineMessage(
                text: "Diagnostics logs, screenshots, screen contents, and Accessibility snapshots are excluded.",
                systemImage: "checkmark.shield",
                style: .success
            )
        }
    }
}

private struct MigrationImportWorkflowView: View {
    let dryRun: SettingsImportDryRun?
    let pendingPackageAvailable: Bool
    let hasUnsupportedSchema: Bool
    let lastApplyResult: SettingsImportApplyResult?
    let onImport: () -> Void
    let onApply: () -> Void
    let onClearPendingImport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MigrationWorkflowHeader(
                title: "Import Review",
                subtitle: "Choose a package, inspect the dry-run, then apply the safe import.",
                systemImage: "doc.text.magnifyingglass",
                statusText: headerStatusText,
                statusStyle: headerStatusStyle
            )

            ClearGlassGroupedList("Package Review", subtitle: "Safe apply never enables experimental settings from an imported package.") {
                ClearGlassStatusControlRow(
                    systemImage: "square.and.arrow.down",
                    title: "Choose Package",
                    subtitle: "Select a local JSON package. Dry-run does not mutate settings; a backup is created only when you apply.",
                    statusStyle: .info
                ) {
                    Button("Choose File", systemImage: "doc.badge.plus", action: onImport)
                        .controlSize(.small)
                }

                ClearGlassDivider()

                if let dryRun {
                    MigrationImportReviewPanel(
                        dryRun: dryRun,
                        pendingPackageAvailable: pendingPackageAvailable,
                        hasUnsupportedSchema: hasUnsupportedSchema,
                        onApply: onApply,
                        onClearPendingImport: onClearPendingImport
                    )
                } else {
                    SettingsUnavailableGate(
                        .emptyData,
                        title: "No Package Selected",
                        message: "Choose a JSON package to run a local import review.",
                        systemImage: "doc.text.magnifyingglass",
                        minHeight: 150,
                        nextSteps: ["Choose a package.", "Review the dry-run before applying."]
                    )
                    .frame(maxWidth: .infinity, minHeight: 150)
                }

                if let lastApplyResult {
                    ClearGlassDivider()
                    MigrationApplyResultPanel(result: lastApplyResult)
                }
            }
        }
    }

    private var headerStatusText: String {
        if hasUnsupportedSchema {
            return "Blocked"
        }
        if pendingPackageAvailable {
            return "Ready"
        }
        return dryRun == nil ? "Choose File" : "Applied"
    }

    private var headerStatusStyle: ClearGlassStatusStyle {
        if hasUnsupportedSchema {
            return .danger
        }
        if pendingPackageAvailable {
            return .warning
        }
        return dryRun == nil ? .secondary : .success
    }
}

private struct MigrationBackupWorkflowView: View {
    let backupCount: Int
    let onRefreshBackups: () -> Void
    let onRestoreLatestBackup: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MigrationWorkflowHeader(
                title: "Backups",
                subtitle: "Restore points are local files created before imports are applied.",
                systemImage: "externaldrive",
                statusText: backupCount > 0 ? "\(backupCount) Available" : "None",
                statusStyle: backupCount > 0 ? .success : .secondary
            )

            ClearGlassGroupedList("Local Restore Points", subtitle: "Refresh the local backup count or restore the newest backup package.") {
                ClearGlassStatusControlRow(
                    systemImage: "externaldrive",
                    title: "Available Backups",
                    subtitle: "Backups are stored locally in MenuBarDeclutter application support.",
                    statusStyle: backupCount > 0 ? .success : .secondary
                ) {
                    Text(backupCount, format: .number)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .trailing)
                }

                ClearGlassDivider()

                ClearGlassActionStrip(
                    "Backup Actions",
                    subtitle: "Refresh restore points or restore the newest local backup package.",
                    systemImage: "externaldrive",
                    statusText: backupCount > 0 ? "Ready" : "None",
                    statusStyle: backupCount > 0 ? .success : .secondary
                ) {
                    backupButtons
                }
                .padding(.vertical, 8)
            }

            ClearGlassInlineMessage(
                text: "Restoring a backup uses the full backup package so local recovery can return experimental flags to their saved state.",
                systemImage: "arrow.uturn.backward.circle",
                style: .info
            )
        }
    }

    @ViewBuilder
    private var backupButtons: some View {
        Button("Refresh Backups", systemImage: "arrow.clockwise", action: onRefreshBackups)

        Button("Restore Latest Backup", systemImage: "arrow.uturn.backward.circle", action: onRestoreLatestBackup)
            .disabled(backupCount == 0)
    }
}

private struct MigrationImportReviewPanel: View {
    let dryRun: SettingsImportDryRun
    let pendingPackageAvailable: Bool
    let hasUnsupportedSchema: Bool
    let onApply: () -> Void
    let onClearPendingImport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                Label("Dry-run Complete", systemImage: "doc.text.magnifyingglass")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                ClearGlassStatusValue(text: reviewStatusText, style: reviewStatusStyle)
            }

            MigrationDryRunMetricGrid(dryRun: dryRun)

            if dryRun.hasConflicts {
                ClearGlassInlineMessage(
                    text: dryRun.conflicts.map(\.description).joined(separator: "\n"),
                    systemImage: hasUnsupportedSchema ? "xmark.octagon" : "exclamationmark.triangle",
                    style: hasUnsupportedSchema ? .danger : .warning
                )
            }

            if dryRun.hasRisks {
                ClearGlassInlineMessage(
                    text: "Safe apply skips experimental enablement unless a future explicit experimental import option is added.",
                    systemImage: "checkmark.shield",
                    style: .success
                )
            }

            ClearGlassActionStrip(
                "Import Actions",
                subtitle: "Apply only after review, or clear the pending package and choose another file.",
                systemImage: hasUnsupportedSchema ? "xmark.octagon" : "checkmark.shield",
                iconTint: hasUnsupportedSchema ? .red : .accentColor,
                statusText: reviewStatusText,
                statusStyle: reviewStatusStyle
            ) {
                importButtons
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var importButtons: some View {
        Button("Apply Safe Import", systemImage: "checkmark.shield", action: onApply)
            .buttonStyle(.borderedProminent)
            .disabled(!pendingPackageAvailable || hasUnsupportedSchema)

        Button("Clear Pending Import", systemImage: "xmark.circle", action: onClearPendingImport)
            .disabled(!pendingPackageAvailable)
    }

    private var reviewStatusText: String {
        if hasUnsupportedSchema {
            return "Blocked"
        }
        if dryRun.hasConflicts || dryRun.hasRisks {
            return "Review"
        }
        return "Ready"
    }

    private var reviewStatusStyle: ClearGlassStatusStyle {
        if hasUnsupportedSchema {
            return .danger
        }
        if dryRun.hasConflicts || dryRun.hasRisks {
            return .warning
        }
        return .success
    }
}

private struct MigrationApplyResultPanel: View {
    let result: SettingsImportApplyResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                Label("Last Apply Result", systemImage: "checkmark.shield")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                ClearGlassStatusValue(text: "Applied", style: .success)
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ClearGlassMetricTile(value: "\(result.appliedSettings)", label: "Applied Settings")
                ClearGlassMetricTile(value: "\(result.skippedSettings)", label: "Skipped Settings")
                ClearGlassMetricTile(value: "\(result.importedObjectCount)", label: "Imported Objects")
                ClearGlassMetricTile(value: "\(result.skippedHotkeys)", label: "Skipped Hotkeys")
            }

            if !result.skippedExperimentalFlags.isEmpty {
                ClearGlassInlineMessage(
                    text: "Skipped Labs enablement: \(result.skippedExperimentalFlags.joined(separator: ", ")).",
                    systemImage: "checkmark.shield",
                    style: .success
                )
            }
        }
        .padding(.vertical, 8)
    }

    private let columns = [
        GridItem(.adaptive(minimum: 132), spacing: 8)
    ]
}

private struct MigrationPackageScopeGrid: View {
    let counts: MigrationPackageCounts

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ClearGlassMetricTile(value: "\(counts.profiles)", label: "Profiles")
            ClearGlassMetricTile(value: "\(counts.groups)", label: "Groups")
            ClearGlassMetricTile(value: "\(counts.hotkeys)", label: "Hotkeys")
            ClearGlassMetricTile(value: "\(counts.spacers)", label: "Spacers")
            ClearGlassMetricTile(value: "\(counts.workspaces)", label: "Workspaces")
        }
        .padding(.vertical, 8)
    }

    private let columns = [
        GridItem(.adaptive(minimum: 132), spacing: 8)
    ]
}

private struct MigrationDryRunMetricGrid: View {
    let dryRun: SettingsImportDryRun

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ClearGlassMetricTile(value: "\(dryRun.modifiedSettings)", label: "Modified Settings")
            ClearGlassMetricTile(value: "\(dryRun.addedProfiles)", label: "Profiles")
            ClearGlassMetricTile(value: "\(dryRun.addedGroups)", label: "Groups")
            ClearGlassMetricTile(value: "\(dryRun.addedHotkeys)", label: "Hotkeys")
            ClearGlassMetricTile(value: "\(dryRun.addedSpacers)", label: "Spacers")
            ClearGlassMetricTile(value: "\(dryRun.addedWorkspaces)", label: "Workspaces")
        }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 132), spacing: 8)
    ]
}

private struct MigrationWorkflowHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let statusText: String
    let statusStyle: ClearGlassStatusStyle

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(statusStyle.tint.opacity(0.12))

                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(statusStyle.tint)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ClearGlassStatusValue(text: statusText, style: statusStyle)
                .fixedSize()
                .padding(.top, 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
        }
    }
}

@MainActor
final class MigrationAssistantWindowController: NSWindowController {
    init(rootView: MigrationAssistantRootView) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Import / Export"
        window.contentViewController = NSHostingController(rootView: rootView)
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("MigrationAssistantWindowController does not support storyboards.")
    }
}
