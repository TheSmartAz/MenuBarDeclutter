import Foundation

/// Experimental, Labs-only service that adjusts global macOS menu bar item
/// spacing.
///
/// This service is explicit, reversible, and never automatic. It backs up
/// existing values before applying, provides restore and reset, and never
/// restarts system processes automatically.
@MainActor
final class MenuBarSpacingService {
    /// Minimum and maximum for custom spacing values.
    static let minCustomItemSpacing = 2
    static let maxCustomItemSpacing = 32
    static let minCustomSelectionPadding = 2
    static let maxCustomSelectionPadding = 32

    private let settingsStore: SettingsStore
    private let diagnosticsLogger: DiagnosticsLogger
    private let commandRunner: any MenuBarSpacingCommandRunner
    private let now: () -> Date

    /// Whether actual apply is enabled. When false, the service operates in
    /// dry-run mode only.
    private let enableUndocumentedSpacingDefaults: Bool

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger,
        commandRunner: any MenuBarSpacingCommandRunner,
        enableUndocumentedSpacingDefaults: Bool = false,
        now: @escaping () -> Date = { Date() }
    ) {
        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.commandRunner = commandRunner
        self.enableUndocumentedSpacingDefaults = enableUndocumentedSpacingDefaults
        self.now = now
    }

    /// Back up the current system values before applying a preset.
    @discardableResult
    func backupCurrentValues() -> MenuBarSpacingBackup? {
        let itemSpacing = commandRunner.readItemSpacing()
        let selectionPadding = commandRunner.readSelectionPadding()

        guard itemSpacing != nil || selectionPadding != nil else {
            diagnosticsLogger.log("No existing spacing values to back up.", category: .layout)
            return nil
        }

        let backup = MenuBarSpacingBackup(
            itemSpacing: itemSpacing,
            selectionPadding: selectionPadding,
            createdAt: now()
        )

        settingsStore.menuBarSpacingHasBackup = true
        diagnosticsLogger.log("Spacing values backed up.", category: .layout)
        return backup
    }

    /// Apply a preset. Returns the result of the operation.
    func apply(preset: MenuBarSpacingPreset, customItemSpacing: Int? = nil, customSelectionPadding: Int? = nil) -> MenuBarSpacingApplyResult {
        guard settingsStore.menuBarSpacingLabsEnabled else {
            return MenuBarSpacingApplyResult(success: false, isDryRun: true, message: "Menu Bar Spacing Labs is not enabled.", preset: preset)
        }

        // Back up before first apply.
        if !settingsStore.menuBarSpacingHasBackup {
            _ = backupCurrentValues()
        }

        let itemSpacing: Int?
        let selectionPadding: Int?

        switch preset {
        case .system:
            itemSpacing = nil
            selectionPadding = nil
        case .compact:
            itemSpacing = MenuBarSpacingPreset.compact.itemSpacing
            selectionPadding = MenuBarSpacingPreset.compact.selectionPadding
        case .dense:
            itemSpacing = MenuBarSpacingPreset.dense.itemSpacing
            selectionPadding = MenuBarSpacingPreset.dense.selectionPadding
        case .custom:
            itemSpacing = Self.clampItemSpacing(customItemSpacing ?? settingsStore.menuBarSpacingCustomItemSpacing)
            selectionPadding = Self.clampSelectionPadding(customSelectionPadding ?? settingsStore.menuBarSpacingCustomSelectionPadding)
        }

        // Dry-run mode: if actual apply is disabled, log and return.
        guard enableUndocumentedSpacingDefaults else {
            let msg = "Dry-run: spacing preset '\(preset.displayName)' would apply itemSpacing=\(itemSpacing.map(String.init) ?? "nil"), selectionPadding=\(selectionPadding.map(String.init) ?? "nil")."
            settingsStore.menuBarSpacingPreset = preset.rawValue
            settingsStore.menuBarSpacingLastApplyStatus = "dry-run"
            settingsStore.menuBarSpacingLastApplyDate = now()
            diagnosticsLogger.log(msg, level: .info, category: .layout)
            return MenuBarSpacingApplyResult(success: true, isDryRun: true, message: msg, preset: preset)
        }

        // Real apply.
        var success = true
        var messages: [String] = []

        if let itemSpacing {
            if !commandRunner.writeItemSpacing(itemSpacing) {
                success = false
                messages.append("Failed to write item spacing.")
            }
        } else {
            _ = commandRunner.deleteItemSpacing()
        }

        if let selectionPadding {
            if !commandRunner.writeSelectionPadding(selectionPadding) {
                success = false
                messages.append("Failed to write selection padding.")
            }
        } else {
            _ = commandRunner.deleteSelectionPadding()
        }

        settingsStore.menuBarSpacingPreset = preset.rawValue
        settingsStore.menuBarSpacingLastApplyStatus = success ? "applied" : "failed"
        settingsStore.menuBarSpacingLastApplyDate = now()

        let message = messages.isEmpty ? "Spacing preset '\(preset.displayName)' applied." : messages.joined(separator: " ")
        diagnosticsLogger.log(message, level: success ? .info : .warning, category: .layout)

        return MenuBarSpacingApplyResult(success: success, isDryRun: false, message: message, preset: preset)
    }

    /// Restore previously backed-up values.
    func restorePrevious() -> MenuBarSpacingApplyResult {
        guard settingsStore.menuBarSpacingHasBackup else {
            return MenuBarSpacingApplyResult(success: false, isDryRun: false, message: "No backup exists to restore.", preset: .system)
        }

        guard enableUndocumentedSpacingDefaults else {
            diagnosticsLogger.log("Dry-run: would restore previous spacing values.", category: .layout)
            return MenuBarSpacingApplyResult(success: true, isDryRun: true, message: "Dry-run: would restore previous spacing values.", preset: .system)
        }

        let itemSpacing = commandRunner.readItemSpacing()
        let selectionPadding = commandRunner.readSelectionPadding()

        // Restore to the backed-up values (which are what we read now,
        // since backup was done before first apply).
        if let itemSpacing {
            _ = commandRunner.writeItemSpacing(itemSpacing)
        } else {
            _ = commandRunner.deleteItemSpacing()
        }

        if let selectionPadding {
            _ = commandRunner.writeSelectionPadding(selectionPadding)
        } else {
            _ = commandRunner.deleteSelectionPadding()
        }

        settingsStore.menuBarSpacingPreset = MenuBarSpacingPreset.system.rawValue
        settingsStore.menuBarSpacingLastApplyStatus = "restored"
        settingsStore.menuBarSpacingLastApplyDate = now()
        settingsStore.menuBarSpacingHasBackup = false

        diagnosticsLogger.log("Previous spacing values restored.", category: .layout)
        return MenuBarSpacingApplyResult(success: true, isDryRun: false, message: "Previous spacing values restored.", preset: .system)
    }

    /// Reset to system default (delete all custom values).
    func resetToSystemDefault() -> MenuBarSpacingApplyResult {
        guard settingsStore.menuBarSpacingLabsEnabled else {
            return MenuBarSpacingApplyResult(success: false, isDryRun: true, message: "Menu Bar Spacing Labs is not enabled.", preset: .system)
        }

        guard enableUndocumentedSpacingDefaults else {
            diagnosticsLogger.log("Dry-run: would reset to system default.", category: .layout)
            settingsStore.menuBarSpacingPreset = MenuBarSpacingPreset.system.rawValue
            return MenuBarSpacingApplyResult(success: true, isDryRun: true, message: "Dry-run: would reset to system default.", preset: .system)
        }

        _ = commandRunner.deleteItemSpacing()
        _ = commandRunner.deleteSelectionPadding()

        settingsStore.menuBarSpacingPreset = MenuBarSpacingPreset.system.rawValue
        settingsStore.menuBarSpacingLastApplyStatus = "system-default"
        settingsStore.menuBarSpacingLastApplyDate = now()
        settingsStore.menuBarSpacingHasBackup = false

        diagnosticsLogger.log("Spacing reset to system default.", category: .layout)
        return MenuBarSpacingApplyResult(success: true, isDryRun: false, message: "Spacing reset to system default.", preset: .system)
    }

    // MARK: - Clamping

    static func clampItemSpacing(_ value: Int) -> Int {
        min(max(value, minCustomItemSpacing), maxCustomItemSpacing)
    }

    static func clampSelectionPadding(_ value: Int) -> Int {
        min(max(value, minCustomSelectionPadding), maxCustomSelectionPadding)
    }
}
