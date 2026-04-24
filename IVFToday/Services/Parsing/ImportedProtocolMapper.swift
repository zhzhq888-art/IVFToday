import Foundation

struct ImportedProtocolMapper {
    func mapToMedicationPlans(from results: [MedicationLineParser.LineResult]) -> [MedicationPlan] {
        let parsed = results.filter { $0.state == .parsed }

        return parsed.compactMap { line in
            let hasDose = line.doseAmount != nil
            let hasDirective = line.directive != nil
            let isInstructionOnlyDirective = line.directive?.isActiveDirective == false

            guard hasDose || hasDirective else {
                return nil
            }

            let name = line.medicationName?.trimmingCharacters(in: .whitespacesAndNewlines)
            let medicationName = (name?.isEmpty == false) ? name! : "Imported Medication"

            let doseAmount = Double(line.doseAmount ?? "") ?? 0
            let unit = mapUnit(line.unit, fallback: isInstructionOnlyDirective ? .iu : .mg)
            let scheduledTime = (line.scheduledTime?.isEmpty == false)
                ? line.scheduledTime!
                : (hasDirective ? "As needed" : "8:00 PM")
            let instructions = instructions(for: line)
            let isActive = !isInstructionOnlyDirective

            let lower = "\(medicationName) \(instructions)".lowercased()
            let isCritical = lower.contains("trigger") || lower.contains("urgent")

            return MedicationPlan(
                name: medicationName,
                doseAmount: doseAmount,
                unit: unit,
                route: inferredRoute(for: line, hasDose: hasDose, isInstructionOnlyDirective: isInstructionOnlyDirective),
                scheduledTime: scheduledTime,
                instructions: instructions,
                isCritical: isCritical,
                isActive: isActive
            )
        }
    }

    private func instructions(for line: MedicationLineParser.LineResult) -> String {
        let remainingText = sanitizedInstructionText(from: line.remainingText)
        if let directive = line.directive, line.doseAmount == nil {
            if let remainingText, !remainingText.isEmpty {
                return "\(directive.displayText) \(remainingText)"
            }
            return directive.displayText
        }

        if let remainingText, !remainingText.isEmpty {
            return remainingText
        }

        return "Imported from extracted protocol line"
    }

    private func inferredRoute(
        for line: MedicationLineParser.LineResult,
        hasDose: Bool,
        isInstructionOnlyDirective: Bool
    ) -> String {
        let raw = line.rawLine.lowercased()

        if raw.contains(" intramuscular") || raw.contains(" im ") || raw.hasSuffix(" im") {
            return "Intramuscular"
        }
        if raw.contains(" oral") || raw.contains(" by mouth") || raw.contains(" po ") || raw.hasSuffix(" po") {
            return "Oral"
        }
        if raw.contains(" vaginal") {
            return "Vaginal"
        }
        if raw.contains(" subcutaneous") || raw.contains(" subcut") || raw.contains(" sq ") || raw.hasSuffix(" sq") || raw.contains(" sc ") || raw.hasSuffix(" sc") {
            return "Subcutaneous"
        }
        if isInstructionOnlyDirective || !hasDose {
            return "Instruction"
        }
        return "Subcutaneous"
    }

    private func sanitizedInstructionText(from value: String?) -> String? {
        guard var text = value?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }

        let routePatterns = [
            #"(?i)\bsubcutaneous\b"#,
            #"(?i)\bsubcut\b"#,
            #"(?i)\bintramuscular\b"#,
            #"(?i)\bim\b"#,
            #"(?i)\boral\b"#,
            #"(?i)\bby mouth\b"#,
            #"(?i)\bpo\b"#,
            #"(?i)\bvaginal\b"#,
            #"(?i)\bsc\b"#,
            #"(?i)\bsq\b"#
        ]

        for pattern in routePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(text.startIndex..<text.endIndex, in: text)
                text = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
            }
        }

        text = text.replacingOccurrences(of: "  ", with: " ")
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        text = text.trimmingCharacters(in: CharacterSet(charactersIn: "-:•,.;"))
        return text.isEmpty ? nil : text
    }

    private func mapUnit(_ value: String?, fallback: MedicationUnit) -> MedicationUnit {
        switch value?.lowercased() {
        case "iu", "units", "unit":
            return .iu
        case "mg":
            return .mg
        case "mcg", "μg":
            return .mcg
        case "ml":
            return .ml
        default:
            return fallback
        }
    }
}
