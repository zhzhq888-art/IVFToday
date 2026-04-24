import Foundation
import UserNotifications

final class UserNotificationCenterScheduler: LocalNotificationScheduling {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func schedule(_ request: LocalNotificationRequest) async throws {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(60, request.timeInterval),
            repeats: false
        )
        let notificationRequest = UNNotificationRequest(
            identifier: request.id,
            content: content,
            trigger: trigger
        )
        try await center.add(notificationRequest)
    }

    func removePendingRequests(withIdentifiers identifiers: [String]) async {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
