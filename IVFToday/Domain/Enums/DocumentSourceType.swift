import Foundation

enum DocumentSourceType: String, Codable, CaseIterable {
    case screenshot
    case pdf
    case photo
    case manualEntry
}