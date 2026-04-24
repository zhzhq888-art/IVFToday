import Foundation

struct MedicationLineParser {
    enum ParseState {
        case parsed
        case unparsed
    }

    enum InstructionDirective: String {
        case take
        case inject
        case use
        case start
        case `continue`
        case stop
        case hold
        case pause
        case discontinue
        case skip

        var isActiveDirective: Bool {
            switch self {
            case .stop, .hold, .pause, .discontinue, .skip:
                return false
            case .take, .inject, .use, .start, .continue:
                return true
            }
        }

        var displayText: String {
            switch self {
            case .continue:
                return "Continue"
            default:
                return rawValue.capitalized
            }
        }
    }
    
    struct LineResult {
        let rawLine: String
        let medicationName: String?
        let doseAmount: String?
        let unit: String?
        let scheduledTime: String?
        let remainingText: String?
        let directive: InstructionDirective?
        let state: ParseState
    }
    
    private static let dosePattern = #"(\d+(?:\.\d+)?)\s*(IU|mg|mcg|μg|g|mL|ml|m1|units?)"#
    private static let timePattern = #"\b(?:tomorrow|today|tonight)\s+(?:morning|afternoon|evening|night)\b|\b(?:every\s+other\s+night|every\s+other\s+day|every\s+night|nightly|before\s+bed|bedtime|after\s+breakfast|before\s+breakfast|after\s+lunch|after\s+dinner|with\s+dinner|twice\s+daily|once\s+daily)\b|\b(?:qhs|qam|qpm|qod|eod|bid|tid|qid)\b|\b(?:tomorrow|today|tonight)\b|\b(?:morning|afternoon|evening|night|noon|midday)\b|\b(?:[01]?\d|2[0-3]):[0-5]\d\s*(?:AM|PM|am|pm)?\b|\b(?:1[0-2]|0?[1-9])\s*(?:AM|PM|am|pm)\b"#
    private static let leadingDirectivePattern = #"^(?i)(take|inject|use|start|continue|stop|hold|pause|discontinue|skip)\b[\s:,-]*"#
    private static let leadingBulletPattern = #"^\s*(?:[-•*]+|\d+[.)])\s*"#
    private static let leadingDayPattern = #"^(?i)(?:day|cycle day|cd)\s*\d+\s*[:\-–—]?\s*"#
    
    func parseLines(_ lines: [String]) -> [LineResult] {
        lines.map(parseLine)
    }
    
    func parseLine(_ line: String) -> LineResult {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return LineResult(
                rawLine: line,
                medicationName: nil,
                doseAmount: nil,
                unit: nil,
                scheduledTime: nil,
                remainingText: nil,
                directive: nil,
                state: .unparsed
            )
        }
        
        let stripped = stripLeadingNoise(from: normalizedUnits(in: trimmed))
        let (directive, directiveStripped) = leadingDirective(from: stripped)
        let timeMatch = firstMatch(of: Self.timePattern, in: directiveStripped)
        let doseMatch = directive?.isActiveDirective == false ? nil : firstMatch(of: Self.dosePattern, in: directiveStripped)
        let medicationName = medicationName(
            in: directiveStripped,
            doseMatch: doseMatch,
            timeMatch: timeMatch
        )
        let scheduledTime = timeMatch?.fullMatch
        let remainingText = remainingText(
            in: directiveStripped,
            medicationName: medicationName,
            doseMatch: doseMatch,
        )
        let hasMedicationName = !medicationName.isEmpty
        let isPartialDirectiveLine = directive != nil && hasMedicationName
        let hasStructuredDose = doseMatch != nil
        let shouldParse = hasMedicationName && (hasStructuredDose || isPartialDirectiveLine)

