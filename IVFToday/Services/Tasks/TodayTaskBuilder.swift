import Foundation

struct TodayTaskBuilder {
    func build(medications: [MedicationPlan], appointments: [AppointmentItem]) -> [TodayTask] {
        let medicationTasks = medications
            .filter(\.isActive)
            .map { medication in
                let risk: TaskRiskLevel = medication.isCritical ? .high : .medium
                return TodayTask(
                    id: medication.id,
                    sourceID: medication.id,
                    sourceType: .medication,
                    title: medication.name,
                    subtitle: medication.summaryLine,
                    scheduledTime: medication.scheduledTime,
                    scheduledDate: parseClockTime(medication.scheduledTime),
                    urgency: urgency(for: risk, source: .medication, appointmentKind: nil),
                    riskLevel: risk
                )
            }

        let appointmentTasks = appointments.map { appointment in
            let risk: TaskRiskLevel = appointment.isCritical ? .high : inferredRisk(for: appointment.kind)
            let scheduledTimeText = appointment.scheduledTimeText ?? "No time"
            let location = (appointment.locationText?.isEmpty == false) ? " • \(appointment.locationText ?? "")" : ""
            return TodayTask(
                id: appointment.id,
                sourceID: appointment.id,
                sourceType: .appointment,
                title: appointment.title,
                subtitle: "\(appointment.kind.capitalized)\(location)",
                scheduledTime: scheduledTimeText,
                scheduledDate: appointment.scheduledDate ?? parseClockTime(scheduledTimeText),
                urgency: urgency(for: risk, source: .appointment, appointmentKind: appointment.kind),
                riskLevel: risk
            )
        }

        return (medicationTasks + appointmentTasks).sorted(by: compare)
    }

    private func compare(_ lhs: TodayTask, _ rhs: TodayTask) -> Bool {
        if lhs.urgency != rhs.urgency {
            return lhs.urgency.rawValue > rhs.urgency.rawValue
        }
        if lhs.riskLevel != rhs.riskLevel {
            return riskPriority(lhs.riskLevel) > riskPriority(rhs.riskLevel)
        }
        switch (lhs.scheduledDate, rhs.scheduledDate) {
        case let (left?, right?):
            if left != right {
                return left < right
            }
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            break
        }
        if lhs.scheduledTime != rhs.scheduledTime {
            return lhs.scheduledTime < rhs.scheduledTime
        }
        return lhs.title < rhs.title
    }

    private func riskPriority(_ risk: TaskRiskLevel) -> Int {
        switch risk {
        case .high:
            return 2
        case .medium:
            return 1
        case .low:
            return 0
        }
    }

    private func urgency(for risk: TaskRiskLevel, source: TodayTaskSourceType, appointmentKind: String?) -> TaskUrgency {
        if risk == .high {
            return .high
        }
        if source == .appointment {
            let normalizedKind = appointmentKind?.lowercased() ?? ""
            if normalizedKind.contains("retrieval") || normalizedKind.contains("transfer") || normalizedKind.contains("trigger") {
                return .high
            }
            if normalizedKind.contains("monitoring") || normalizedKind.contains("lab") {
                return .medium
            }
            return .low
        }
        return .medium
    }

    private func inferredRisk(for appointmentKind: String) -> TaskRiskLevel {
        let normalizedKind = appointmentKind.lowercased()
        if normalizedKind.contains("retrieval") || normalizedKind.contains("transfer") || normalizedKind.contains("trigger") {
            return .high
        }
        if normalizedKind.contains("monitoring") || normalizedKind.contains("lab") {
            return .medium
        }
        return .low
    }

    private func parseClockTime(_ value: String) -> Date? {
        let formats = ["h:mm a", "h a", "H:mm", "HH:mm"]
        let calendar = Calendar(identifier: .gregorian)
        let baseDate = calendar.startOfDay(for: Date())
        let candidate = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            if let parsed = formatter.date(from: candidate) {
                let components = calendar.dateComponents([.hour, .minute], from: parsed)
                return calendar.date(byAdding: components, to: baseDate)
            }
        }
        return nil
    }
}
