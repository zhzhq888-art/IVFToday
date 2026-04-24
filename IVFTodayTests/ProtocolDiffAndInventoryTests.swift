import XCTest
@testable import IVFToday

final class ProtocolDiffAndInventoryTests: XCTestCase {
    func testApplyImportedProtocolDoesNotCreateInventoryRowsForInstructionOnlyLines() {
        let appState = DemoDataFactory.createAppState()
        let caseID = appState.treatmentCase.id

        let importedMedications = [
            MedicationPlan(
                name: "Continue aspirin",
                doseAmount: 0,
                unit: .iu,
                route: "Instruction",
                scheduledTime: "after dinner",
                instructions: "Continue after dinner",
                isActive: true
            ),
            MedicationPlan(
                name: "Hold Cetrotide",
                doseAmount: 0,
                unit: .iu,
                route: "Instruction",
                scheduledTime: "tonight",
                instructions: "Hold tonight",
                isActive: false
            ),
            MedicationPlan(
                name: "Gonal-F",
                doseAmount: 150,
                unit: .iu,
                route: "Subcutaneous",
                scheduledTime: "8:00 PM",
                instructions: "Resume tonight",
                isActive: true
            )
        ]

        appState.applyImportedProtocol(
            sourceType: .pdf,
            sourceFilename: "Imported.pdf",
            rawText: "raw",
            normalizedText: "normalized",
            medications: importedMedications
        )

        XCTAssertEqual(appState.currentDocument.caseID, caseID)
        XCTAssertEqual(appState.inventoryItems.count, 1)
        XCTAssertEqual(appState.inventoryItems.first?.medicationName, "Gonal-F")
    }

    func testApplyImportedProtocolPersistsAppointmentsWithoutBreakingMedicationFlow() {
        let appState = DemoDataFactory.createAppState()
        let importedMedications = [
            MedicationPlan(
                name: "Gonal-F",
                doseAmount: 150,
                unit: .iu,
                route: "Subcutaneous",
                scheduledTime: "8:00 PM",
                instructions: "Resume tonight",
                isActive: true
            )
        ]
        let importedAppointments = [
            AppointmentItem(
                title: "Ultrasound monitoring",
                scheduledDate: nil,
                scheduledTimeText: "7:30 AM",
                locationText: "Main Clinic",
                kind: "monitoring",
                isCritical: false,
                sourceLine: "Ultrasound monitoring tomorrow 7:30 AM at Main Clinic"
            ),
            AppointmentItem(
                title: "Egg retrieval",
                scheduledDate: nil,
                scheduledTimeText: "06:45 AM",
                locationText: "OR Suite 2",
                kind: "retrieval",
                isCritical: true,
                sourceLine: "Egg retrieval 06:45 AM in OR Suite 2"
            )
        ]

        appState.applyImportedProtocol(
            sourceType: .pdf,
            sourceFilename: "Imported.pdf",
            rawText: "raw",
            normalizedText: "normalized",
            medications: importedMedications,
            appointments: importedAppointments
        )

        XCTAssertEqual(appState.medications.count, 1)
        XCTAssertEqual(appState.inventoryItems.count, 1)
        XCTAssertEqual(appState.inventoryItems.first?.medicationName, "Gonal-F")
        XCTAssertEqual(appState.appointments.count, 2)
        XCTAssertTrue(appState.appointments.contains(where: { $0.kind == "monitoring" }))
        XCTAssertTrue(appState.appointments.contains(where: { $0.kind == "retrieval" && $0.isCritical }))
    }

