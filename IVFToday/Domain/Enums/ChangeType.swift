import Foundation

enum ChangeType: String, Codable, CaseIterable {
    case added
    case doseChanged
    case timeChanged
    case detailsChanged
    case stopped
}
