import Foundation

enum AsyncPause {
    static func sleep(_ interval: TimeInterval) async -> Bool {
        guard !Task.isCancelled else { return false }
        guard interval.isFinite, interval > 0 else { return true }

        let nanoseconds = UInt64((interval * 1_000_000_000).rounded())
        do {
            try await Task.sleep(nanoseconds: nanoseconds)
            return !Task.isCancelled
        } catch {
            return false
        }
    }
}
