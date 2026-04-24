import Observation
import Foundation

@Observable
final class AppState {
    var treatmentCase: IVFCase {
        didSet { persistIfNeeded() }
    }
    var currentDocument: ProtocolDocument {
        didSet { persistIfNeeded() }
    }
    var previousDocument: ProtocolDocument {
        didSet { persistIfNeeded() }
    }
    var medications: [MedicationPlan] {
        didSet { persistIfNeeded() }
    }
    var inventoryItems: [InventoryItem] {
        didSet { persistIfNeeded() }
    }
    var appointments: [AppointmentItem] {
        didSet { persistIfNeeded() }
    }
    var protocolHistory: [ProtocolHistoryEntry] {
        didSet { persistIfNeeded() }
    }
    var completedTaskIDs: Set<UUID> {
        didSet { persistIfNeeded() }
    }
    var completionLogs: [CompletionLog] {
        didSet { persistIfNeeded() }
    }
    var inventoryNotificationsEnabled: Bool {
        didSet { persistIfNeeded() }
    }

    @ObservationIgnored
    private let persistenceStore: AppStatePersisting
    @ObservationIgnored
    private let taskBuilder = TodayTaskBuilder()
    @ObservationIgnored
    private let inventoryNotificationService: InventoryAlertNotificationService
    @ObservationIgnored
    private var isPersistenceEnabled = false
    @ObservationIgnored
    private var isBatchMutating = false

    init(
        treatmentCase: IVFCase,
        currentDocument: ProtocolDocument,
        previousDocument: ProtocolDocument,
        medications: [MedicationPlan],
        inventoryItems: [InventoryItem],
        appointments: [AppointmentItem] = [],
        protocolHistory: [ProtocolHistoryEntry] = [],
        completedTaskIDs: Set<UUID> = [],
        completionLogs: [CompletionLog] = [],
        inventoryNotificationsEnabled: Bool = false,
        inventoryNotificationService: InventoryAlertNotificationService = InventoryAlertNotificationService(),
        persistenceStore: AppStatePersisting = AppStateFileStore.shared
    ) {
        self.persistenceStore = persistenceStore
        self.inventoryNotificationService = inventoryNotificationService
        self.treatmentCase = treatmentCase
        self.currentDocument = currentDocument
        self.previousDocument = previousDocument
        self.medications = medications
        self.inventoryItems = inventoryItems
        self.appointments = appointments
        self.protocolHistory = protocolHistory
        self.completedTaskIDs = completedTaskIDs
        self.completionLogs = completionLogs
        self.inventoryNotificationsEnabled = inventoryNotificationsEnabled

        loadPersistedStateIfAvailable()
        bootstrapProtocolHistoryIfNeeded()
        pruneCompletionState()
        isPersistenceEnabled = true
        triggerInventoryNotificationSync()
    }

    var todayTasks: [TodayTask] {
        taskBuilder.build(medications: medications, appointments: appointments)
    }

    var changeItems: [ChangeItem] {
        if let latestHistoryEntry = protocolHistory.last(where: { $0.document.id == currentDocument.id }) {
            return latestHistoryEntry.changeSet?.items ?? []
        }
        return ProtocolDiffService.diff(previous: previousDocument, current: currentDocument)
    }

    var inventoryAlerts: [InventoryAlert] {
        InventoryForecastService.alerts(for: medications, inventoryItems: inventoryItems)
    }

    var inventoryProjections: [InventoryProjection] {
        InventoryForecastService.projections(for: medications, inventoryItems: inventoryItems)
    }

    func inventoryProjection(for itemID: UUID) -> InventoryProjection? {
        inventoryProjections.first(where: { $0.id == itemID })
    }

    func syncCurrentDocument() {
        withBatchMutation {
            let summary = ProtocolDocument.textSummary(for: medications)
            currentDocument = makeProtocolDocument(
                caseID: treatmentCase.id,
                sourceType: .manualEntry,
                rawText: summary,
                normalizedText: summary
            )
        }
    }

    func addMedication() {
        withBatchMutation {
            medications.append(
                MedicationPlan(
                    name: "New Medication",
                    doseAmount: 0,
                    unit: .mg,
                    route: "Subcutaneous",
                    scheduledTime: "8:00 PM",
                    instructions: "Add instructions",
                    isCritical: false
                )
            )
            let summary = ProtocolDocument.textSummary(for: medications)
            currentDocument = makeProtocolDocument(
                caseID: treatmentCase.id,
                sourceType: .manualEntry,
                rawText: summary,
                normalizedText: summary
            )
        }
    }

