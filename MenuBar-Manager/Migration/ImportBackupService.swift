import Foundation

/// Service for creating backups before import operations.
@MainActor
final class ImportBackupService {
    private let backupsDirectory: URL
    private let fileManager: FileManager
    private let diagnosticsLogger: DiagnosticsLogger?
    private let now: () -> Date

    init(
        backupsDirectory: URL,
        fileManager: FileManager = .default,
        diagnosticsLogger: DiagnosticsLogger? = nil,
        now: @escaping () -> Date = { Date() }
    ) {
        self.backupsDirectory = backupsDirectory
        self.fileManager = fileManager
        self.diagnosticsLogger = diagnosticsLogger
        self.now = now
    }

    /// Create a backup of the current settings data.
    func createBackup(data: Data, label: String = "pre-import") throws -> URL {
        try fileManager.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)
        let timestamp = backupTimestampFormatter.string(from: now())
        let backupURL = backupsDirectory.appendingPathComponent("settings-\(label)-\(timestamp).json")
        try data.write(to: backupURL, options: .atomic)
        diagnosticsLogger?.log("Import backup created: \(label).", category: .recovery)
        return backupURL
    }

    /// List available backups.
    func listBackups() -> [URL] {
        guard let urls = try? fileManager.contentsOfDirectory(at: backupsDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
            return []
        }
        return urls.filter { $0.pathExtension == "json" }
    }

    /// Read a backup file.
    func readBackup(at url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    private let backupTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
