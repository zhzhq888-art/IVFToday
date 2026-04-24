import Foundation

struct ProtocolHistoryEntry: Identifiable, Hashable, Codable {
    let id: UUID
    let document: ProtocolDocument
    let changeSet: ProtocolChangeSet?
    let recordedAt: Date

    init(
        id: UUID = UUID(),
        document: ProtocolDocument,
        changeSet: ProtocolChangeSet?,
        recordedAt: Date = Date()
    ) {
        self.id = id
        self.document = document
        self.changeSet = changeSet
        self.recordedAt = recordedAt
    }
}
