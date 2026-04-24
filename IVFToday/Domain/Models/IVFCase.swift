import Foundation

struct IVFCase: Identifiable, Codable {
    let id: UUID
    let title: String
    let stage: CycleStage
    let startDate: Date?
    let clinicName: String?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        stage: CycleStage,
        startDate: Date? = nil,
        clinicName: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.stage = stage
        self.startDate = startDate
        self.clinicName = clinicName
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
