import Testing
@testable import MenuBarDeclutter

@Suite("LiveDiagnosticsStatus")
@MainActor
struct LiveDiagnosticsStatusTests {
    @Test func menuBarItemCountsUseAllSnapshotsForSearchAndOnlyConfiguredZonesForSecondBar() {
        let snapshots = [
            TestSnapshots.makeSnapshot(id: "visible", zone: .visible),
            TestSnapshots.makeSnapshot(id: "hidden", zone: .hidden),
            TestSnapshots.makeSnapshot(id: "always-hidden", zone: .alwaysHidden),
            TestSnapshots.makeSnapshot(id: "unknown", zone: .unknown)
        ]

        let counts = LiveDiagnosticsMenuBarItemCounts.counts(
            from: snapshots,
            includeHiddenInSecondBar: true,
            includeAlwaysHiddenInSecondBar: true
        )

        #expect(counts.searchIndexItemCount == 4)
        #expect(counts.secondBarItemCount == 2)
    }

    @Test func menuBarItemCountsRespectSecondBarZoneToggles() {
        let snapshots = [
            TestSnapshots.makeSnapshot(id: "hidden", zone: .hidden),
            TestSnapshots.makeSnapshot(id: "always-hidden", zone: .alwaysHidden)
        ]

        let hiddenOnly = LiveDiagnosticsMenuBarItemCounts.counts(
            from: snapshots,
            includeHiddenInSecondBar: true,
            includeAlwaysHiddenInSecondBar: false
        )
        let alwaysHiddenOnly = LiveDiagnosticsMenuBarItemCounts.counts(
            from: snapshots,
            includeHiddenInSecondBar: false,
            includeAlwaysHiddenInSecondBar: true
        )
        let neither = LiveDiagnosticsMenuBarItemCounts.counts(
            from: snapshots,
            includeHiddenInSecondBar: false,
            includeAlwaysHiddenInSecondBar: false
        )

        #expect(hiddenOnly.secondBarItemCount == 1)
        #expect(alwaysHiddenOnly.secondBarItemCount == 1)
        #expect(neither.secondBarItemCount == 0)
    }

    @Test func applyingMenuBarItemCountsUpdatesDerivedDiagnostics() {
        let liveStatus = LiveDiagnosticsStatus()

        liveStatus.updateSearchAndSecondBarItemCounts(
            LiveDiagnosticsMenuBarItemCounts(
                searchIndexItemCount: 7,
                secondBarItemCount: 3
            )
        )

        #expect(liveStatus.searchIndexItemCount == 7)
        #expect(liveStatus.secondBarItemCount == 3)
    }

    @Test func applyingSearchPerformanceUpdatesOnlyPrivacySafeMetrics() {
        let liveStatus = LiveDiagnosticsStatus()

        liveStatus.updateSearchPerformance(SearchPerformanceDiagnostics(
            indexItemCount: 12,
            resultCount: 4,
            indexRebuildDurationMilliseconds: 1.5,
            rankingDurationMilliseconds: 0.25,
            latestScanAgeSeconds: 42
        ))

        #expect(liveStatus.searchIndexItemCount == 12)
        #expect(liveStatus.searchLastResultCount == 4)
        #expect(liveStatus.searchIndexRebuildDurationMilliseconds == 1.5)
        #expect(liveStatus.searchRankingDurationMilliseconds == 0.25)
        #expect(liveStatus.searchLatestScanAgeSeconds == 42)
    }

    @Test func applyingSecondBarIconWarmUpUpdatesPrivacySafeDiagnostics() {
        let liveStatus = LiveDiagnosticsStatus()

        liveStatus.updateSecondBarIconWarmUp(
            inProgress: true,
            result: nil
        )

        #expect(liveStatus.secondBarIconWarmUpInProgress)
        #expect(liveStatus.secondBarLastIconWarmUpResult == nil)

        liveStatus.updateSecondBarIconWarmUp(
            inProgress: false,
            result: "Refreshed 2 thumbnail(s)"
        )

        #expect(!liveStatus.secondBarIconWarmUpInProgress)
        #expect(liveStatus.secondBarLastIconWarmUpResult == "Refreshed 2 thumbnail(s)")
    }

    @Test func applyingStatusBarVisibilityUpdatesRelatedDiagnostics() {
        let liveStatus = LiveDiagnosticsStatus()

        liveStatus.updateStatusBarVisibility(
            state: .collapsed,
            primarySeparatorLength: 123,
            alwaysHiddenSeparatorLength: 45,
            alwaysHiddenSeparatorInstalled: true
        )

        #expect(liveStatus.visibilityState == .collapsed)
        #expect(liveStatus.primarySeparatorLength == 123)
        #expect(liveStatus.alwaysHiddenSeparatorLength == 45)
        #expect(liveStatus.alwaysHiddenSeparatorInstalled)
    }
}