    func removeMedication(at offsets: IndexSet) {
        withBatchMutation {
            for index in offsets.sorted(by: >) {
                medications.remove(at: index)
            }
            let summary = ProtocolDocument.textSummary(for: medications)
            currentDocument = makeProtocolDocument(
                caseID: treatmentCase.id,
                sourceType: .manualEntry,
                rawText: summary,
                normalizedText: summary
            )
        }
    }

    func applyImportedProtocol(
        sourceType: DocumentSourceType,
        sourceFilename: String?,
        rawText: String,
        normalizedText: String,
        medications importedMedications: [MedicationPlan],
        appointments importedAppointments: [AppointmentItem] = []
    ) {
        withBatchMutation {
            previousDocument = currentDocument

            let existingInventoryItems = inventoryItems
            var seenMedicationNames = Set<String>()
            inventoryItems = importedMedications
                .filter { medication in
                    medication.isActive && medication.doseAmount > 0 && medication.route != "Instruction"
                }
                .compactMap { medication in
                    guard seenMedicationNames.insert(medication.name).inserted else {
                        return nil
                    }

                    if let existingItem = existingInventoryItems.first(where: { $0.medicationName == medication.name }) {
                        return existingItem
                    }

                    return InventoryItem(
                        medicationName: medication.name,
                        unit: medication.unit,
                        remainingAmount: 0,
                        alertThreshold: medication.doseAmount
                    )
                }

            medications = importedMedications
            appointments = importedAppointments
            pruneCompletionState()
            triggerInventoryNotificationSync()

            currentDocument = makeProtocolDocument(
                caseID: treatmentCase.id,
                sourceType: sourceType,
                sourceFilename: sourceFilename,
                rawText: rawText,
                normalizedText: normalizedText
            )
            appendHistoryEntry(for: currentDocument, comparedTo: previousDocument)
        }
    }

    func updateInventoryItem(
        id: UUID,
        remainingAmount: Double,
        alertThreshold: Double,
        updatedAt: Date = Date()
    ) {
        guard let index = inventoryItems.firstIndex(where: { $0.id == id }) else {
            return
        }

        withBatchMutation {
            let existing = inventoryItems[index]
            inventoryItems[index] = InventoryItem(
                id: existing.id,
                medicationName: existing.medicationName,
                unit: existing.unit,
                remainingAmount: max(0, remainingAmount),
                alertThreshold: max(0, alertThreshold),
                lastUpdatedAt: updatedAt
            )
            triggerInventoryNotificationSync()
        }
    }

    func setInventoryNotificationsEnabled(_ isEnabled: Bool) {
        withBatchMutation {
            inventoryNotificationsEnabled = isEnabled
            triggerInventoryNotificationSync()
        }
    }

    func resetToDemoData() {
        withBatchMutation {
            let resetCase = DemoDataFactory.createDemoIVFCase()
            let resetMedications = DemoDataFactory.createCurrentMedicationPlans()
            let resetAppointments = DemoDataFactory.createAppointments()
            let resetPreviousDocument = DemoDataFactory.createPreviousProtocolDocument(for: resetCase.id)
            let resetCurrentDocument = DemoDataFactory.createCurrentProtocolDocument(
                for: resetCase.id,
                medications: resetMedications,
                appointments: resetAppointments
            )

            treatmentCase = resetCase
            previousDocument = resetPreviousDocument
            currentDocument = resetCurrentDocument
            medications = resetMedications
            inventoryItems = DemoDataFactory.createInventoryItems()
            appointments = resetAppointments
            protocolHistory = []
            completedTaskIDs = []
            completionLogs = []
            inventoryNotificationsEnabled = false

            bootstrapProtocolHistoryIfNeeded()
            pruneCompletionState()
            triggerInventoryNotificationSync()
        }
    }

    func isTaskCompleted(_ taskID: UUID) -> Bool {
        completedTaskIDs.contains(taskID)
    }

    func completeTask(_ task: TodayTask, confirmedByUser: Bool) {
        withBatchMutation {
            guard !completedTaskIDs.contains(task.id) else {
                return
            }
            completedTaskIDs.insert(task.id)
            completionLogs.append(
                CompletionLog(
                    taskID: task.id,
                    taskTitle: task.title,
                    sourceType: task.sourceType,
                    riskLevel: task.riskLevel,
                    requiredDoubleConfirmation: task.riskLevel == .high && confirmedByUser
                )
            )
        }
    }

