import Foundation

struct MedicationDraftValidationService {
    struct Draft {
        let medicationName: String
        let doseAmount: String
        let scheduledTime: String
        let route: String
        let instructions: String
        let isActive: Bool
    }

    func validate(_ draft: Draft) -> [String] {
        var issues: [String] = []
        let name = draft.medicationName.trimmingCharacters(in: .whitespacesAndNewlines)
        let route = draft.route.trimmingCharacters(in: .whitespacesAndNewlines)
        let instructions = draft.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        let isInstructionRoute = route.lowercased() == "instruction"

        if name.isEmpty {
            issues.append("Medication name cannot be empty.")
        }

        if route.isEmpty {
            issues.append("Route cannot be empty.")
        }

        if draft.isActive && !isInstructionRoute {
            if let dose = Double(draft.doseAmount), dose > 0 {
                // Valid active dose.
            } else {
                issues.append("Active medication dose must be a number greater than 0.")
            }

            if draft.scheduledTime.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append("Active medication needs a scheduled time.")
            }
        }

        if !draft.isActive && instructions.isEmpty {
            issues.append("Inactive instruction should include guidance text.")
        }

        return issues
    }
}
