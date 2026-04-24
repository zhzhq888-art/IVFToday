import Foundation

struct CompletionLog: Identifiable, Hashable, Codable {
    let id: UUID
    let taskID: UUID
    let taskTitle: String
    let sourceType: TodayTaskSourceType
    let completedAt: Date
    let riskLevel: TaskRiskLevel
    let requiredDoubleConfirmation: Bool

    init(
        id: UUID = UUID(),
        taskID: UUID,
        taskTitle: String,
        sourceType: TodayTaskSourceType,
        completedAt: Date = Date(),
        riskLevel: TaskRiskLevel,
        requiredDoubleConfirmation: Bool
    ) {
        self.id = id
        self.taskID = taskID
        self.taskTitle = taskTitle
        self.sourceType = sourceType
        self.completedAt = completedAt
        self.riskLevel = riskLevel
        self.requiredDoubleConfirmation = requiredDoubleConfirmation
    }
}