    func uncompleteTask(_ taskID: UUID) {
        withBatchMutation {
            completedTaskIDs.remove(taskID)
        }
    }

    private func persistIfNeeded() {
        guard isPersistenceEnabled, !isBatchMutating else {
            return
        }
        persistSnapshot()
    }

    private func withBatchMutation(_ block: () -> Void) {
        let wasMutating = isBatchMutating
        isBatchMutating = true
        block()
        isBatchMutating = wasMutating
        persistIfNeeded()
    }

    private func loadPersistedStateIfAvailable() {
        do {
            guard let persistedState = try persistenceStore.load() else {
                return
            }
            treatmentCase = persistedState.treatmentCase
            currentDocument = persistedState.currentDocument
            previousDocument = persistedState.previousDocument
            medications = persistedState.medications
            inventoryItems = persistedState.inventoryItems
            appointments = persistedState.appointments
            protocolHistory = persistedState.protocolHistory
            completedTaskIDs = persistedState.completedTaskIDs
            completionLogs = persistedState.completionLogs
            inventoryNotificationsEnabled = persistedState.inventoryNotificationsEnabled
            pruneCompletionState()
        } catch is DecodingError {
            // Ignore invalid persisted data and keep fallback demo state.
            return
        } catch {
            return
        }
    }

    private func persistSnapshot() {
        let snapshot = PersistedAppState(
            treatmentCase: treatmentCase,
            currentDocument: currentDocument,
            previousDocument: previousDocument,
            medications: medications,
            inventoryItems: inventoryItems,
            appointments: appointments,
            protocolHistory: protocolHistory,
            completedTaskIDs: completedTaskIDs,
            completionLogs: completionLogs,
            inventoryNotificationsEnabled: inventoryNotificationsEnabled
        )
        do {
            try persistenceStore.save(snapshot)
        } catch {
            return
        }
    }

    private func pruneCompletionState() {
        let validTaskIDs = Set(todayTasks.map(\.id))
        completedTaskIDs = completedTaskIDs.intersection(validTaskIDs)
    }

    private func makeProtocolDocument(
        caseID: UUID,
        sourceType: DocumentSourceType,
        sourceFilename: String? = nil,
        rawText: String,
        normalizedText: String
    ) -> ProtocolDocument {
        ProtocolDocument(
            caseID: caseID,
            sourceType: sourceType,
            sourceFilename: sourceFilename,
            rawText: rawText,
            normalizedText: normalizedText,
            isActiveBaseline: true,
            medicationSnapshot: medications,
            appointmentSnapshot: appointments
        )
    }

    private func appendHistoryEntry(for document: ProtocolDocument, comparedTo previous: ProtocolDocument?) {
        let changeSet = ProtocolChangeSet(
            previousDocumentID: previous?.id,
            currentDocumentID: document.id,
            createdAt: document.createdAt,
            items: previous.map { ProtocolDiffService.diff(previous: $0, current: document) } ?? []
        )
        let entry = ProtocolHistoryEntry(
            document: document,
            changeSet: changeSet,
            recordedAt: document.createdAt
        )
        protocolHistory.append(entry)
        protocolHistory.sort { $0.recordedAt < $1.recordedAt }
    }

    private func bootstrapProtocolHistoryIfNeeded() {
        guard protocolHistory.isEmpty else {
            return
        }

        let baselineEntry = ProtocolHistoryEntry(
            document: previousDocument,
            changeSet: nil,
            recordedAt: previousDocument.createdAt
        )
        let currentChangeSet = ProtocolChangeSet(
            previousDocumentID: previousDocument.id,
            currentDocumentID: currentDocument.id,
            createdAt: currentDocument.createdAt,
            items: ProtocolDiffService.diff(previous: previousDocument, current: currentDocument)
        )
        let currentEntry = ProtocolHistoryEntry(
            document: currentDocument,
            changeSet: currentChangeSet,
            recordedAt: currentDocument.createdAt
        )
        protocolHistory = previousDocument.id == currentDocument.id ? [currentEntry] : [baselineEntry, currentEntry]
    }

    private func triggerInventoryNotificationSync() {
        let alerts = inventoryAlerts
        let trackedMedicationNames = inventoryItems.map(\.medicationName)
        let isEnabled = inventoryNotificationsEnabled
        Task {
            await inventoryNotificationService.syncLowStockNotifications(
                alerts: alerts,
                trackedMedicationNames: trackedMedicationNames,
                isEnabled: isEnabled
            )
        }
    }
}
