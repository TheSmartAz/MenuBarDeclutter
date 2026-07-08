import Foundation

/// Minimal, reusable JSON-file persistence for a single `Codable` value.
///
/// This owns only the mechanical core that every file-store in the app repeats:
/// an atomic write that first creates the parent directory, and an
/// existence-guarded read that decodes the file. Everything above that line —
/// corruption policy (backup / log / silent reset), container/schema-version
/// wrapping, post-load transforms (sort, dedup), and save side-effects — stays
/// with each store, because those genuinely differ across stores.
///
/// The `encoder`/`decoder` are injectable and default to the app-wide canonical
/// config (`JSONCoding`). When adopting this in an existing store, pass the
/// store's *current* encoder/decoder so the on-disk format (notably the date
/// strategy) is preserved and previously-written files still decode.
nonisolated struct CodableFileStore<Value: Codable> {
    let fileURL: URL
    let fileManager: FileManager
    let encoder: JSONEncoder
    let decoder: JSONDecoder

    init(
        fileURL: URL,
        fileManager: FileManager = .default,
        encoder: JSONEncoder = JSONCoding.makeEncoder(),
        decoder: JSONDecoder = JSONCoding.makeDecoder()
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        self.encoder = encoder
        self.decoder = decoder
    }

    /// Encodes `value` and writes it atomically, creating the parent directory
    /// if needed.
    func write(_ value: Value) throws {
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(value)
        try data.write(to: fileURL, options: .atomic)
    }

    /// Reads and decodes the backing file.
    ///
    /// Returns `nil` when the file does not exist (a first run, or after a
    /// reset). Throws on I/O or decode failure so the caller can apply its own
    /// corruption policy (back up + reset, log, or fail closed).
    func read() throws -> Value? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(Value.self, from: data)
    }

    /// Removes the backing file if it exists. No-op when already absent.
    func removeFile() throws {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        try fileManager.removeItem(at: fileURL)
    }
}
