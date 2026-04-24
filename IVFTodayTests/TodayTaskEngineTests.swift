import XCTest
import SwiftData
@testable import IVFToday

final class TodayTaskEngineTests: XCTestCase {
    func testTodayTasksIncludeActiveMedicationsAndAppointments() throws {
        let store = try makeSwiftDataStore()

        let treatmentCase = DemoDataFactory.createDemoIVFCase()
        let medications = [
            MedicationPlan(
                name: "Gonal-F",
                doseAmount: 150,
                unit: .iu,
                route: "Subcutaneous",
                scheduledTime: "8:00 PM",
                instructions: "Evening dose",
                isActive: true
            ),
            MedicationPlan(
                name: "Cetrotide",
                doseAmount: 0.25,
                unit: .mg,
                route: "Subcutaneous",
                scheduledTime: "7:00 AM",
                instructions: "Hold today",
                isActive: false
            )
        ]
        let appointments = [
            AppointmentItem(title: "Ultrasound", scheduledTimeText: "7:30 AM", kind: "monitoring")
        ]

        let appState = AppState(
            treatmentCase: treatmentCase,
            currentDocument: DemoDataFactory.createCurrentProtocolDocument(for: treatmentCase.id, medications: medications),
            previousDocument: DemoDataFactory.createPreviousProtocolDocument(for: treatmentCase.id),
            medications: medications,
            inventoryItems: [],
            appointments: appointments,
            persistenceStore: store
        )

        XCTAssertEqual(appState.todayTasks.count, 2)
        XCTAssertTrue(appState.todayTasks.contains(where: { $0.sourceType == .medication && $0.title == "Gonal-F" }))
        XCTAssertTrue(appState.todayTasks.contains(where: { $0.sourceType == .appointment && $0.title == "Ultrasound" }))
        XCTAssertFalse(appState.todayTasks.contains(where: { $0.title == "Cetrotide" }))
    }

    func testTodayTasksSortByUrgencyRiskThenTime() {
        let builder = TodayTaskBuilder()
        let medications = [
            MedicationPlan(
                name: "Routine Injection",
                doseAmount: 75,
                unit: .iu,
                route: "Subcutaneous",
                scheduledTime: "6:00 AM",
                instructions: "Routine",
                isCritical: false
            ),
            MedicationPlan(
                name: "Trigger Shot",
                doseAmount: 250,
                unit: .mcg,
                route: "Subcutaneous",
                scheduledTime: "10:00 PM",
                instructions: "Critical",
                isCritical: true
            )
        ]
        let appointments = [
            AppointmentItem(title: "Lab Draw", scheduledTimeText: "7:00 AM", kind: "lab")
        ]

        let tasks = builder.build(medications: medications, appointments: appointments)
        XCTAssertEqual(tasks.first?.title, "Trigger Shot")
        XCTAssertEqual(tasks.dropFirst().first?.title, "Routine Injection")
        XCTAssertEqual(tasks.last?.title, "Lab Draw")
    }

    func testCompletionLoggingAndState() throws {
        let store = try makeSwiftDataStore()
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
        guard let highRiskTask = appState.todayTasks.first(where: { $0.riskLevel == .high }) else {
            XCTFail("Expected a high-risk task in demo data")
            return
        }

        XCTAssertFalse(appState.isTaskCompleted(highRiskTask.id))
        appState.completeTask(highRiskTask, confirmedByUser: true)
        XCTAssertTrue(appState.isTaskCompleted(highRiskTask.id))
        XCTAssertEqual(appState.completionLogs.count, 1)
        XCTAssertEqual(appState.completionLogs.first?.taskID, highRiskTask.id)
        XCTAssertTrue(appState.completionLogs.first?.requiredDoubleConfirmation == true)

        appState.uncompleteTask(highRiskTask.id)
        XCTAssertFalse(appState.isTaskCompleted(highRiskTask.id))
    }

    func testLateNightTriggerShotIsHighRiskAndKeepsLateSchedule() {
        let builder = TodayTaskBuilder()
        let medications = [
            MedicationPlan(
                name: "Ovidrel Trigger",
                doseAmount: 250,
                unit: .mcg,
                route: "Subcutaneous",
                scheduledTime: "11:30 PM",
                instructions: "Single trigger shot tonight only",
                isCritical: true
            ),
            MedicationPlan(
                name: "Cetrotide",
                doseAmount: 0.25,
                unit: .mg,
                route: "Subcutaneous",
                scheduledTime: "7:00 AM",
                instructions: "Morning dose",
                isCritical: false
            )
        ]

        let tasks = builder.build(medications: medications, appointments: [])
        guard let triggerTask = tasks.first(where: { $0.title == "Ovidrel Trigger" }) else {
            XCTFail("Expected trigger task")
            return
        }

        XCTAssertEqual(triggerTask.riskLevel, .high)
        XCTAssertEqual(tasks.first?.title, "Ovidrel Trigger")
        XCTAssertEqual(Calendar.current.component(.hour, from: triggerTask.scheduledDate ?? Date()), 23)
    }

    func testTransferDayAppointmentDefaultsToHighRisk() {
        let builder = TodayTaskBuilder()
        let appointments = [
            AppointmentItem(
                title: "Embryo Transfer",
                scheduledTimeText: "11:00 AM",
                locationText: "Transfer Suite",
                kind: "transfer",
                isCritical: false
            )
        ]

        let tasks = builder.build(medications: [], appointments: appointments)
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks[0].sourceType, .appointment)
        XCTAssertEqual(tasks[0].riskLevel, .high)
    }

    private func makeSwiftDataStore() throws -> AppStateSwiftDataStore {
        let schema = Schema([PersistedAppStateRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return AppStateSwiftDataStore(
            modelContext: ModelContext(container),
            legacyStore: nil
        )
    }
}
