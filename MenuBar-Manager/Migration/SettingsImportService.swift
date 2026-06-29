import Foundation

/// Import conflict information.
nonisolated struct ImportConflict: Equatable, Sendable {
    let kind: Kind
    let description: String

    enum Kind: String, Sendable {
        case hotkeyConflict
        case experimentalFlag
        case profileNameConflict
        case schemaMismatch
    }
}

/// Dry-run result of an import operation.
nonisolated struct SettingsImportDryRun: Equatable, Sendable {
    let addedProfiles: Int
    let modifiedSettings: Int
    let addedGroups: Int
    let addedHotkeys: Int
    let addedSpacers: Int
    let conflicts: [ImportConflict]
    let riskyExperimentalFlags: [String]
    let wouldEnableIconMoving: Bool
    let wouldEnableSpacingLabs: Bool
    let wouldEnableSmartTriggers: Bool

    var hasConflicts: Bool { !conflicts.isEmpty }
    var hasRisks: Bool { !riskyExperimentalFlags.isEmpty || wouldEnableIconMoving || wouldEnableSpacingLabs || wouldEnableSmartTriggers }
}

/// Service for importing settings from a JSON package.
@MainActor
final class SettingsImportService {
    private let diagnosticsLogger: DiagnosticsLogger

    init(diagnosticsLogger: DiagnosticsLogger) {
        self.diagnosticsLogger = diagnosticsLogger
    }

    /// Decode a package from JSON data.
    func decode(data: Data) throws -> SettingsExportPackage {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SettingsExportPackage.self, from: data)
    }

    /// Perform a dry-run analysis of what the import would change.
    func dryRun(
        package: SettingsExportPackage,
        existingHotkeyBindings: [HotkeyBinding] = [],
        importExperimentalSettings: Bool = false
    ) -> SettingsImportDryRun {
        var conflicts: [ImportConflict] = []
        var riskyFlags: [String] = []

        // Check for hotkey conflicts
        for newBinding in package.hotkeyBindings {
            if HotkeyConflictDetector.wouldConflict(newBinding, in: existingHotkeyBindings) {
                conflicts.append(ImportConflict(
                    kind: .hotkeyConflict,
                    description: "Hotkey binding '\(newBinding.label)' conflicts with an existing binding."
                ))
            }
        }

        // Check for experimental flags
        let wouldEnableIconMoving = package.settings["iconMovingEnabled"] == "true"
        let wouldEnableSpacingLabs = package.settings["menuBarSpacingLabsEnabled"] == "true"
        let wouldEnableSmartTriggers = package.settings["smartTriggersEnabled"] == "true"

        if wouldEnableIconMoving {
            riskyFlags.append("Icon moving would be enabled.")
        }
        if wouldEnableSpacingLabs {
            riskyFlags.append("Menu Bar Spacing Labs would be enabled.")
        }
        if wouldEnableSmartTriggers {
            riskyFlags.append("Smart triggers would be enabled.")
        }

        if !importExperimentalSettings {
            for flag in riskyFlags {
                conflicts.append(ImportConflict(kind: .experimentalFlag, description: flag))
            }
        }

        // Schema check
        if package.packageVersion != 1 {
            conflicts.append(ImportConflict(
                kind: .schemaMismatch,
                description: "Package version \(package.packageVersion) may not be fully supported."
            ))
        }

        return SettingsImportDryRun(
            addedProfiles: package.profiles.count,
            modifiedSettings: package.settings.count,
            addedGroups: package.groups.count,
            addedHotkeys: package.hotkeyBindings.count,
            addedSpacers: package.spacerItems.count,
            conflicts: conflicts,
            riskyExperimentalFlags: riskyFlags,
            wouldEnableIconMoving: wouldEnableIconMoving,
            wouldEnableSpacingLabs: wouldEnableSpacingLabs,
            wouldEnableSmartTriggers: wouldEnableSmartTriggers
        )
    }
}
