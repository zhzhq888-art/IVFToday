import Foundation

struct DemoDataFactory {
    static func createDemoIVFCase() -> IVFCase {
        IVFCase(
            title: "Cycle #1 - April 2026",
            stage: .stimulation,
            clinicName: "Fertility Clinic",
            notes: "First IVF cycle with antagonist protocol"
        )
    }

    static func createPreviousProtocolDocument(for caseID: UUID) -> ProtocolDocument {
        let previousMedications = [
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
                scheduledTime: "7:30 AM",
                instructions: "Start antagonist coverage"
            )
        ]
        let previousAppointments = [
            AppointmentItem(
                title: "Morning Ultrasound Monitoring",
                scheduledTimeText: "8:00 AM",
                locationText: "Main Clinic",
                kind: "monitoring"
            )
        ]

        return ProtocolDocument(
            caseID: caseID,
            sourceType: .manualEntry,
            rawText: ProtocolDocument.textSummary(for: previousMedications),
            normalizedText: ProtocolDocument.textSummary(for: previousMedications),
            isActiveBaseline: false,
            medicationSnapshot: previousMedications,
            appointmentSnapshot: previousAppointments
        )
    }

    static func createCurrentMedicationPlans() -> [MedicationPlan] {
        [
            MedicationPlan(
                name: "Gonal-F",
                doseAmount: 150,
                unit: .iu,
                route: "Subcutaneous",
                scheduledTime: "8:00 PM",
                instructions: "Reduced dose after morning monitoring"
            ),
            MedicationPlan(
                name: "Cetrotide",
                doseAmount: 0.25,
                unit: .mg,
                route: "Subcutaneous",
                scheduledTime: "7:00 AM",
                instructions: "Take earlier before ultrasound review"
            ),
            MedicationPlan(
                name: "Ovidrel Trigger",
                doseAmount: 250,
                unit: .mcg,
                route: "Subcutaneous",
                scheduledTime: "9:30 PM",
                instructions: "Single trigger shot tonight only",
                isCritical: true
            )
        ]
    }

    static func createCurrentProtocolDocument(
        for caseID: UUID,
        medications: [MedicationPlan]? = nil,
        appointments: [AppointmentItem]? = nil
    ) -> ProtocolDocument {
        let activeMedications = medications ?? createCurrentMedicationPlans()
        let activeAppointments = appointments ?? createAppointments()
        let summary = ProtocolDocument.textSummary(for: activeMedications)

        return ProtocolDocument(
            caseID: caseID,
            sourceType: .manualEntry,
            rawText: summary,
            normalizedText: summary,
            isActiveBaseline: true,
            medicationSnapshot: activeMedications,
            appointmentSnapshot: activeAppointments
        )
    }

    static func createInventoryItems() -> [InventoryItem] {
        [
            InventoryItem(
                medicationName: "Gonal-F",
                unit: .iu,
                remainingAmount: 300,
                alertThreshold: 150
            ),
            InventoryItem(
                medicationName: "Cetrotide",
                unit: .mg,
                remainingAmount: 0.5,
                alertThreshold: 0.25
            ),
            InventoryItem(
                medicationName: "Ovidrel Trigger",
                unit: .mcg,
                remainingAmount: 250,
                alertThreshold: 250
            )
        ]
    }

    static func createAppointments() -> [AppointmentItem] {
        [
            AppointmentItem(
                title: "Morning Ultrasound Monitoring",
                scheduledTimeText: "7:30 AM",
                locationText: "Main Clinic",
                kind: "monitoring"
            ),
            AppointmentItem(
                title: "Egg Retrieval Arrival",
                scheduledTimeText: "6:45 AM",
                locationText: "OR Suite 2",
                kind: "retrieval",
                isCritical: true
            )
        ]
    }

    static func createAppState(
        persistenceStore: AppStatePersisting = AppStateFileStore.shared
    ) -> AppState {
        let treatmentCase = createDemoIVFCase()
        let medications = createCurrentMedicationPlans()
        let appointments = createAppointments()

        return AppState(
            treatmentCase: treatmentCase,
            currentDocument: createCurrentProtocolDocument(
                for: treatmentCase.id,
                medications: medications,
                appointments: appointments
            ),
            previousDocument: createPreviousProtocolDocument(for: treatmentCase.id),
            medications: medications,
            inventoryItems: createInventoryItems(),
            appointments: appointments,
            persistenceStore: persistenceStore
        )
    }
}
