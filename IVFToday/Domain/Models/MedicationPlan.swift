import Foundation

struct MedicationPlan: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var doseAmount: Double
    var unit: MedicationUnit
    var route: String
    var scheduledTime: String
    var instructions: String
    var isCritical: Bool
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        doseAmount: Double,
        unit: MedicationUnit,
        route: String,
        scheduledTime: String,
        instructions: String,
        isCritical: Bool = false,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.doseAmount = doseAmount
        self.unit = unit
        self.route = route
        self.scheduledTime = scheduledTime
        self.instructions = instructions
        self.isCritical = isCritical
        self.isActive = isActive
    }

    var summaryLine: String {
        "\(formattedDose) • \(route) • \(instructions)"
    }

    var formattedDose: String {
        if doseAmount == floor(doseAmount) {
            return "\(Int(doseAmount)) \(unit.rawValue)"
        }

        return "\(doseAmount.formatted()) \(unit.rawValue)"
    }
}
