import Foundation

struct WorkspaceBackupService {
    let backupsDirectory: URL
    var fileManager: FileManager = .default
    var now: () -> Date = { Date() }

    func backup(fileURL: URL, reason: WorkspaceBackupReason) throws -> URL? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        try fileManager.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)

        let filename = "workspaces-\(reason.rawValue)-\(Self.stamp(now())).json"
        let target = backupsDirectory.appendingPathComponent(filename)

        guard target.standardizedFileURL.path.hasPrefix(backupsDirectory.standardizedFileURL.path) else {
            throw WorkspaceStoreError.backupEscapedAppSupport
        }

        if fileManager.fileExists(atPath: target.path) {
            try fileManager.removeItem(at: target)
        }
        try fileManager.copyItem(at: fileURL, to: target)
        return target
    }

    private static func stamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: date)
    }
}
