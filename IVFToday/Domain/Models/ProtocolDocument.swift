import Foundation

struct ProtocolDocument: Identifiable, Codable, Hashable {
    let id: UUID
    let caseID: UUID
    let sourceType: DocumentSourceType
    let sourceFilename: String?
    let capturedAt: Date
    let rawText: String
    let normalizedText: String
    let isActiveBaseline: Bool
    let createdAt: Date
    let medicationSnapshot: [MedicationPlan]
    let appointmentSnapshot: [AppointmentItem]

    private enum CodingKeys: String, CodingKey {
        case id
        case caseID
        case sourceType
        case sourceFilename
        case capturedAt
        case rawText
        case normalizedText
        case isActiveBaseline
        case createdAt
        case medicationSnapshot
        case appointmentSnapshot
    }
    
    init(
        id: UUID = UUID(),
        caseID: UUID,
        sourceType: DocumentSourceType,
        sourceFilename: String? = nil,
        capturedAt: Date = Date(),
        rawText: String,
        normalizedText: String = "",
        isActiveBaseline: Bool = false,
        createdAt: Date = Date(),
        medicationSnapshot: [MedicationPlan] = [],
        appointmentSnapshot: [AppointmentItem] = []
    ) {
        self.id = id
        self.caseID = caseID
        self.sourceType = sourceType
        self.sourceFilename = sourceFilename
        self.capturedAt = capturedAt
        self.rawText = rawText
        self.normalizedText = normalizedText
        self.isActiveBaseline = isActiveBaseline
        self.createdAt = createdAt
        self.medicationSnapshot = medicationSnapshot
        self.appointmentSnapshot = appointmentSnapshot
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        caseID = try container.decode(UUID.self, forKey: .caseID)
        sourceType = try container.decode(DocumentSourceType.self, forKey: .sourceType)
        sourceFilename = try container.decodeIfPresent(String.self, forKey: .sourceFilename)
        capturedAt = try container.decode(Date.self, forKey: .capturedAt)
        rawText = try container.decode(String.self, forKey: .rawText)
        normalizedText = try container.decode(String.self, forKey: .normalizedText)
        isActiveBaseline = try container.decode(Bool.self, forKey: .isActiveBaseline)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        medicationSnapshot = try container.decodeIfPresent([MedicationPlan].self, forKey: .medicationSnapshot) ?? []
        appointmentSnapshot = try container.decodeIfPresent([AppointmentItem].self, forKey: .appointmentSnapshot) ?? []
    }
}

extension ProtocolDocument {
    struct ParsedMedicationLine: Hashable {
        let name: String
        let dose: String
        let time: String
        let route: String
        let instructions: String
        let isCritical: Bool
    }

    var parsedMedicationLines: [ParsedMedicationLine] {
        if !medicationSnapshot.isEmpty {
            return medicationSnapshot.map { medication in
                ParsedMedicationLine(
                    name: medication.name,
                    dose: medication.formattedDose,
                    time: medication.scheduledTime,
                    route: medication.route,
                    instructions: medication.instructions,
                    isCritical: medication.isCritical
                )
            }
        }

        return rawText
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .compactMap { line -> ParsedMedicationLine? in
                let parts = line.split(separator: "|").map {
                    String($0).trimmingCharacters(in: .whitespacesAndNewlines)
                }

                guard parts.count >= 5 else {
                    return nil
                }

                return ParsedMedicationLine(
                    name: parts[0],
                    dose: parts[1],
                    time: parts[2],
                    route: parts[3],
                    instructions: parts[4].replacingOccurrences(of: "\\n", with: "\n"),
                    isCritical: parts.count >= 6 && parts[5].lowercased() == "critical"
                )
            }
    }

    var parsedAppointmentItems: [AppointmentItem] {
        appointmentSnapshot
    }

    static func textSummary(for medications: [MedicationPlan]) -> String {
        medications
            .map { medication in
                let criticalMarker = medication.isCritical ? "|critical" : ""
                let safeInstructions = medication.instructions.replacingOccurrences(of: "\n", with: "\\n")
                return "\(medication.name)|\(medication.formattedDose)|\(medication.scheduledTime)|\(medication.route)|\(safeInstructions)\(criticalMarker)"
            }
            .joined(separator: "\n")
    }
}
