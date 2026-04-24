import XCTest
import SwiftData
@testable import IVFToday

final class AppStatePersistenceTests: XCTestCase {
    func testAppStateLoadsPreviouslyPersistedSnapshot() throws {
        let container = try makeInMemoryContainer()
        let store = makeSwiftDataStore(container: container)
        let seed = DemoDataFactory.createAppState()
        let appState = AppState(
            treatmentCase: seed.treatmentCase,
            currentDocument: seed.currentDocument,
            previousDocument: seed.previousDocument,
            medications: seed.medications,
            inventoryItems: seed.inventoryItems,
            persistenceStore: store
        )

        let baselineCount = appState.medications.count
        appState.addMedication()
        XCTAssertEqual(appState.medications.count, baselineCount + 1)

        // Re-create state with same store to verify load path.
        let reloaded = AppState(
            treatmentCase: seed.treatmentCase,
            currentDocument: seed.currentDocument,
            previousDocument: seed.previousDocument,
            medications: seed.medications,
            inventoryItems: seed.inventoryItems,
            persistenceStore: store
        )
        XCTAssertEqual(reloaded.medications.count, baselineCount + 1)
    }

    func testAppStateFallsBackWhenPersistedSnapshotIsInvalid() throws {
        let storageDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: storageDirectory) }

        let invalidFileURL = storageDirectory.appendingPathComponent("app-state.json")
        try "not-json".data(using: .utf8)?.write(to: invalidFileURL, options: .atomic)

        let legacyStore = AppStateFileStore(storageDirectoryURL: storageDirectory)
        let container = try makeInMemoryContainer()
        let store = AppStateSwiftDataStore(
            modelContext: ModelContext(container),
            legacyStore: legacyStore
        )
        let seed = DemoDataFactory.createAppState()
        let appState = AppState(
            treatmentCase: seed.treatmentCase,
            currentDocument: seed.currentDocument,
            previousDocument: seed.previousDocument,
            medications: seed.medications,
            inventoryItems: seed.inventoryItems,
            persistenceStore: store
        )

        XCTAssertEqual(appState.treatmentCase.id, seed.treatmentCase.id)
        XCTAssertEqual(appState.medications, seed.medications)
        XCTAssertEqual(appState.inventoryItems, seed.inventoryItems)
    }

    func testUpdateInventoryItemClampsValuesUpdatesTimestampAndPersists() throws {
        let container = try makeInMemoryContainer()
        let store = makeSwiftDataStore(container: container)
        let seed = DemoDataFactory.createAppState()
        let appState = AppState(
            treatmentCase: seed.treatmentCase,
            currentDocument: seed.currentDocument,
            previousDocument: seed.previousDocument,
            medications: seed.medications,
            inventoryItems: seed.inventoryItems,
            persistenceStore: store
        )

        guard let targetItem = appState.inventoryItems.first else {
            XCTFail("Expected demo inventory item")
            return
        }

        let expectedUpdatedAt = Date(timeIntervalSince1970: 1_700_000_000)
        appState.updateInventoryItem(
            id: targetItem.id,
            remainingAmount: -42,
            alertThreshold: -7,
            updatedAt: expectedUpdatedAt
        )

        guard let updated = appState.inventoryItems.first(where: { $0.id == targetItem.id }) else {
            XCTFail("Updated inventory item was not found")
            return
        }
        XCTAssertEqual(updated.remainingAmount, 0)
        XCTAssertEqual(updated.alertThreshold, 0)
        XCTAssertEqual(updated.lastUpdatedAt, expectedUpdatedAt)

        let reloaded = AppState(
            treatmentCase: seed.treatmentCase,
            currentDocument: seed.currentDocument,
            previousDocument: seed.previousDocument,
            medications: seed.medications,
            inventoryItems: seed.inventoryItems,
            persistenceStore: store
        )
        let reloadedItem = reloaded.inventoryItems.first { $0.id == targetItem.id }
        XCTAssertEqual(reloadedItem?.remainingAmount, 0)
        XCTAssertEqual(reloadedItem?.alertThreshold, 0)
        XCTAssertEqual(reloadedItem?.lastUpdatedAt, expectedUpdatedAt)
    }

    func testAppointmentsPersistAcrossReload() throws {
        let container = try makeInMemoryContainer()
        let store = makeSwiftDataStore(container: container)
        let seed = DemoDataFactory.createAppState()
        let appState = AppState(
            treatmentCase: seed.treatmentCase,
            currentDocument: seed.currentDocument,
            previousDocument: seed.previousDocument,
            medications: seed.medications,
            inventoryItems: seed.inventoryItems,
            persistenceStore: store
        )

        let appointments = [
            AppointmentItem(title: "Ultrasound monitoring", scheduledTimeText: "7:30 AM", locationText: "Main Clinic", kind: "monitoring"),
            AppointmentItem(title: "Egg retrieval", scheduledTimeText: "06:45 AM", locationText: "OR Suite 2", kind: "retrieval", isCritical: true)
        ]

        appState.applyImportedProtocol(
            sourceType: .pdf,
            sourceFilename: "Imported.pdf",
            rawText: "raw",
            normalizedText: "normalized",
            medications: seed.medications,
            appointments: appointments
        )

        let reloaded = AppState(
            treatmentCase: seed.treatmentCase,
            currentDocument: seed.currentDocument,
            previousDocument: seed.previousDocument,
            medications: seed.medications,
            inventoryItems: seed.inventoryItems,
            persistenceStore: store
        )

        XCTAssertEqual(reloaded.appointments.count, 2)
        XCTAssertEqual(reloaded.appointments.first?.title, "Ultrasound monitoring")
        XCTAssertTrue(reloaded.appointments.contains(where: { $0.kind == "retrieval" && $0.isCritical }))
    }

    func testCompletionLogsPersistAcrossReload() throws {
        let container = try makeInMemoryContainer()
        let store = makeSwiftDataStore(container: container)
        let seed = DemoDataFactory.createAppState()
        let appState = AppState(
            treatmentCase: seed.treatmentCase,
            currentDocument: seed.currentDocument,
            previousDocument: seed.previousDocument,
            medications: seed.medications,
            inventoryItems: seed.inventoryItems,
            appointments: seed.appointments,
            persistenceStore: store
        )

        guard let task = appState.todayTasks.first else {
            XCTFail("Expected at least one today task")
            return
        }
        appState.completeTask(task, confirmedByUser: task.riskLevel == .high)

        let reloaded = AppState(
            treatmentCase: seed.treatmentCase,
            currentDocument: seed.currentDocument,
            previousDocument: seed.previousDocument,
            medications: seed.medications,
            inventoryItems: seed.inventoryItems,
            appointments: seed.appointments,
            persistenceStore: store
        )

        XCTAssertTrue(reloaded.completedTaskIDs.contains(task.id))
        XCTAssertEqual(reloaded.completionLogs.count, 1)
        XCTAssertEqual(reloaded.completionLogs.first?.taskID, task.id)
    }

    func testInventoryNotificationPreferencePersistsAcrossReload() throws {
        let container = try makeInMemoryContainer()
        let store = makeSwiftDataStore(container: container)
        let seed = DemoDataFactory.createAppState()
        let appState = AppState(
            treatmentCase: seed.treatmentCase,
            currentDocument: seed.currentDocument,
            previousDocument: seed.previousDocument,
            medications: seed.medications,
            inventoryItems: seed.inventoryItems,
            appointments: seed.appointments,
            persistenceStore: store
        )

        appState.inventoryNotificationsEnabled = true

        let reloaded = AppState(
            treatmentCase: seed.treatmentCase,
            currentDocument: seed.currentDocument,
            previousDocument: seed.previousDocument,
            medications: seed.medications,
            inventoryItems: seed.inventoryItems,
            appointments: seed.appointments,
            persistenceStore: store
        )

        XCTAssertTrue(reloaded.inventoryNotificationsEnabled)
    }

    func testProtocolHistoryPersistsAcrossReload() throws {
        let container = try makeInMemoryContainer()
        let store = makeSwiftDataStore(container: container)
        let seed = DemoDataFactory.createAppState(persistenceStore: store)

        XCTAssertGreaterThanOrEqual(seed.protocolHistory.count, 2)

        let importedAppointments = [
            AppointmentItem(
                title: "Embryo Transfer",
                scheduledTimeText: "11:00 AM",
                locationText: "Transfer Suite",
                kind: "transfer",
                isCritical: true
            )
        ]

        seed.applyImportedProtocol(
            sourceType: .pdf,
            sourceFilename: "UpdatedProtocol.pdf",
            rawText: "raw",
            normalizedText: "normalized",
            medications: seed.medications,
            appointments: importedAppointments
        )

        let reloaded = AppState(
            treatmentCase: seed.treatmentCase,
            currentDocument: seed.currentDocument,
            previousDocument: seed.previousDocument,
            medications: seed.medications,
            inventoryItems: seed.inventoryItems,
            appointments: seed.appointments,
            persistenceStore: store
        )

        XCTAssertGreaterThanOrEqual(reloaded.protocolHistory.count, 3)
        XCTAssertEqual(reloaded.protocolHistory.last?.document.sourceFilename, "UpdatedProtocol.pdf")
        XCTAssertTrue(reloaded.protocolHistory.last?.changeSet?.items.contains(where: {
            $0.subjectType == .appointment && $0.subjectName == "Embryo Transfer" && $0.type == .added
        }) == true)
    }

    func testResetToDemoDataRestoresBaselineAndPersists() throws {
        let container = try makeInMemoryContainer()
        let store = makeSwiftDataStore(container: container)
        let seed = DemoDataFactory.createAppState()
        let appState = AppState(
            treatmentCase: seed.treatmentCase,
            currentDocument: seed.currentDocument,
            previousDocument: seed.previousDocument,
            medications: seed.medications,
            inventoryItems: seed.inventoryItems,
            appointments: seed.appointments,
            persistenceStore: store
        )

        appState.addMedication()
        if let task = appState.todayTasks.first {
            appState.completeTask(task, confirmedByUser: task.riskLevel == .high)
        }
        appState.inventoryNotificationsEnabled = true

        appState.resetToDemoData()

        XCTAssertEqual(appState.treatmentCase.title, DemoDataFactory.createDemoIVFCase().title)
        XCTAssertEqual(appState.medications.count, DemoDataFactory.createCurrentMedicationPlans().count)
        XCTAssertTrue(appState.completedTaskIDs.isEmpty)
        XCTAssertTrue(appState.completionLogs.isEmpty)
        XCTAssertFalse(appState.inventoryNotificationsEnabled)
        XCTAssertGreaterThanOrEqual(appState.protocolHistory.count, 1)

        let reloaded = AppState(
            treatmentCase: seed.treatmentCase,
            currentDocument: seed.currentDocument,
            previousDocument: seed.previousDocument,
            medications: seed.medications,
            inventoryItems: seed.inventoryItems,
            appointments: seed.appointments,
            persistenceStore: store
        )

        XCTAssertEqual(reloaded.treatmentCase.title, DemoDataFactory.createDemoIVFCase().title)
        XCTAssertEqual(reloaded.medications.count, DemoDataFactory.createCurrentMedicationPlans().count)
        XCTAssertTrue(reloaded.completedTaskIDs.isEmpty)
        XCTAssertTrue(reloaded.completionLogs.isEmpty)
        XCTAssertFalse(reloaded.inventoryNotificationsEnabled)
        XCTAssertGreaterThanOrEqual(reloaded.protocolHistory.count, 1)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([PersistedAppStateRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeSwiftDataStore(container: ModelContainer) -> AppStateSwiftDataStore {
        AppStateSwiftDataStore(
            modelContext: ModelContext(container),
            legacyStore: nil
        )
    }
}
