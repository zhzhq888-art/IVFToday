import Foundation
import SwiftData

@Model
final class PersistedAppStateRecord {
    @Attribute(.unique) var key: String
    var payload: Data
    var updatedAt: Date

    init(key: String = "main", payload: Data, updatedAt: Date = Date()) {
        self.key = key
        self.payload = payload
        self.updatedAt = updatedAt
    }
}

final class AppStateSwiftDataStore: AppStatePersisting {
    private let modelContext: ModelContext
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let legacyStore: AppStatePersisting?

    init(
        modelContext: ModelContext,
        legacyStore: AppStatePersisting? = AppStateFileStore.shared
    ) {
        self.modelContext = modelContext
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.legacyStore = legacyStore
    }

    func load() throws -> PersistedAppState? {
        if let record = try fetchRecord() {
            return try decoder.decode(PersistedAppState.self, from: record.payload)
        }

        guard let legacyState = try legacyStore?.load() else {
            return nil
        }
        try save(legacyState)
        return legacyState
    }

    func save(_ snapshot: PersistedAppState) throws {
        let payload = try encoder.encode(snapshot)
        if let record = try fetchRecord() {
            record.payload = payload
            record.updatedAt = Date()
        } else {
            let record = PersistedAppStateRecord(payload: payload)
            modelContext.insert(record)
        }
        try modelContext.save()
    }

    private func fetchRecord() throws -> PersistedAppStateRecord? {
        var descriptor = FetchDescriptor<PersistedAppStateRecord>(
            predicate: #Predicate { $0.key == "main" }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
