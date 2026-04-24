import Foundation

struct InventoryAlertNotificationService {
    private let scheduler: LocalNotificationScheduling

    init(scheduler: LocalNotificationScheduling = UserNotificationCenterScheduler()) {
        self.scheduler = scheduler
    }

    func syncLowStockNotifications(
        alerts: [InventoryAlert],
        trackedMedicationNames: [String],
        isEnabled: Bool
    ) async {
        let trackedIDs = trackedMedicationNames.map(Self.notificationID(forMedicationName:))

        guard isEnabled else {
            await scheduler.removePendingRequests(withIdentifiers: trackedIDs)
            return
        }

        // Always clear tracked requests first to avoid stale low-stock notifications.
        await scheduler.removePendingRequests(withIdentifiers: trackedIDs)
        guard !alerts.isEmpty else { return }

        let granted = await scheduler.requestAuthorizationIfNeeded()
        guard granted else {
            return
        }

        for alert in alerts {
            let body: String
            if let daysLeft = alert.daysLeft {
                body = "\(alert.message) Estimated days left: \(formatDaysLeft(daysLeft))."
            } else {
                body = alert.message
            }
            let request = LocalNotificationRequest(
                id: Self.notificationID(for: alert),
                title: title(for: alert),
                body: body,
                timeInterval: scheduleDelay(for: alert)
            )
            do {
                try await scheduler.schedule(request)
            } catch {
                continue
            }
        }
    }

    static func notificationID(for alert: InventoryAlert) -> String {
        notificationID(forMedicationName: alert.medicationName)
    }

    static func notificationID(forMedicationName medicationName: String) -> String {
        let slug = medicationName
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return "inventory.low.\(slug)"
    }

    private func formatDaysLeft(_ days: Double) -> String {
        if days < 1 {
            return "< 1 day"
        }
        return String(format: "%.1f days", days)
    }

    private func title(for alert: InventoryAlert) -> String {
        if alert.isCritical {
            return "Critical Low Inventory: \(alert.medicationName)"
        }
        return "Low Inventory: \(alert.medicationName)"
    }

    private func scheduleDelay(for alert: InventoryAlert) -> TimeInterval {
        if alert.isCritical {
            return 60
        }

        guard let daysLeft = alert.daysLeft else {
            return 3600
        }

        if daysLeft <= 1 {
            return 900
        }
        if daysLeft <= 2 {
            return 1800
        }
        return 3600
    }
}
