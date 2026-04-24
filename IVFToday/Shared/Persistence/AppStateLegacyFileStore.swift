import Foundation

/// Legacy JSON snapshot store retained for migration into SwiftData-backed persistence.
final class AppStateFileStore: AppStatePersisting {
    static let shared = AppStateFileStore()

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let storageDirectoryURL: URL?

    init(
        fileManager: FileManager = .default,
        storageDirectoryURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.storageDirectoryURL = storageDirectoryURL
    }

    func load() throws -> PersistedAppState? {
        let url = try storageURL()
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        let data = try Data(contentsOf: url)
        return try decoder.decode(PersistedAppState.self, from: data)
    }

    func save(_ snapshot: PersistedAppState) throws {
        let url = try storageURL()
        let data = try encoder.encode(snapshot)
        try data.write(to: url, options: .atomic)
    }

    private func storageURL() throws -> URL {
        if let storageDirectoryURL {
            if !fileManager.fileExists(atPath: storageDirectoryURL.path) {
                try fileManager.createDirectory(at: storageDirectoryURL, withIntermediateDirectories: true)
            }
            return storageDirectoryURL.appendingPathComponent("app-state.json")
        }

        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directoryURL = appSupportURL.appendingPathComponent("IVFToday", isDirectory: true)
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        return directoryURL.appendingPathComponent("app-state.json")
    }
}
