import Foundation

struct ProtocolChangeSet: Identifiable, Hashable, Codable {
    let id: UUID
    let previousDocumentID: UUID?
    let currentDocumentID: UUID
    let createdAt: Date
    let items: [ChangeItem]

    init(
        id: UUID = UUID(),
        previousDocumentID: UUID?,
        currentDocumentID: UUID,
        createdAt: Date = Date(),
        items: [ChangeItem]
    ) {
        self.id = id
        self.previousDocumentID = previousDocumentID
        self.currentDocumentID = currentDocumentID
        self.createdAt = createdAt
        self.items = items
    }
}
