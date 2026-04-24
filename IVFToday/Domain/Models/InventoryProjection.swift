import Foundation

struct InventoryProjection: Identifiable, Hashable {
    let id: UUID
    let medicationName: String
    let unit: MedicationUnit
    let remainingAmount: Double
    let alertThresholdAmount: Double
    let dailyDoseAmount: Double
    let remainingAfterToday: Double
    let daysLeft: Double?
    let isLowStock: Bool
    let isCritical: Bool
}
