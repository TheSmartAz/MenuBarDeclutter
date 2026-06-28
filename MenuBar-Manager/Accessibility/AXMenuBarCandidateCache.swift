import Foundation

nonisolated struct AXMenuBarCandidateCache {
    private(set) var cachedProcessIdentifiers: [pid_t] = []

    func orderedProcessIdentifiers(forRunningProcessIdentifiers runningProcessIdentifiers: [pid_t]) -> [pid_t] {
        let running = Self.unique(runningProcessIdentifiers)
        let runningSet = Set(running)
        let cached = cachedProcessIdentifiers.filter { runningSet.contains($0) }
        let cachedSet = Set(cached)
        return cached + running.filter { cachedSet.contains($0) == false }
    }

    mutating func update(
        successfulProcessIdentifiers: [pid_t],
        runningProcessIdentifiers: [pid_t],
        completedFullSweep: Bool
    ) {
        let runningSet = Set(Self.unique(runningProcessIdentifiers))
        let successful = Self.unique(successfulProcessIdentifiers)
            .filter { runningSet.contains($0) }

        if completedFullSweep {
            cachedProcessIdentifiers = successful
            return
        }

        let retained = cachedProcessIdentifiers.filter { runningSet.contains($0) }
        cachedProcessIdentifiers = Self.unique(successful + retained)
    }

    mutating func invalidate() {
        cachedProcessIdentifiers.removeAll()
    }

    private static func unique(_ processIdentifiers: [pid_t]) -> [pid_t] {
        var seen: Set<pid_t> = []
        return processIdentifiers.filter { seen.insert($0).inserted }
    }
}
