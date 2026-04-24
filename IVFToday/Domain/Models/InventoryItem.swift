import Foundation

struct InventoryItem: Identifiable, Hashable, Codable {
    let id: UUID
    let medicationName: String
    let unit: MedicationUnit
    var remainingAmount: Double
    let alertThreshold: Double
    var lastUpdatedAt: Date

    init(
        id: UUID = UUID(),
        medicationName: String,
        unit: MedicationUnit,
        remainingAmount: Double,
        alertThreshold: Double,
        lastUpdatedAt: Date = Date()
    ) {
        self.id = id
        self.medicationName = medicationName
        self.unit = unit
        self.remainingAmount = remainingAmount
        self.alertThreshold = alertThreshold
        self.lastUpdatedAt = lastUpdatedAt
    }

    var remainingLabel: String {
        if remainingAmount == floor(remainingAmount) {
            return "\(Int(remainingAmount)) \(unit.rawValue) left"
        }

        return "\(remainingAmount.formatted()) \(unit.rawValue) left"
    }
}
