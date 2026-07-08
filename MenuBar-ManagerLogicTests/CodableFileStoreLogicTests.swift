import Foundation
import Testing
@testable import MenuBarDeclutter

@Suite("Codable File Store")
struct CodableFileStoreLogicTests {
    private struct Model: Codable, Equatable {
        var name: String
        var count: Int
        var stamp: Date
    }

    private func tempFileURL(_ name: String = "value.json") -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("CodableFileStoreTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("nested", isDirectory: true)
            .appendingPathComponent(name)
    }

    private func makeModel() -> Model {
        Model(name: "hello", count: 7, stamp: Date(timeIntervalSince1970: 1_700_000_000))
    }

    @Test func readReturnsNilWhenFileAbsent() throws {
        let store = CodableFileStore<Model>(fileURL: tempFileURL())
        #expect(try store.read() == nil)
    }

    @Test func writeThenReadRoundTripsAndCreatesParentDirectory() throws {
        let url = tempFileURL()
        // Parent directory does not exist yet; write must create it.
        #expect(FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path) == false)

        let store = CodableFileStore<Model>(fileURL: url)
        let model = makeModel()
        try store.write(model)

        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(try store.read() == model)
    }

    @Test func writeOverwritesExistingValue() throws {
        let store = CodableFileStore<Model>(fileURL: tempFileURL())
        try store.write(makeModel())
        var updated = makeModel()
        updated.count = 99
        try store.write(updated)
        #expect(try store.read()?.count == 99)
    }

    @Test func readThrowsOnCorruptData() throws {
        let url = tempFileURL()
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("{ not valid json".utf8).write(to: url)

        let store = CodableFileStore<Model>(fileURL: url)
        #expect(throws: (any Error).self) {
            _ = try store.read()
        }
    }

    @Test func removeFileDeletesAndIsNoOpWhenAbsent() throws {
        let url = tempFileURL()
        let store = CodableFileStore<Model>(fileURL: url)

        // No-op when absent (must not throw).
        try store.removeFile()

        try store.write(makeModel())
        #expect(FileManager.default.fileExists(atPath: url.path))

        try store.removeFile()
        #expect(FileManager.default.fileExists(atPath: url.path) == false)
        #expect(try store.read() == nil)
    }

    @Test func honorsInjectedEncoderDecoderConfig() throws {
        let url = tempFileURL()
        // Non-default date strategy must survive the round trip when both the
        // encoder and decoder agree on it — this is the contract each store
        // relies on to preserve its on-disk format.
        let store = CodableFileStore<Model>(
            fileURL: url,
            encoder: JSONCoding.makeEncoder(dateEncodingStrategy: .secondsSince1970),
            decoder: JSONCoding.makeDecoder(dateDecodingStrategy: .secondsSince1970)
        )
        let model = makeModel()
        try store.write(model)
        #expect(try store.read() == model)

        // A decoder configured for a *different* date strategy fails to
        // round-trip, proving the injected config is actually used.
        let mismatched = CodableFileStore<Model>(
            fileURL: url,
            decoder: JSONCoding.makeDecoder(dateDecodingStrategy: .iso8601)
        )
        #expect(throws: (any Error).self) {
            _ = try mismatched.read()
        }
    }
}
