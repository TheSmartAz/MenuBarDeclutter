import Foundation

/// Centralizes Application Support paths used by MenuBarDeclutter and ensures
/// the relevant directories exist on demand without writing any files in
/// Phase 0/1/2 setup paths.
///
/// Directories created lazily:
/// - `Application Support/MenuBarDeclutter/`
/// - `Application Support/MenuBarDeclutter/diagnostics/`
/// - `Application Support/MenuBarDeclutter/profiles/`
/// - `Application Support/MenuBarDeclutter/backups/`
/// - `Application Support/MenuBarDeclutter/Dogfood/`
/// - `Application Support/MenuBarDeclutter/Dogfood/runs/`
/// - `Application Support/MenuBarDeclutter/Dogfood/exports/`
///
/// No personal file paths, network data, or screen contents are written here.
struct AppSupportPaths {
    private let fileManager: FileManager
    /// Optional override for the Application Support base directory. In
    /// production this stays `nil` and the system Application Support directory
    /// is used. Tests inject a temporary URL so they do not touch the real
    /// user domain.
    private let baseURL: URL?

    init(fileManager: FileManager = .default, baseURL: URL? = nil) {
        self.fileManager = fileManager
        self.baseURL = baseURL
    }

    var applicationSupportDirectory: URL {
        let root = baseURL ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        return root.appendingPathComponent(AppConstants.displayName, isDirectory: true)
    }

    var diagnosticsDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("diagnostics", isDirectory: true)
    }

    /// Reserved for a future Profiles phase. Created on demand but not yet
    /// read or written by Phase 3 features.
    var profilesDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("profiles", isDirectory: true)
    }

    /// Reserved for a future Backups phase. Created on demand but not yet
    /// read or written by Phase 3 features.
    var backupsDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("backups", isDirectory: true)
    }

    /// Local-only Phase 9.2 dogfood notes, run state, and export bundles.
    var dogfoodDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("Dogfood", isDirectory: true)
    }

    var dogfoodRunsDirectory: URL {
        dogfoodDirectory.appendingPathComponent("runs", isDirectory: true)
    }

    var dogfoodExportsDirectory: URL {
        dogfoodDirectory.appendingPathComponent("exports", isDirectory: true)
    }

    /// Local-only hashed recents/favorites state for Find Icon and Second Bar.
    var menuBarItemMemoryFileURL: URL {
        applicationSupportDirectory.appendingPathComponent("menu-bar-item-memory.json")
    }

    // MARK: Directory creation

    /// Creates `applicationSupportDirectory` and all known subdirectories if
    /// they do not already exist. Returns the list of directories actually
    /// created (those that did not exist before this call).
    @discardableResult
    func ensureDirectoriesExist() throws -> [URL] {
        let directories = [
            applicationSupportDirectory,
            diagnosticsDirectory,
            profilesDirectory,
            backupsDirectory,
            dogfoodDirectory,
            dogfoodRunsDirectory,
            dogfoodExportsDirectory
        ]

        var created: [URL] = []
        for url in directories {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
                continue
            }
            try fileManager.createDirectory(
                at: url,
                withIntermediateDirectories: true
            )
            created.append(url)
        }
        return created
    }

    /// Builds a diagnostics export URL inside `diagnosticsDirectory`.
    /// Does not create the file; the caller is responsible for writing it.
    func diagnosticsExportURL(filename: String) -> URL {
        diagnosticsDirectory.appendingPathComponent(filename)
    }
}
