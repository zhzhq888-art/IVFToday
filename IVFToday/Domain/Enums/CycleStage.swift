import Foundation

enum CycleStage: String, Codable, CaseIterable {
    case stimulation
    case monitoring
    case trigger
    case retrieval
    case transfer
    case beta
    case unknown
}