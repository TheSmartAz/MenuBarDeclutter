import Foundation
import Observation

@MainActor
@Observable
final class DogfoodStore {
    @ObservationIgnored private let appSupportPaths: AppSupportPaths
    @ObservationIgnored private let fileManager: FileManager
    @ObservationIgnored private let dateProvider: () -> Date
    @ObservationIgnored private let idProvider: () -> UUID

    var currentRun: DogfoodRun?
    var notes: [DogfoodNote] = []
    var lastError: String?

    init(
        appSupportPaths: AppSupportPaths,
        fileManager: FileManager = .default,
        dateProvider: @escaping () -> Date = { Date() },
        idProvider: @escaping () -> UUID = { UUID() }
    ) {
        self.appSupportPaths = appSupportPaths
        self.fileManager = fileManager
        self.dateProvider = dateProvider
        self.idProvider = idProvider
    }

    @discardableResult
    func startRun() throws -> DogfoodRun {
        let run = DogfoodRun(startedAt: dateProvider())
        currentRun = run
        notes = []
        try save(run: run)
        try save(notes: notes, runID: run.id)
        lastError = nil
        return run
    }

    @discardableResult
    func endCurrentRun() throws -> DogfoodRun? {
        guard var run = currentRun else { return nil }
        run.endedAt = dateProvider()
        currentRun = run
        try save(run: run)
        lastError = nil
        return run
    }

    func loadRun(id: String?) {
        guard let id, !id.isEmpty else {
            currentRun = nil
            notes = []
            return
        }

        do {
            currentRun = try readRun(id: id)
            notes = try readNotes(runID: id)
            lastError = nil
        } catch {
            currentRun = nil
            notes = []
            lastError = error.localizedDescription
        }
    }

    @discardableResult
    func addNote(runID: String, text: String) throws -> DogfoodNote? {
        let sanitized = Self.sanitizedNote(text)
        guard !sanitized.isEmpty else { return nil }

        let note = DogfoodNote(
            id: idProvider(),
            runID: runID,
            createdAt: dateProvider(),
            text: sanitized
        )
        notes.append(note)
        try save(notes: notes, runID: runID)
        lastError = nil
        return note
    }

    func updateChecklistItem(
        id itemID: DogfoodChecklistItem.ID,
        result: DogfoodChecklistResult,
        notes itemNotes: String? = nil
    ) throws {
        guard var run = currentRun,
              let index = run.checklist.firstIndex(where: { $0.id == itemID }) else {
            throw DogfoodStoreError.runUnavailable
        }

        run.checklist[index].result = result
        if let itemNotes {
            run.checklist[index].notes = itemNotes
        }
        currentRun = run
        try save(run: run)
        lastError = nil
    }

    func checklistItems(for gate: DogfoodGate) -> [DogfoodChecklistItem] {
        (currentRun?.checklist ?? DogfoodChecklistItem.defaultItems).filter { $0.gate == gate }
    }

    func exportBundle(
        diagnosticsData: Data,
        healthReport: HealthReport?,
        metadata: DogfoodBundleMetadata
    ) throws -> URL {
        try ensureDogfoodDirectoriesExist()
        let runID = currentRun?.id ?? "no-active-run"
        let bundleName = "\(runID)-\(DogfoodRun.timestamp(date: metadata.generatedAt))"
        let bundleURL = appSupportPaths.dogfoodExportsDirectory.appendingPathComponent(
            bundleName,
            isDirectory: true
        )

        if fileManager.fileExists(atPath: bundleURL.path) {
            try fileManager.removeItem(at: bundleURL)
        }
        try fileManager.createDirectory(at: bundleURL, withIntermediateDirectories: true)

        try diagnosticsData.write(
            to: bundleURL.appendingPathComponent("diagnostics.txt"),
            options: .atomic
        )

        if let healthReport {
            try Data(healthReport.plainText().utf8).write(
                to: bundleURL.appendingPathComponent("health-report.txt"),
                options: .atomic
            )
        }

        if let currentRun {
            try encode(currentRun, to: bundleURL.appendingPathComponent("run.json"))
        }
        try encode(notes, to: bundleURL.appendingPathComponent("notes.json"))
        try encode(metadata, to: bundleURL.appendingPathComponent("metadata.json"))
        try encode(DogfoodExportManifest(), to: bundleURL.appendingPathComponent("manifest.json"))

        lastError = nil
        return bundleURL
    }

    private func save(run: DogfoodRun) throws {
        try ensureDogfoodDirectoriesExist()
        try fileManager.createDirectory(at: runDirectory(runID: run.id), withIntermediateDirectories: true)
        try encode(run, to: runURL(runID: run.id))
    }

    private func save(notes: [DogfoodNote], runID: String) throws {
        try ensureDogfoodDirectoriesExist()
        try fileManager.createDirectory(at: runDirectory(runID: runID), withIntermediateDirectories: true)
        try encode(notes, to: notesURL(runID: runID))
    }

    private func readRun(id: String) throws -> DogfoodRun {
        try decode(DogfoodRun.self, from: runURL(runID: id))
    }

    private func readNotes(runID: String) throws -> [DogfoodNote] {
        let url = notesURL(runID: runID)
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        return try decode([DogfoodNote].self, from: url)
    }

    private func ensureDogfoodDirectoriesExist() throws {
        try appSupportPaths.ensureDirectoriesExist()
    }

    private func runDirectory(runID: String) -> URL {
        appSupportPaths.dogfoodRunsDirectory.appendingPathComponent(runID, isDirectory: true)
    }

    private func runURL(runID: String) -> URL {
        runDirectory(runID: runID).appendingPathComponent("run.json")
    }

    private func notesURL(runID: String) -> URL {
        runDirectory(runID: runID).appendingPathComponent("notes.json")
    }

    private func encode<Value: Encodable>(_ value: Value, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(value)
        try data.write(to: url, options: .atomic)
    }

    private func decode<Value: Decodable>(_ type: Value.Type, from url: URL) throws -> Value {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }

    private static func sanitizedNote(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum DogfoodStoreError: Error {
    case runUnavailable
}

private struct DogfoodExportManifest: Encodable, Equatable, Sendable {
    let description = "MenuBarDeclutter local dogfood bundle"
    let localOnly = true
    let excludedByDesign = [
        "screenshots",
        "screenContents",
        "liveSearchText",
        "selectedItemIdentity",
        "telemetry",
        "networkData"
    ]
}