    func testProtocolDiffDetectsDoseTimeDetailsAddedAndStoppedChanges() {
        let caseID = UUID()
        let previous = ProtocolDocument(
            caseID: caseID,
            sourceType: .manualEntry,
            rawText: """
            Gonal-F|225 IU|8:00 PM|Subcutaneous|Evening stimulation injection
            Cetrotide|0.25 mg|7:30 AM|Subcutaneous|Start antagonist coverage
            """
        )
        let current = ProtocolDocument(
            caseID: caseID,
            sourceType: .manualEntry,
            rawText: """
            Gonal-F|150 IU|8:00 PM|Subcutaneous|Reduced dose after monitoring
            Cetrotide|0.25 mg|7:00 AM|Subcutaneous|Start antagonist coverage
            Lupron|10 IU|9:00 PM|Subcutaneous|Added tonight
            """
        )

        let changes = ProtocolDiffService.diff(previous: previous, current: current)

        XCTAssertEqual(changes.count, 3)
        XCTAssertTrue(changes.contains { $0.medicationName == "Gonal-F" && $0.type == .doseChanged })
        XCTAssertTrue(changes.contains { $0.medicationName == "Cetrotide" && $0.type == .timeChanged })
        XCTAssertTrue(changes.contains { $0.medicationName == "Lupron" && $0.type == .added })
    }

    func testProtocolDiffDetectsStoppedAndDetailsChanged() {
        let caseID = UUID()
        let previous = ProtocolDocument(
            caseID: caseID,
            sourceType: .manualEntry,
            rawText: """
            Progesterone|1 mL|before bed|Intramuscular|Nightly support
            Ovidrel Trigger|250 mcg|9:30 PM|Subcutaneous|Single trigger shot|critical
            """
        )
        let current = ProtocolDocument(
            caseID: caseID,
            sourceType: .manualEntry,
            rawText: """
            Progesterone|1 mL|before bed|Intramuscular|Nightly support after shower
            """
        )

        let changes = ProtocolDiffService.diff(previous: previous, current: current)

        XCTAssertEqual(changes.count, 2)
        XCTAssertEqual(changes.first?.medicationName, "Ovidrel Trigger")
        XCTAssertEqual(changes.first?.type, .stopped)
        XCTAssertTrue(changes.first?.isCritical == true)
        XCTAssertTrue(changes.contains { $0.medicationName == "Progesterone" && $0.type == .detailsChanged })
    }

    func testProtocolDiffDetectsAppointmentAwareSemanticChangesAndKeepsCriticalFirst() {
        let caseID = UUID()
        let previousAppointments = [
            AppointmentItem(
                title: "Morning Ultrasound Monitoring",
                scheduledTimeText: "8:00 AM",
                locationText: "Main Clinic",
                kind: "monitoring"
            ),
            AppointmentItem(
                title: "Egg Retrieval Arrival",
                scheduledTimeText: "6:30 AM",
                locationText: "OR Suite 1",
                kind: "retrieval",
                isCritical: true
            )
        ]
        let currentAppointments = [
            AppointmentItem(
                title: "Morning Ultrasound Monitoring",
                scheduledTimeText: "7:30 AM",
                locationText: "Main Clinic",
                kind: "monitoring"
            ),
            AppointmentItem(
                title: "Embryo Transfer",
                scheduledTimeText: "11:00 AM",
                locationText: "Transfer Suite",
                kind: "transfer",
                isCritical: true
            )
        ]
        let previous = ProtocolDocument(
            caseID: caseID,
            sourceType: .manualEntry,
            rawText: "",
            normalizedText: "",
            medicationSnapshot: [],
            appointmentSnapshot: previousAppointments
        )
        let current = ProtocolDocument(
            caseID: caseID,
            sourceType: .manualEntry,
            rawText: "",
            normalizedText: "",
            medicationSnapshot: [],
            appointmentSnapshot: currentAppointments
        )

        let changes = ProtocolDiffService.diff(previous: previous, current: current)

        XCTAssertEqual(changes.count, 3)
        XCTAssertEqual(changes.first?.subjectType, .appointment)
        XCTAssertTrue(changes.first?.isCritical == true)
        XCTAssertTrue(changes.contains {
            $0.subjectType == .appointment &&
            $0.subjectName == "Morning Ultrasound Monitoring" &&
            $0.type == .timeChanged
        })
        XCTAssertTrue(changes.contains {
            $0.subjectType == .appointment &&
            $0.subjectName == "Egg Retrieval Arrival" &&
            $0.type == .stopped
        })
        XCTAssertTrue(changes.contains {
            $0.subjectType == .appointment &&
            $0.subjectName == "Embryo Transfer" &&
            $0.type == .added
        })
    }

