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
            spacers: spacerItemStore?.items.count ?? 0
        )
    }

    var body: some View {
        ClearGlassSettingsPage(
            "Import / Export",
            subtitle: "Move local MenuBarDeclutter configuration explicitly and safely.",
            badges: [.preview, .privacySafe]
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
                spacerItems: spacerItemStore?.items ?? []
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
            _ = try backupService.createBackup(data: exportService.encode(exportService.createExportPackage(
                profiles: profileStore?.profiles ?? [],
                groups: groupStore?.groups ?? [],
                hotkeyBindings: hotkeyBindingStore?.bindings ?? [],
                spacerItems: spacerItemStore?.items ?? []
            )))
            selectedWorkflow = .importReview
            refreshBackups()
            statusMessage = "Dry-run complete. Backup created; review and apply safe import when ready."
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
            let result = try importService.apply(
                package: pendingPackage,
                settingsStore: settingsStore,
                profileStore: profileStore,
                groupStore: groupStore,
                hotkeyBindingStore: hotkeyBindingStore,
                spacerItemStore: spacerItemStore,
                importExperimentalSettings: false
            )
            lastApplyResult = result
            self.pendingPackage = nil
            selectedWorkflow = .importReview
            onImportApplied?()
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
            let result = try importService.apply(
                package: package,
                settingsStore: settingsStore,
                profileStore: profileStore,
                groupStore: groupStore,
                hotkeyBindingStore: hotkeyBindingStore,
                spacerItemStore: spacerItemStore,
                importExperimentalSettings: true
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

    var objectCount: Int {
        profiles + groups + hotkeys + spacers
    }
}

private struct MigrationOverviewStrip: View {
    let hasPendingImport: Bool
    let backupCount: Int
    let lastApplyResult: SettingsImportApplyResult?

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            MigrationOverviewPill(
                title: "Pending Import",
                value: hasPendingImport ? "Review" : "None",
                systemImage: hasPendingImport ? "doc.text.magnifyingglass" : "checkmark.circle",
                style: hasPendingImport ? .warning : .secondary
            )

            MigrationOverviewPill(
                title: "Backups",
                value: "\(backupCount)",
                systemImage: "externaldrive",
                style: backupCount > 0 ? .success : .secondary
            )

            MigrationOverviewPill(
                title: "Last Apply",
                value: lastApplyResult == nil ? "None" : "Applied",
                systemImage: lastApplyResult == nil ? "clock" : "checkmark.shield",
                style: lastApplyResult == nil ? .secondary : .success
            )

            MigrationOverviewPill(
                title: "Import Mode",
                value: "Safe Apply",
                systemImage: "lock.shield",
                style: .success
            )
        }
    }
}

private struct MigrationOverviewPill: View {
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
                    .minimumScaleFactor(0.85)
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
                text: "Preview in v0.1.1. Export writes local JSON; import dry-runs, backs up, then applies only after confirmation."
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

            MigrationGroupedBox("Package Contents", subtitle: "The package reflects the settings stores currently attached to this window.") {
                MigrationPackageScopeGrid(counts: counts)

                migrationDivider

                MigrationRow(
                    title: "Export Settings Package",
                    subtitle: "Includes user settings, groups, hotkeys, spacers, profiles, and Private Access policy.",
                    systemImage: "doc.badge.gearshape",
                    style: .info
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

            MigrationGroupedBox("Package Review", subtitle: "Safe apply never enables experimental settings from an imported package.") {
                MigrationRow(
                    title: "Choose Package",
                    subtitle: "Select a local JSON package. A backup is created before safe apply becomes available.",
                    systemImage: "square.and.arrow.down",
                    style: .info
                ) {
                    Button("Choose File", systemImage: "doc.badge.plus", action: onImport)
                        .controlSize(.small)
                }

                migrationDivider

                if let dryRun {
                    MigrationImportReviewPanel(
                        dryRun: dryRun,
                        pendingPackageAvailable: pendingPackageAvailable,
                        hasUnsupportedSchema: hasUnsupportedSchema,
                        onApply: onApply,
                        onClearPendingImport: onClearPendingImport
                    )
                } else {
                    ContentUnavailableView(
                        "No Package Selected",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Choose a JSON package to run a local import review.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 140)
                }

                if let lastApplyResult {
                    migrationDivider
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

            MigrationGroupedBox("Local Restore Points", subtitle: "Refresh the local backup count or restore the newest backup package.") {
                MigrationRow(
                    title: "Available Backups",
                    subtitle: "Backups are stored locally in MenuBarDeclutter application support.",
                    systemImage: "externaldrive",
                    style: backupCount > 0 ? .success : .secondary
                ) {
                    Text(backupCount, format: .number)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .trailing)
                }

                migrationDivider

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        backupButtons
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        backupButtons
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
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

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    importButtons
                }

                VStack(alignment: .leading, spacing: 8) {
                    importButtons
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
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
                MigrationMetricTile(value: "\(result.appliedSettings)", label: "Applied Settings")
                MigrationMetricTile(value: "\(result.skippedSettings)", label: "Skipped Settings")
                MigrationMetricTile(value: "\(result.importedObjectCount)", label: "Imported Objects")
                MigrationMetricTile(value: "\(result.skippedHotkeys)", label: "Skipped Hotkeys")
            }

            if !result.skippedExperimentalFlags.isEmpty {
                ClearGlassInlineMessage(
                    text: "Skipped experimental enablement: \(result.skippedExperimentalFlags.joined(separator: ", ")).",
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
            MigrationMetricTile(value: "\(counts.profiles)", label: "Profiles")
            MigrationMetricTile(value: "\(counts.groups)", label: "Groups")
            MigrationMetricTile(value: "\(counts.hotkeys)", label: "Hotkeys")
            MigrationMetricTile(value: "\(counts.spacers)", label: "Spacers")
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
            MigrationMetricTile(value: "\(dryRun.modifiedSettings)", label: "Modified Settings")
            MigrationMetricTile(value: "\(dryRun.addedProfiles)", label: "Profiles")
            MigrationMetricTile(value: "\(dryRun.addedGroups)", label: "Groups")
            MigrationMetricTile(value: "\(dryRun.addedHotkeys)", label: "Hotkeys")
            MigrationMetricTile(value: "\(dryRun.addedSpacers)", label: "Spacers")
        }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 132), spacing: 8)
    ]
}

private struct MigrationMetricTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: .rect(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(nsColor: .separatorColor).opacity(0.36), lineWidth: 0.5)
        }
    }
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

private struct MigrationGroupedBox<Content: View>: View {
    private let title: String
    private let subtitle: String?
    @ViewBuilder private let content: Content

    init(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 2)

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.42), lineWidth: 0.5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MigrationRow<Accessory: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let style: ClearGlassStatusStyle
    @ViewBuilder let accessory: Accessory

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        style: ClearGlassStatusStyle = .secondary,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.style = style
        self.accessory = accessory()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 12) {
                rowLabel
                    .frame(maxWidth: .infinity, alignment: .leading)

                accessory
                    .fixedSize()
            }

            VStack(alignment: .leading, spacing: 8) {
                rowLabel
                accessory
                    .fixedSize()
            }
        }
        .padding(.vertical, 8)
    }

    private var rowLabel: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15))
                .foregroundStyle(style.tint)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body)

                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private var migrationDivider: some View {
    Divider()
        .padding(.leading, 34)
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