        return LineResult(
            rawLine: trimmed,
            medicationName: hasMedicationName ? medicationName : nil,
            doseAmount: doseMatch?.capture(at: 1),
            unit: doseMatch.flatMap { normalizedUnit($0.capture(at: 2)) },
            scheduledTime: scheduledTime,
            remainingText: remainingText,
            directive: directive,
            state: shouldParse ? .parsed : .unparsed
        )
    }
    
    private func normalizedUnits(in text: String) -> String {
        var normalized = text
        normalized = replacing(pattern: #"\b(?:lU|IU|iu|Lu)\b"#, with: "IU", in: normalized)
        normalized = replacing(pattern: #"\b(?:m1|ml|mL)\b"#, with: "mL", in: normalized)
        normalized = replacing(pattern: #"\b(?:μg|ug)\b"#, with: "mcg", in: normalized)
        normalized = replacing(pattern: #"\b(?:units?)\b"#, with: "IU", in: normalized)
        return normalized
    }
    
    private func stripLeadingNoise(from text: String) -> String {
        var current = text.trimmingCharacters(in: .whitespacesAndNewlines)

        while true {
            let stripped = replacing(pattern: Self.leadingBulletPattern, with: "", in: current)
            let dayStripped = replacing(pattern: Self.leadingDayPattern, with: "", in: stripped)
            if dayStripped == current {
                return current
            }
            current = dayStripped.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    private func leadingDirective(from text: String) -> (InstructionDirective?, String) {
        guard let match = firstMatch(of: Self.leadingDirectivePattern, in: text) else {
            return (nil, text)
        }

        let directiveString = String(text[match.range])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-:•,.;"))
        let directive = InstructionDirective(rawValue: directiveString.lowercased())
        let remainder = String(text[match.range.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-:•,.;"))
        return (directive, remainder)
    }

    private func medicationName(
        in text: String,
        doseMatch: RegexMatch?,
        timeMatch: RegexMatch?
    ) -> String {
        let baseText: String
        if let doseMatch {
            let beforeDose = String(text[..<doseMatch.range.lowerBound])
            let afterDose = String(text[doseMatch.range.upperBound...])
            let beforeDoseName = cleanedMedicationName(from: beforeDose)
            let afterDoseName = cleanedMedicationName(from: afterDose)
            baseText = beforeDoseName.isEmpty ? afterDoseName : beforeDoseName
        } else if let timeMatch {
            baseText = cleanedMedicationName(from: String(text[..<timeMatch.range.lowerBound]))
        } else {
            baseText = cleanedMedicationName(from: text)
        }

        return baseText
    }

    private func remainingText(
        in text: String,
        medicationName: String,
        doseMatch: RegexMatch?,
    ) -> String? {
        var textAfterRemoval = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let doseMatch {
            textAfterRemoval = String(textAfterRemoval[doseMatch.range.upperBound...])
        } else if let medicationRange = textAfterRemoval.range(of: medicationName, options: [.caseInsensitive]) {
            textAfterRemoval.removeSubrange(medicationRange)
        }

        textAfterRemoval = textAfterRemoval
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-:•,.;"))

        guard !textAfterRemoval.isEmpty else { return nil }

        return textAfterRemoval
    }

    private func cleanedMedicationName(from text: String) -> String {
        var candidate = text.trimmingCharacters(in: .whitespacesAndNewlines)
        candidate = candidate.trimmingCharacters(in: CharacterSet(charactersIn: "-:•,.;"))
        candidate = replacing(pattern: Self.leadingDirectivePattern, with: "", in: candidate)
        candidate = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        candidate = candidate.trimmingCharacters(in: CharacterSet(charactersIn: "-:•,.;"))
        return candidate
    }
    
    private func replacing(pattern: String, with replacement: String, in text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: replacement)
    }
    
    private func normalizedUnit(_ rawUnit: String?) -> String? {
        guard let rawUnit else { return nil }
        switch rawUnit.lowercased() {
        case "iu", "unit", "units":
            return "IU"
        case "mg":
            return "mg"
        case "mcg", "μg":
            return "mcg"
        case "g":
            return "g"
        case "ml":
            return "mL"
        case "m1":
            return "mL"
        default:
            return rawUnit
        }
    }
    
    private func firstMatch(of pattern: String, in text: String) -> RegexMatch? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: nsRange),
              let range = Range(match.range, in: text) else {
            return nil
        }
        return RegexMatch(text: text, match: match, range: range)
    }
}

private struct RegexMatch {
    let text: String
    let match: NSTextCheckingResult
    let range: Range<String.Index>
    
    var fullMatch: String {
        String(text[range])
    }
    
    func capture(at index: Int) -> String? {
        guard index < match.numberOfRanges else { return nil }
        let nsRange = match.range(at: index)
        guard nsRange.location != NSNotFound,
              let range = Range(nsRange, in: text) else {
            return nil
        }
        return String(text[range])
    }
}
