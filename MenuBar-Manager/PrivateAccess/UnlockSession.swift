import Foundation

/// Manages the unlock session that caches a successful authentication
/// for a configured duration.
@MainActor
final class UnlockSession {
    private let now: () -> Date
    private var unlockedAt: Date?
    private let durationProvider: () -> Double

    init(
        durationProvider: @escaping () -> Double,
        now: @escaping () -> Date = { Date() }
    ) {
        self.durationProvider = durationProvider
        self.now = now
    }

    /// Whether the session is currently active (unlocked and not expired).
    var isActive: Bool {
        guard let unlockedAt else { return false }
        let expiry = unlockedAt.addingTimeInterval(durationProvider())
        return now() < expiry
    }

    /// Mark the session as unlocked.
    func unlock() {
        unlockedAt = now()
    }

    /// Clear the unlock session.
    func clear() {
        unlockedAt = nil
    }

    /// Time remaining until the session expires, or 0 if not active.
    var remainingSeconds: Double {
        guard let unlockedAt, isActive else { return 0 }
        let expiry = unlockedAt.addingTimeInterval(durationProvider())
        return max(0, expiry.timeIntervalSince(now()))
    }
}
