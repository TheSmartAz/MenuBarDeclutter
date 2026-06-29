import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Dogfood")
@MainActor
struct DogfoodStoreTests {
    @Test func runIDCreationIsDeterministic() {
        let date = Self.date(year: 2026, month: 6, day: 28, hour: 12, minute: 34, second: 56)

        #expect(DogfoodRun.makeRunID(date: date) == "dogfood-2026-06-28-123456")
    }

    @Test func storeSavesAndLoadsRunNotesAndChecklist() throws {
        let root = try Self.makeTempRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = AppSupportPaths(baseURL: root)
        var dates = [
            Self.date(year: 2026, month: 6, day: 28, hour: 12, minute: 0, second: 0),
            Self.date(year: 2026, month: 6, day: 28, hour: 12, minute: 1, second: 0)
        ]
        let noteID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let store = DogfoodStore(
            appSupportPaths: paths,
            dateProvider: { dates.removeFirst() },
            idProvider: { noteID }
        )

        let run = try store.startRun()
        #expect(run.id == "dogfood-2026-06-28-120000")
        #expect(store.currentRun?.checklist.count == DogfoodChecklistItem.defaultItems.count)

        let firstItem = try #require(store.currentRun?.checklist.first)
        try store.updateChecklistItem(id: firstItem.id, result: .pass)
        _ = try store.addNote(runID: run.id, text: "  Fixture passed.  ")

        let reloaded = DogfoodStore(appSupportPaths: paths)
        reloaded.loadRun(id: run.id)

        #expect(reloaded.currentRun?.id == run.id)
        #expect(reloaded.currentRun?.checklist.first?.result == .pass)
        #expect(reloaded.notes == [
            DogfoodNote(
                id: noteID,
                runID: run.id,
                createdAt: Self.date(year: 2026, month: 6, day: 28, hour: 12, minute: 1, second: 0),
                text: "Fixture passed."
            )
        ])
    }

    @Test func exportBundleKeepsPrivacyExclusionsExplicit() throws {
        let root = try Self.makeTempRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let paths = AppSupportPaths(baseURL: root)
        let store = DogfoodStore(
            appSupportPaths: paths,
            dateProvider: { Self.date(year: 2026, month: 6, day: 28, hour: 12, minute: 0, second: 0) }
        )
        _ = try store.startRun()

        let bundle = try store.exportBundle(
            diagnosticsData: Data("diagnostics".utf8),
            healthReport: nil,
            metadata: DogfoodBundleMetadata(
                generatedAt: Self.date(year: 2026, month: 6, day: 28, hour: 12, minute: 2, second: 0),
                appVersion: "1.0 (1)",
                marketingVersion: "1.0",
                buildNumber: "1",
                bundleIdentifier: "local.MenuBarDeclutter",
                macOSVersion: "macOS 26.0",
                architecture: "arm64",
                screens: [.init(index: 0, width: 1440, height: 900, isMain: true)]
            )
        )

        let files = try FileManager.default.contentsOfDirectory(at: bundle, includingPropertiesForKeys: nil)
        let fileNames = Set(files.map(\.lastPathComponent))
        #expect(fileNames.contains("diagnostics.txt"))
        #expect(fileNames.contains("manifest.json"))
        #expect(!fileNames.contains { $0.hasSuffix(".png") || $0.hasSuffix(".jpg") })

        let manifestText = try String(contentsOf: bundle.appendingPathComponent("manifest.json"), encoding: .utf8)
        #expect(manifestText.contains("screenshots"))
        #expect(manifestText.contains("screenContents"))
        #expect(manifestText.contains("telemetry"))
        #expect(manifestText.contains("networkData"))
    }

    private static func makeTempRoot() throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("DogfoodStoreTests.\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = DateComponents(
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
        return calendar.date(from: components)!
    }
}
