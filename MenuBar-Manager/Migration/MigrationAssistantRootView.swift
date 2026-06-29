import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct MigrationAssistantRootView: View {
    @Bindable var settingsStore: SettingsStore
    let appSupportPaths: AppSupportPaths
    let diagnosticsLogger: DiagnosticsLogger
    let groups: [IconGroup]
    let hotkeyBindings: [HotkeyBinding]
    let spacerItems: [SpacerItemModel]

    @State private var statusMessage: String?
    @State private var dryRun: SettingsImportDryRun?
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
            badges: [.privacySafe]
        ) {
            ClearGlassSection("Export") {
                ClearGlassControlRow(
                    systemImage: "square.and.arrow.up",
                    title: "Export Full Settings",
                    subtitle: "Exports settings, groups, hotkeys, spacer items, and Private Access policy. Active unlock sessions are excluded."
                ) {
                    Button("Export", systemImage: "square.and.arrow.up") {
                        exportPackage()
                    }
                }

                ClearGlassInlineMessage(
                    text: "Diagnostics logs, screenshots, screen contents, and Accessibility snapshots are not included by default.",
                    systemImage: "checkmark.shield",
                    style: .success
                )
            }

            ClearGlassSection("Import") {
                ClearGlassControlRow(
                    systemImage: "square.and.arrow.down",
                    title: "Import Package",
                    subtitle: "Choose a package manually. Import is dry-run first and never silently enables experimental flags."
                ) {
                    Button("Choose File", systemImage: "doc.badge.plus") {
                        importPackage()
                    }
                }

                if let dryRun {
                    importDryRunView(dryRun)
                }
            }

            ClearGlassSection("Backups") {
                ClearGlassValueRow("Available Backups") {
                    Text(backupCount, format: .number)
                        .font(.system(.body, design: .monospaced))
                }

                Button("Refresh Backups", systemImage: "arrow.clockwise") {
                    refreshBackups()
                }
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
            ClearGlassValueRow("Modified Settings") { Text(dryRun.modifiedSettings, format: .number) }
            ClearGlassValueRow("Added Groups") { Text(dryRun.addedGroups, format: .number) }
            ClearGlassValueRow("Added Hotkeys") { Text(dryRun.addedHotkeys, format: .number) }
            ClearGlassValueRow("Added Spacers") { Text(dryRun.addedSpacers, format: .number) }

            if dryRun.hasConflicts {
                ClearGlassInlineMessage(
                    text: dryRun.conflicts.map(\.description).joined(separator: " "),
                    systemImage: "exclamationmark.triangle",
                    style: .warning
                )
            }
        }
    }

    private func exportPackage() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "MenuBarDeclutter-settings.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let package = exportService.createExportPackage(
                groups: groups,
                hotkeyBindings: hotkeyBindings,
                spacerItems: spacerItems
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
            dryRun = importService.dryRun(
                package: package,
                existingHotkeyBindings: hotkeyBindings,
                importExperimentalSettings: false
            )
            _ = try backupService.createBackup(data: exportService.encode(exportService.createExportPackage(
                groups: groups,
                hotkeyBindings: hotkeyBindings,
                spacerItems: spacerItems
            )))
            refreshBackups()
            statusMessage = "Dry-run complete. Backup created before applying any future import."
        } catch {
            statusMessage = "Import dry-run failed: \(error.localizedDescription)"
        }
    }

    private func refreshBackups() {
        backupCount = backupService.listBackups().count
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
