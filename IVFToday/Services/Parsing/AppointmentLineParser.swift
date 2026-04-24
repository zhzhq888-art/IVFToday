import Foundation

struct AppointmentLineParser {
    enum ParseState {
        case parsed
        case unparsed
    }

    struct LineResult {
        let rawLine: String
        let title: String?
        let kind: String?
        let scheduledTimeText: String?
        let locationText: String?
        let isCritical: Bool
        let state: ParseState
    }

    private struct KeywordRule {
        let pattern: String
        let kind: String
        let title: String
        let isCritical: Bool
    }

    private let keywordRules: [KeywordRule] = [
        .init(pattern: #"\ber\b"#, kind: "retrieval", title: "Egg retrieval", isCritical: true),
        .init(pattern: #"\begg\s+retrieval\b|\bretrieval\b"#, kind: "retrieval", title: "Egg retrieval", isCritical: true),
        .init(pattern: #"\bet\b"#, kind: "transfer", title: "Embryo transfer", isCritical: true),
        .init(pattern: #"\bembryo\s+transfer\b|\btransfer\b"#, kind: "transfer", title: "Embryo transfer", isCritical: true),
        .init(pattern: #"\bbeta\b|\bbeta\s+blood\b|\bblood\s+test\b"#, kind: "lab", title: "Beta blood test", isCritical: true),
        .init(pattern: #"\bu/?s\b"#, kind: "monitoring", title: "Ultrasound monitoring", isCritical: false),
        .init(pattern: #"\bultrasound\b|\bscan\b"#, kind: "monitoring", title: "Ultrasound monitoring", isCritical: false),
        .init(pattern: #"\bmonitoring\b"#, kind: "monitoring", title: "Monitoring appointment", isCritical: false),
        .init(pattern: #"\bbloodwork\b|\bblood\s+draw\b|\blabs?\b"#, kind: "lab", title: "Bloodwork", isCritical: false),
        .init(pattern: #"\bappointment\b|\bvisit\b|\bclinic\b|\bcheck[- ]?in\b"#, kind: "appointment", title: "Clinic appointment", isCritical: false)
    ]

    private static let timePattern = #"\b(?:[01]?\d|2[0-3]):[0-5]\d\s*(?:AM|PM|am|pm)?\b|\b(?:1[0-2]|0?[1-9])\s*(?:AM|PM|am|pm)\b|\b(?:today|tomorrow|tonight|this\s+morning|this\s+afternoon|this\s+evening)\b"#
    private static let locationPattern = #"(?i)(?:\b(?:at|in)\s+|@\s*)([A-Za-z0-9][A-Za-z0-9 .&'/-]{2,})$"#
    private static let leadingNoisePattern = #"^\s*(?:[-•*]+|\d+[.)])\s*"#

    func parseLines(_ lines: [String]) -> [LineResult] {
        lines.map(parseLine)
    }

    func parseLine(_ line: String) -> LineResult {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .init(
                rawLine: line,
                title: nil,
                kind: nil,
                scheduledTimeText: nil,
                locationText: nil,
                isCritical: false,
                state: .unparsed
            )
        }

        let normalized = stripLeadingNoise(from: trimmed)
        guard let matchedRule = keywordRules.first(where: { contains(pattern: $0.pattern, in: normalized) }) else {
            return .init(
                rawLine: trimmed,
                title: nil,
                kind: nil,
                scheduledTimeText: nil,
                locationText: nil,
                isCritical: false,
                state: .unparsed
            )
        }

        let parsedTime = firstMatch(of: Self.timePattern, in: normalized)
        let parsedLocation = captureGroup(of: Self.locationPattern, in: normalized, index: 1)
        let cleanedTitle = inferTitle(from: normalized, fallbackTitle: matchedRule.title)

        return .init(
            rawLine: trimmed,
            title: cleanedTitle,
            kind: matchedRule.kind,
            scheduledTimeText: parsedTime,
            locationText: parsedLocation,
            isCritical: matchedRule.isCritical,
            state: .parsed
        )
    }

    func mapToAppointments(from results: [LineResult]) -> [AppointmentItem] {
        results
            .filter { $0.state == .parsed }
            .map { result in
                AppointmentItem(
                    title: result.title ?? "Appointment",
                    scheduledDate: nil,
                    scheduledTimeText: result.scheduledTimeText,
                    locationText: result.locationText,
                    kind: result.kind ?? "appointment",
                    isCritical: result.isCritical,
                    sourceLine: result.rawLine
                )
            }
    }

    private func inferTitle(from text: String, fallbackTitle: String) -> String {
        var candidate = text
        candidate = replacing(pattern: Self.timePattern, with: "", in: candidate)
        candidate = replacing(pattern: #"\b(?:today|tomorrow|tonight|this\s+morning|this\s+afternoon|this\s+evening)\b"#, with: "", in: candidate)
        candidate = replacing(pattern: #"(?:\b(?:at|in)\s+|@\s*)[A-Za-z0-9][A-Za-z0-9 .&'/-]{2,}$"#, with: "", in: candidate)
        candidate = candidate
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-:•,.;"))

        if candidate.isEmpty || isAbbreviationCandidate(candidate) || startsWithKnownAppointmentAbbreviation(candidate) {
            return fallbackTitle
        }
        return candidate
    }

    private func isAbbreviationCandidate(_ candidate: String) -> Bool {
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= 4 else {
            return false
        }
        return trimmed.range(of: #"^[A-Za-z/]+$"#, options: .regularExpression) != nil
    }

    private func startsWithKnownAppointmentAbbreviation(_ candidate: String) -> Bool {
        candidate.range(of: #"^(?i)(et|er|u/?s)\b"#, options: .regularExpression) != nil
    }

    private func stripLeadingNoise(from text: String) -> String {
        replacing(pattern: Self.leadingNoisePattern, with: "", in: text)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func contains(pattern: String, in text: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return false
        }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, options: [], range: nsRange) != nil
    }

    private func firstMatch(of pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        guard
            let match = regex.firstMatch(in: text, options: [], range: nsRange),
            let range = Range(match.range, in: text)
        else {
            return nil
        }
        return String(text[range])
    }

    private func captureGroup(of pattern: String, in text: String, index: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: nsRange) else {
            return nil
        }
        guard index < match.numberOfRanges else {
            return nil
        }
        let captureRange = match.range(at: index)
        guard captureRange.location != NSNotFound, let range = Range(captureRange, in: text) else {
            return nil
        }
        let captured = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        return captured.isEmpty ? nil : captured
    }

    private func replacing(pattern: String, with replacement: String, in text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return text
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: replacement)
    }
}