    func testInventoryForecastReturnsCriticalAndWarningAlerts() {
        let medications = [
            MedicationPlan(
                name: "Gonal-F",
                doseAmount: 225,
                unit: .iu,
                route: "Subcutaneous",
                scheduledTime: "8:00 PM",
                instructions: "Evening stimulation injection"
            ),
            MedicationPlan(
                name: "Cetrotide",
                doseAmount: 0.25,
                unit: .mg,
                route: "Subcutaneous",
                scheduledTime: "7:00 AM",
                instructions: "Antagonist coverage"
            ),
            MedicationPlan(
                name: "Hold aspirin",
                doseAmount: 0,
                unit: .iu,
                route: "Instruction",
                scheduledTime: "tonight",
                instructions: "Hold tonight",
                isActive: false
            )
        ]

        let inventoryItems = [
            InventoryItem(medicationName: "Gonal-F", unit: .iu, remainingAmount: 200, alertThreshold: 150),
            InventoryItem(medicationName: "Cetrotide", unit: .mg, remainingAmount: 1.8, alertThreshold: 0.1),
            InventoryItem(medicationName: "Hold aspirin", unit: .iu, remainingAmount: 1, alertThreshold: 0)
        ]

        let alerts = InventoryForecastService.alerts(for: medications, inventoryItems: inventoryItems)

        XCTAssertEqual(alerts.count, 2)
        XCTAssertTrue(alerts.contains { $0.medicationName == "Gonal-F" && $0.isCritical })
        XCTAssertTrue(alerts.contains { $0.medicationName == "Cetrotide" && !$0.isCritical })
        XCTAssertFalse(alerts.contains { $0.medicationName == "Hold aspirin" })
        XCTAssertTrue(alerts.contains { $0.medicationName == "Cetrotide" && ($0.daysLeft ?? 0) > 0 })
    }

    func testInventoryProjectionCalculatesExplicitDaysLeft() {
        let medications = [
            MedicationPlan(
                name: "Gonal-F",
                doseAmount: 150,
                unit: .iu,
                route: "Subcutaneous",
                scheduledTime: "8:00 PM",
                instructions: "Evening stimulation injection"
            )
        ]
        let inventoryItems = [
            InventoryItem(medicationName: "Gonal-F", unit: .iu, remainingAmount: 450, alertThreshold: 120)
        ]

        let projections = InventoryForecastService.projections(for: medications, inventoryItems: inventoryItems)

        XCTAssertEqual(projections.count, 1)
        XCTAssertEqual(projections[0].medicationName, "Gonal-F")
        XCTAssertEqual(projections[0].dailyDoseAmount, 150, accuracy: 0.001)
        XCTAssertEqual(projections[0].remainingAfterToday, 300, accuracy: 0.001)
        XCTAssertEqual(projections[0].daysLeft ?? 0, 3.0, accuracy: 0.001)
        XCTAssertEqual(projections[0].alertThresholdAmount, 120, accuracy: 0.001)
        XCTAssertFalse(projections[0].isCritical)
    }

    func testInventoryForecastWarnsForProjectedLowStockWithinSevenDays() {
        let medications = [
            MedicationPlan(
                name: "Menopur",
                doseAmount: 75,
                unit: .iu,
                route: "Subcutaneous",
                scheduledTime: "8:00 PM",
                instructions: "Evening stimulation injection"
            )
        ]
        let inventoryItems = [
            InventoryItem(medicationName: "Menopur", unit: .iu, remainingAmount: 650, alertThreshold: 200)
        ]

        let alerts = InventoryForecastService.alerts(for: medications, inventoryItems: inventoryItems)

        XCTAssertEqual(alerts.count, 1)
        XCTAssertEqual(alerts[0].medicationName, "Menopur")
        XCTAssertFalse(alerts[0].isCritical)
        XCTAssertTrue(alerts[0].message.contains("Projected low stock within 7 days"))
    }
}
