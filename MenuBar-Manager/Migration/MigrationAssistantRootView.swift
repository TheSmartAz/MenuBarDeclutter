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

    var body: some View {
        ClearGlassSettingsPage(
            "Import / Export",
            subtitle: "Move local MenuBarDeclutter configuration explicitly and safely.",
            badges: [.preview, .privacySafe]
        ) {
            ClearGlassSection("Export", subtitle: "Create a local JSON package with volatile support data omitted.") {
                FeatureGateNotice(
                    .preview,
                    text: "Preview in v0.1.1. Export writes local JSON; import dry-runs, backs up, then applies only after confirmation."
                )

                ClearGlassDivider()

                ClearGlassControlRow(
                    systemImage: "square.and.arrow.up",
                    title: "Export Settings Package",
                    subtitle: "Exports user settings, groups, hotkeys, spacers, and Private Access policy. Volatile state is excluded."
                ) {
                    Button("Export", systemImage: "square.and.arrow.up") {
                        exportPackage()
                    }
                }

                ClearGlassInlineMessage(
                    text: "Diagnostics logs, screenshots, screen contents, and Accessibility snapshots are excluded.",
                    systemImage: "checkmark.shield",
                    style: .success
                )
            }

            ClearGlassSection("Import", subtitle: "Review packages with a dry-run before applying changes.") {
                ClearGlassControlRow(
                    systemImage: "square.and.arrow.down",
                    title: "Import Package",
                    subtitle: "Dry-runs a selected package and creates a local backup before safe apply is available."
                ) {
                    Button("Choose File", systemImage: "doc.badge.plus") {
                        importPackage()
                    }
                }

                if let dryRun {
                    ClearGlassDivider()
                    importDryRunView(dryRun)
                }

                if let lastApplyResult {
                    importApplyResultView(lastApplyResult)
                }
            }

            ClearGlassSection("Backups", subtitle: "Local restore points created before imports are applied.") {
                ClearGlassValueRow("Available Backups") {
                    Text(backupCount, format: .number)
                        .font(.system(.body, design: .monospaced))
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        backupButtons
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        backupButtons
                    }
                }
                .buttonStyle(.bordered)
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

    private func importDryRunView(_ dryRun: SettingsImportDryRun) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(spacing: 0) {
                ClearGlassValueRow("Modified Settings") { Text(dryRun.modifiedSettings, format: .number) }
                ClearGlassDivider()
                ClearGlassValueRow("Profiles in Package") { Text(dryRun.addedProfiles, format: .number) }
                ClearGlassDivider()
                ClearGlassValueRow("Groups in Package") { Text(dryRun.addedGroups, format: .number) }
                ClearGlassDivider()
                ClearGlassValueRow("Hotkeys in Package") { Text(dryRun.addedHotkeys, format: .number) }
                ClearGlassDivider()
                ClearGlassValueRow("Spacers in Package") { Text(dryRun.addedSpacers, format: .number) }
            }

            if dryRun.hasConflicts {
                ClearGlassInlineMessage(
                    text: dryRun.conflicts.map(\.description).joined(separator: "\n"),
                    systemImage: "exclamationmark.triangle",
                    style: .warning
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
                    importDryRunButtons(dryRun)
                }

                VStack(alignment: .leading, spacing: 8) {
                    importDryRunButtons(dryRun)
                }
            }
            .buttonStyle(.bordered)
        }
    }

    private func importApplyResultView(_ result: SettingsImportApplyResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ClearGlassDivider()
            VStack(spacing: 0) {
                ClearGlassValueRow("Applied Settings") { Text(result.appliedSettings, format: .number) }
                ClearGlassDivider()
                ClearGlassValueRow("Skipped Settings") { Text(result.skippedSettings, format: .number) }
                ClearGlassDivider()
                ClearGlassValueRow("Imported Objects") { Text(result.importedObjectCount, format: .number) }
                ClearGlassDivider()
                ClearGlassValueRow("Skipped Hotkeys") { Text(result.skippedHotkeys, format: .number) }
            }

            if !result.skippedExperimentalFlags.isEmpty {
                ClearGlassInlineMessage(
                    text: "Skipped experimental enablement: \(result.skippedExperimentalFlags.joined(separator: ", ")).",
                    systemImage: "checkmark.shield",
                    style: .success
                )
            }
        }
    }

    @ViewBuilder
    private func importDryRunButtons(_ dryRun: SettingsImportDryRun) -> some View {
        Button("Apply Safe Import", systemImage: "checkmark.shield") {
            applyPendingImport()
        }
        .disabled(pendingPackage == nil || hasUnsupportedSchema(dryRun))

        Button("Clear Pending Import", systemImage: "xmark.circle") {
            pendingPackage = nil
            self.dryRun = nil
            lastApplyResult = nil
            statusMessage = "Pending import cleared."
        }
        .disabled(pendingPackage == nil)
    }

    @ViewBuilder
    private var backupButtons: some View {
        Button("Refresh Backups", systemImage: "arrow.clockwise") {
            refreshBackups()
        }

        Button("Restore Latest Backup", systemImage: "arrow.uturn.backward.circle") {
            restoreLatestBackup()
        }
        .disabled(backupCount == 0)
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
            onImportApplied?()
            statusMessage = "Safe import applied."
        } catch {
            statusMessage = "Import apply failed: \(error.localizedDescription)"
        }
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
