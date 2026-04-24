import Foundation

struct AppointmentItem: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let scheduledDate: Date?
    let scheduledTimeText: String?
    let locationText: String?
    let kind: String
    let isCritical: Bool
    let sourceLine: String?

    init(
        id: UUID = UUID(),
        title: String,
        scheduledDate: Date? = nil,
        scheduledTimeText: String? = nil,
        locationText: String? = nil,
        kind: String = "appointment",
        isCritical: Bool = false,
        sourceLine: String? = nil
    ) {
        self.id = id
        self.title = title
        self.scheduledDate = scheduledDate
        self.scheduledTimeText = scheduledTimeText
        self.locationText = locationText
        self.kind = kind
        self.isCritical = isCritical
        self.sourceLine = sourceLine
    }
}
