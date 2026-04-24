import Foundation

struct LocalNotificationRequest: Hashable {
    let id: String
    let title: String
    let body: String
    let timeInterval: TimeInterval
}

protocol LocalNotificationScheduling {
    func requestAuthorizationIfNeeded() async -> Bool
    func schedule(_ request: LocalNotificationRequest) async throws
    func removePendingRequests(withIdentifiers identifiers: [String]) async
}
