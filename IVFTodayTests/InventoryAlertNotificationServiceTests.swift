import XCTest
@testable import IVFToday

final class InventoryAlertNotificationServiceTests: XCTestCase {
    func testSchedulesNotificationsWhenEnabledAndAuthorized() async {
        let scheduler = MockNotificationScheduler(isAuthorized: true)
        let service = InventoryAlertNotificationService(scheduler: scheduler)
        let alerts = [
            InventoryAlert(
                id: "gonal-f",
                medicationName: "Gonal-F",
                message: "Low stock after today",
                daysLeft: 1.2,
                isCritical: false
            )
        ]

        await service.syncLowStockNotifications(
            alerts: alerts,
            trackedMedicationNames: ["Gonal-F"],
            isEnabled: true
        )

        XCTAssertEqual(scheduler.authorizationRequestCount, 1)
        XCTAssertEqual(scheduler.scheduledRequests.count, 1)
        XCTAssertTrue(scheduler.scheduledRequests[0].id.contains("inventory.low"))
        XCTAssertEqual(scheduler.scheduledRequests[0].title, "Low Inventory: Gonal-F")
        XCTAssertEqual(scheduler.scheduledRequests[0].timeInterval, 1800, accuracy: 0.001)
    }

    func testDoesNotScheduleWhenAuthorizationDenied() async {
        let scheduler = MockNotificationScheduler(isAuthorized: false)
        let service = InventoryAlertNotificationService(scheduler: scheduler)
        let alerts = [
            InventoryAlert(
                id: "cetrotide",
                medicationName: "Cetrotide",
                message: "Low stock after today",
                daysLeft: 0.8,
                isCritical: true
            )
        ]

        await service.syncLowStockNotifications(
            alerts: alerts,
            trackedMedicationNames: ["Cetrotide"],
            isEnabled: true
        )

        XCTAssertEqual(scheduler.authorizationRequestCount, 1)
        XCTAssertTrue(scheduler.scheduledRequests.isEmpty)
    }

    func testRemovesPendingNotificationsWhenDisabled() async {
        let scheduler = MockNotificationScheduler(isAuthorized: true)
        let service = InventoryAlertNotificationService(scheduler: scheduler)
        let alerts = [
            InventoryAlert(
                id: "ovidrel",
                medicationName: "Ovidrel Trigger",
                message: "Current stock does not cover today's dose.",
                daysLeft: 0.4,
                isCritical: true
            )
        ]

        await service.syncLowStockNotifications(
            alerts: alerts,
            trackedMedicationNames: ["Ovidrel Trigger"],
            isEnabled: false
        )

        XCTAssertEqual(scheduler.authorizationRequestCount, 0)
        XCTAssertEqual(scheduler.removedIdentifiers.count, 1)
        XCTAssertTrue(scheduler.removedIdentifiers[0].contains("inventory.low"))
    }

    func testEnabledFlowClearsTrackedNotificationsBeforeScheduling() async {
        let scheduler = MockNotificationScheduler(isAuthorized: true)
        let service = InventoryAlertNotificationService(scheduler: scheduler)
        let alerts = [
            InventoryAlert(
                id: "gonal-f",
                medicationName: "Gonal-F",
                message: "Low stock after today",
                daysLeft: 1.0,
                isCritical: false
            )
        ]

        await service.syncLowStockNotifications(
            alerts: alerts,
            trackedMedicationNames: ["Gonal-F", "Cetrotide"],
            isEnabled: true
        )

        XCTAssertEqual(scheduler.authorizationRequestCount, 1)
        XCTAssertEqual(scheduler.removedIdentifiers.count, 2)
        XCTAssertEqual(scheduler.scheduledRequests.count, 1)
    }

    func testCriticalAlertsUseCriticalTitleAndFastDelay() async {
        let scheduler = MockNotificationScheduler(isAuthorized: true)
        let service = InventoryAlertNotificationService(scheduler: scheduler)
        let alerts = [
            InventoryAlert(
                id: "ovidrel",
                medicationName: "Ovidrel Trigger",
                message: "Current stock does not cover today's dose.",
                daysLeft: 0.1,
                isCritical: true
            )
        ]

        await service.syncLowStockNotifications(
            alerts: alerts,
            trackedMedicationNames: ["Ovidrel Trigger"],
            isEnabled: true
        )

        XCTAssertEqual(scheduler.scheduledRequests.count, 1)
        XCTAssertEqual(scheduler.scheduledRequests[0].title, "Critical Low Inventory: Ovidrel Trigger")
        XCTAssertEqual(scheduler.scheduledRequests[0].timeInterval, 60, accuracy: 0.001)
    }
}

private final class MockNotificationScheduler: LocalNotificationScheduling {
    private let isAuthorized: Bool

    private(set) var authorizationRequestCount = 0
    private(set) var scheduledRequests: [LocalNotificationRequest] = []
    private(set) var removedIdentifiers: [String] = []

    init(isAuthorized: Bool) {
        self.isAuthorized = isAuthorized
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        authorizationRequestCount += 1
        return isAuthorized
    }

    func schedule(_ request: LocalNotificationRequest) async throws {
        scheduledRequests.append(request)
    }

    func removePendingRequests(withIdentifiers identifiers: [String]) async {
        removedIdentifiers.append(contentsOf: identifiers)
    }
}
