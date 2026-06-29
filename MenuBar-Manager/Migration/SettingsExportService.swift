import Foundation

/// Service for exporting settings to a JSON package.
@MainActor
final class SettingsExportService {
    private let settingsStore: SettingsStore
    private let diagnosticsLogger: DiagnosticsLogger
    private let appVersionProvider: () -> String

    init(
        settingsStore: SettingsStore,
        diagnosticsLogger: DiagnosticsLogger,
        appVersionProvider: @escaping () -> String = { AppConstants.appVersion }
    ) {
        self.settingsStore = settingsStore
        self.diagnosticsLogger = diagnosticsLogger
        self.appVersionProvider = appVersionProvider
    }

    /// Create an export package from current settings.
    func createExportPackage(
        groups: [IconGroup] = [],
        hotkeyBindings: [HotkeyBinding] = [],
        spacerItems: [SpacerItemModel] = [],
        includeAXSnapshots: Bool = false
    ) -> SettingsExportPackage {
        let settings = exportSettingsDict()

        let privateAccessPolicy = PrivateAccessPolicyExport(
            isEnabled: settingsStore.privateAccessEnabled,
            protectAlwaysHidden: settingsStore.privateAccessProtectAlwaysHidden,
            protectSecondBar: settingsStore.privateAccessProtectSecondBar,
            protectFindIcon: settingsStore.privateAccessProtectFindIcon,
            protectIconMoving: settingsStore.privateAccessProtectIconMoving,
            protectSpacingLabs: settingsStore.privateAccessProtectSpacingLabs,
            protectedGroupsRequireAuth: settingsStore.protectedGroupsRequireAuth,
            unlockDurationSeconds: settingsStore.privateAccessUnlockDurationSeconds,
            allowDevicePasswordFallback: settingsStore.privateAccessAllowDevicePasswordFallback
        )

        return SettingsExportPackage(
            appVersion: appVersionProvider(),
            settings: settings,
            groups: groups,
            hotkeyBindings: hotkeyBindings,
            spacerItems: spacerItems,
            privateAccessPolicy: privateAccessPolicy,
            includeAXSnapshots: includeAXSnapshots
        )
    }

    /// Encode the package to JSON data.
    func encode(_ package: SettingsExportPackage) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(package)
    }

    private func exportSettingsDict() -> [String: String] {
        Dictionary(
            uniqueKeysWithValues: SettingsStore.Key.allCases.map { key in
                (key.rawValue, "exported")
            }
        )
    }
}
