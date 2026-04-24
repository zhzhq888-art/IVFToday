import Foundation

enum MedicationUnit: String, Codable, CaseIterable {
    case iu = "IU"
    case mg = "mg"
    case mcg = "mcg"
    case ml = "mL"
    case vial = "vial"
}
