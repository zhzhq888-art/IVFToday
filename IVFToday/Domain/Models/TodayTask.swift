import Foundation

struct TodayTask: Identifiable, Hashable {
    let id: UUID
    let sourceID: UUID
    let sourceType: TodayTaskSourceType
    let title: String
    let subtitle: String
    let scheduledTime: String
    let scheduledDate: Date?
    let urgency: TaskUrgency
    let riskLevel: TaskRiskLevel

    init(
        id: UUID,
        sourceID: UUID,
        sourceType: TodayTaskSourceType,
        title: String,
        subtitle: String,
        scheduledTime: String,
        scheduledDate: Date? = nil,
        urgency: TaskUrgency,
        riskLevel: TaskRiskLevel
    ) {
        self.id = id
        self.sourceID = sourceID
        self.sourceType = sourceType
        self.title = title
        self.subtitle = subtitle
        self.scheduledTime = scheduledTime
        self.scheduledDate = scheduledDate
        self.urgency = urgency
        self.riskLevel = riskLevel
    }
}
