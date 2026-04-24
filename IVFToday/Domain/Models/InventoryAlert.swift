import Foundation

struct InventoryAlert: Identifiable, Hashable {
    let id: String
    let medicationName: String
    let message: String
    let daysLeft: Double?
    let isCritical: Bool

    init(
        id: String,
        medicationName: String,
        message: String,
        daysLeft: Double? = nil,
        isCritical: Bool
    ) {
        self.id = id
        self.medicationName = medicationName
        self.message = message
        self.daysLeft = daysLeft
        self.isCritical = isCritical
    }
}
