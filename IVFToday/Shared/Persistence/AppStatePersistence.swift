import Foundation

struct PersistedAppState: Codable {
    var treatmentCase: IVFCase
    var currentDocument: ProtocolDocument
    var previousDocument: ProtocolDocument
    var medications: [MedicationPlan]
    var inventoryItems: [InventoryItem]
    var appointments: [AppointmentItem]
    var protocolHistory: [ProtocolHistoryEntry]
    var completedTaskIDs: Set<UUID>
    var completionLogs: [CompletionLog]
    var inventoryNotificationsEnabled: Bool

    init(
        treatmentCase: IVFCase,
        currentDocument: ProtocolDocument,
        previousDocument: ProtocolDocument,
        medications: [MedicationPlan],
        inventoryItems: [InventoryItem],
        appointments: [AppointmentItem],
        protocolHistory: [ProtocolHistoryEntry],
        completedTaskIDs: Set<UUID>,
        completionLogs: [CompletionLog],
        inventoryNotificationsEnabled: Bool
    ) {
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
    }

    private enum CodingKeys: String, CodingKey {
        case treatmentCase
        case currentDocument
        case previousDocument
        case medications
        case inventoryItems
        case appointments
        case protocolHistory
        case completedTaskIDs
        case completionLogs
        case inventoryNotificationsEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        treatmentCase = try container.decode(IVFCase.self, forKey: .treatmentCase)
        currentDocument = try container.decode(ProtocolDocument.self, forKey: .currentDocument)
        previousDocument = try container.decode(ProtocolDocument.self, forKey: .previousDocument)
        medications = try container.decode([MedicationPlan].self, forKey: .medications)
        inventoryItems = try container.decode([InventoryItem].self, forKey: .inventoryItems)
        appointments = try container.decodeIfPresent([AppointmentItem].self, forKey: .appointments) ?? []
        protocolHistory = try container.decodeIfPresent([ProtocolHistoryEntry].self, forKey: .protocolHistory) ?? []
        completedTaskIDs = try container.decodeIfPresent(Set<UUID>.self, forKey: .completedTaskIDs) ?? []
        completionLogs = try container.decodeIfPresent([CompletionLog].self, forKey: .completionLogs) ?? []
        inventoryNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .inventoryNotificationsEnabled) ?? false
    }
}

protocol AppStatePersisting {
    func load() throws -> PersistedAppState?
    func save(_ snapshot: PersistedAppState) throws
}
