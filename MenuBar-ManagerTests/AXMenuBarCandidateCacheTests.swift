import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("AXMenuBarCandidateCache")
struct AXMenuBarCandidateCacheTests {
    @Test func orderedProcessIdentifiersUseCachedPIDsBeforeRemainingRunningPIDs() {
        var cache = AXMenuBarCandidateCache()
        cache.update(
            successfulProcessIdentifiers: [3, 1],
            runningProcessIdentifiers: [1, 2, 3, 4],
            completedFullSweep: true
        )

        #expect(
            cache.orderedProcessIdentifiers(forRunningProcessIdentifiers: [1, 2, 3, 4])
                == [3, 1, 2, 4]
        )
    }

    @Test func orderedProcessIdentifiersDropTerminatedPIDsAndDeduplicateRunningPIDs() {
        var cache = AXMenuBarCandidateCache()
        cache.update(
            successfulProcessIdentifiers: [2, 2, 5],
            runningProcessIdentifiers: [1, 2, 2, 3],
            completedFullSweep: true
        )

        #expect(cache.cachedProcessIdentifiers == [2])
        #expect(
            cache.orderedProcessIdentifiers(forRunningProcessIdentifiers: [1, 2, 2, 3])
                == [2, 1, 3]
        )
    }

    @Test func completedSweepReplacesCachedPIDsWithCurrentSuccessfulPIDs() {
        var cache = AXMenuBarCandidateCache()
        cache.update(
            successfulProcessIdentifiers: [4, 2],
            runningProcessIdentifiers: [1, 2, 4],
            completedFullSweep: true
        )
        cache.update(
            successfulProcessIdentifiers: [1],
            runningProcessIdentifiers: [1, 2, 4],
            completedFullSweep: true
        )

        #expect(cache.cachedProcessIdentifiers == [1])
        #expect(
            cache.orderedProcessIdentifiers(forRunningProcessIdentifiers: [1, 2, 4])
                == [1, 2, 4]
        )
    }

    @Test func partialSweepRetainsPreviouslyCachedRunningPIDs() {
        var cache = AXMenuBarCandidateCache()
        cache.update(
            successfulProcessIdentifiers: [4, 2],
            runningProcessIdentifiers: [1, 2, 4],
            completedFullSweep: true
        )
        cache.update(
            successfulProcessIdentifiers: [3],
            runningProcessIdentifiers: [1, 2, 3, 4],
            completedFullSweep: false
        )

        #expect(cache.cachedProcessIdentifiers == [3, 4, 2])
        #expect(
            cache.orderedProcessIdentifiers(forRunningProcessIdentifiers: [1, 2, 3, 4])
                == [3, 4, 2, 1]
        )
    }

    @Test func invalidateClearsCachedPriority() {
        var cache = AXMenuBarCandidateCache()
        cache.update(
            successfulProcessIdentifiers: [2],
            runningProcessIdentifiers: [1, 2, 3],
            completedFullSweep: true
        )

        cache.invalidate()

        #expect(cache.cachedProcessIdentifiers.isEmpty)
        #expect(
            cache.orderedProcessIdentifiers(forRunningProcessIdentifiers: [1, 2, 3])
                == [1, 2, 3]
        )
    }
}
