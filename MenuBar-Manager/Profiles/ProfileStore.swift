import Foundation
import Observation

@MainActor
@Observable
final class ProfileStore {
    private let appSupportPaths: AppSupportPaths
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let now: () -> Date

    private(set) var profiles: [ProfileModel] = []
    private(set) var lastError: String?

    init(
        appSupportPaths: AppSupportPaths,
        fileManager: FileManager = .default,
        now: @escaping () -> Date = { Date() }
    ) {
        self.appSupportPaths = appSupportPaths
        self.fileManager = fileManager
        self.now = now

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func load() {
        do {
            try appSupportPaths.ensureDirectoriesExist()
            let urls = try fileManager.contentsOfDirectory(
                at: appSupportPaths.profilesDirectory,
                includingPropertiesForKeys: nil
            )
            var loadedProfiles: [ProfileModel] = []
            var skippedFiles: [String] = []

            for url in profileURLs(from: urls) {
                do {
                    let data = try Data(contentsOf: url)
                    loadedProfiles.append(try decoder.decode(ProfileModel.self, from: data))
                } catch {
                    skippedFiles.append("\(url.lastPathComponent): \(error.localizedDescription)")
                }
            }

            profiles = loadedProfiles.sorted { $0.updatedAt > $1.updatedAt }
            lastError = skippedFiles.isEmpty
                ? nil
                : "Skipped \(skippedFiles.count) profile file(s): \(skippedFiles.joined(separator: "; "))"
        } catch {
            lastError = error.localizedDescription
        }
    }

    @discardableResult
    func createProfile(name: String = "New Profile") -> ProfileModel {
        var profile = ProfileModel.makeDefault(name: name, now: now())
        profile.name = uniqueName(profile.name)
        profiles.insert(profile, at: 0)
        save(profile)
        return profile
    }

    @discardableResult
    func duplicate(_ profile: ProfileModel) -> ProfileModel {
        var copy = profile
        copy.id = UUID()
        copy.name = uniqueName("\(profile.name) Copy")
        copy.createdAt = now()
        copy.updatedAt = copy.createdAt
        profiles.insert(copy, at: 0)
        save(copy)
        return copy
    }

    func update(_ profile: ProfileModel) {
        var updated = profile
        updated.updatedAt = now()
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = updated
        } else {
            profiles.insert(updated, at: 0)
        }
        profiles.sort { $0.updatedAt > $1.updatedAt }
        save(updated)
    }

    func delete(_ profile: ProfileModel) {
        profiles.removeAll { $0.id == profile.id }
        do {
            let url = url(for: profile.id)
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func profile(named name: String) -> ProfileModel? {
        profiles.first {
            $0.name.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    func exportProfile(_ profile: ProfileModel, to url: URL) throws {
        let data = try encoder.encode(profile)
        try data.write(to: url, options: .atomic)
    }

    @discardableResult
    func importProfile(from url: URL) throws -> ProfileModel {
        let data = try Data(contentsOf: url)
        var imported = try decoder.decode(ProfileModel.self, from: data)
        if profiles.contains(where: { $0.id == imported.id }) {
            imported.id = UUID()
            imported.name = uniqueName(imported.name)
        }
        imported.updatedAt = now()
        profiles.insert(imported, at: 0)
        save(imported)
        return imported
    }

    func encodedData(for profile: ProfileModel) throws -> Data {
        try encoder.encode(profile)
    }

    func decodeProfile(from data: Data) throws -> ProfileModel {
        try decoder.decode(ProfileModel.self, from: data)
    }

    func importProfiles(_ importedProfiles: [ProfileModel]) {
        guard !importedProfiles.isEmpty else { return }
        for profile in importedProfiles {
            if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
                profiles[index] = profile
            } else {
                profiles.append(profile)
            }
            save(profile)
        }
        profiles.sort { $0.updatedAt > $1.updatedAt }
    }

    func replaceAll(_ replacementProfiles: [ProfileModel]) {
        do {
            try appSupportPaths.ensureDirectoriesExist()
            let urls = try fileManager.contentsOfDirectory(
                at: appSupportPaths.profilesDirectory,
                includingPropertiesForKeys: nil
            )
            for url in profileURLs(from: urls) {
                try fileManager.removeItem(at: url)
            }
            profiles = replacementProfiles.sorted { $0.updatedAt > $1.updatedAt }
            for profile in profiles {
                let data = try encoder.encode(profile)
                try data.write(to: url(for: profile.id), options: .atomic)
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func save(_ profile: ProfileModel) {
        do {
            try appSupportPaths.ensureDirectoriesExist()
            let data = try encoder.encode(profile)
            try data.write(to: url(for: profile.id), options: .atomic)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func url(for id: UUID) -> URL {
        appSupportPaths.profilesDirectory.appendingPathComponent("\(id.uuidString).json")
    }

    private func profileURLs(from urls: [URL]) -> [URL] {
        urls.filter {
            $0.pathExtension == "json" && $0.lastPathComponent != TriggerService.storageFilename
        }
    }

    private func uniqueName(_ base: String) -> String {
        let existing = Set(profiles.map(\.name))
        guard existing.contains(base) else { return base }

        var counter = 2
        while existing.contains("\(base) \(counter)") {
            counter += 1
        }
        return "\(base) \(counter)"
    }
}
