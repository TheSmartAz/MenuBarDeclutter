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
        return urls
            .filter { $0.pathExtension == "json" }
            .sorted { lhs, rhs in
                let lhsDate = backupDate(for: lhs)
                let rhsDate = backupDate(for: rhs)
                if lhsDate == rhsDate {
                    return lhs.lastPathComponent > rhs.lastPathComponent
                }
                return lhsDate > rhsDate
            }
    }

    /// Return the most recent backup by filename timestamp, falling back to file metadata.
    func latestBackup() -> URL? {
        listBackups().first
    }

    /// Read a backup file.
    func readBackup(at url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    private func backupDate(for url: URL) -> Date {
        let basename = url.deletingPathExtension().lastPathComponent
        let timestampLength = "yyyy-MM-dd_HHmmss".count
        if basename.count >= timestampLength,
           let date = backupTimestampFormatter.date(from: String(basename.suffix(timestampLength))) {
            return date
        }

        if let values = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey]),
           let date = values.creationDate ?? values.contentModificationDate {
            return date
        }

        return .distantPast
    }

    private let backupTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
