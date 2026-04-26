import Foundation

enum ProtocolDiffService {
    static func diff(previous: ProtocolDocument, current: ProtocolDocument) -> [ChangeItem] {
        let medicationChanges = diffMedications(previous: previous, current: current)
        let appointmentChanges = diffAppointments(previous: previous, current: current)

        return (medicationChanges + appointmentChanges)
            .sorted { lhs, rhs in
                if lhs.isCritical != rhs.isCritical {
                    return lhs.isCritical && !rhs.isCritical
                }
                if lhs.subjectType != rhs.subjectType {
                    return lhs.subjectType == .medication
                }
                return lhs.subjectName.localizedCaseInsensitiveCompare(rhs.subjectName) == .orderedAscending
            }
    }

    private static func diffMedications(previous: ProtocolDocument, current: ProtocolDocument) -> [ChangeItem] {
        let previousMedications = previous.parsedMedicationLines
        let currentMedications = current.parsedMedicationLines
        let previousMap = keyedMedicationMap(from: previousMedications)
        let currentMap = keyedMedicationMap(from: currentMedications)
        let allKeys = Set(previousMap.keys).union(currentMap.keys)

        return allKeys.compactMap { key in
            let oldMedication = previousMap[key]
            let newMedication = currentMap[key]

            switch (oldMedication, newMedication) {
            case let (nil, .some(newMedication)):
                return ChangeItem(
                    id: "added-\(newMedication.name.lowercased())",
                    type: .added,
                    subjectType: .medication,
                    subjectName: newMedication.name,
                    newValue: "\(newMedication.dose) at \(newMedication.time)",
                    isCritical: newMedication.isCritical
                )
            case let (.some(oldMedication), nil):
                return ChangeItem(
                    id: "stopped-\(oldMedication.name.lowercased())",
                    type: .stopped,
                    subjectType: .medication,
                    subjectName: oldMedication.name,
                    oldValue: "\(oldMedication.dose) at \(oldMedication.time)",
                    isCritical: oldMedication.isCritical
                )
            case let (.some(oldMedication), .some(newMedication)):
                if oldMedication.dose != newMedication.dose {
                    return ChangeItem(
                        id: "dose-\(newMedication.name.lowercased())",
                        type: .doseChanged,
                        subjectType: .medication,
                        subjectName: newMedication.name,
                        oldValue: oldMedication.dose,
                        newValue: newMedication.dose,
                        isCritical: newMedication.isCritical
                    )
                }

                if oldMedication.time != newMedication.time {
                    return ChangeItem(
                        id: "time-\(newMedication.name.lowercased())",
                        type: .timeChanged,
                        subjectType: .medication,
                        subjectName: newMedication.name,
                        oldValue: oldMedication.time,
                        newValue: newMedication.time,
                        isCritical: newMedication.isCritical
                    )
                }

                if oldMedication.route != newMedication.route || oldMedication.instructions != newMedication.instructions {
                    return ChangeItem(
                        id: "details-\(newMedication.name.lowercased())",
                        type: .detailsChanged,
                        subjectType: .medication,
                        subjectName: newMedication.name,
                        oldValue: "\(oldMedication.route) • \(oldMedication.instructions)",
                        newValue: "\(newMedication.route) • \(newMedication.instructions)",
                        isCritical: newMedication.isCritical
                    )
                }

                return nil
            case (nil, nil):
                return nil
            }
        }
    }

    private static func diffAppointments(previous: ProtocolDocument, current: ProtocolDocument) -> [ChangeItem] {
        let previousMap = keyedAppointmentMap(from: previous.parsedAppointmentItems)
        let currentMap = keyedAppointmentMap(from: current.parsedAppointmentItems)
        let allKeys = Set(previousMap.keys).union(currentMap.keys)

        return allKeys.compactMap { key in
            let oldAppointment = previousMap[key]
            let newAppointment = currentMap[key]

            switch (oldAppointment, newAppointment) {
            case let (nil, .some(newAppointment)):
                return ChangeItem(
                    id: "appointment-added-\(key)",
                    type: .added,
                    subjectType: .appointment,
                    subjectName: newAppointment.title,
                    newValue: appointmentDescription(for: newAppointment),
                    isCritical: newAppointment.isCritical
                )
            case let (.some(oldAppointment), nil):
                return ChangeItem(
                    id: "appointment-stopped-\(key)",
                    type: .stopped,
                    subjectType: .appointment,
                    subjectName: oldAppointment.title,
                    oldValue: appointmentDescription(for: oldAppointment),
                    isCritical: oldAppointment.isCritical
                )
            case let (.some(oldAppointment), .some(newAppointment)):
                if oldAppointment.scheduledTimeText != newAppointment.scheduledTimeText {
                    return ChangeItem(
                        id: "appointment-time-\(key)",
                        type: .timeChanged,
                        subjectType: .appointment,
                        subjectName: newAppointment.title,
                        oldValue: oldAppointment.scheduledTimeText ?? "Not set",
                        newValue: newAppointment.scheduledTimeText ?? "Not set",
                        isCritical: newAppointment.isCritical
                    )
                }

                if oldAppointment.locationText != newAppointment.locationText
                    || oldAppointment.title != newAppointment.title
                    || oldAppointment.kind != newAppointment.kind {
                    return ChangeItem(
                        id: "appointment-details-\(key)",
                        type: .detailsChanged,
                        subjectType: .appointment,
                        subjectName: newAppointment.title,
                        oldValue: appointmentDescription(for: oldAppointment),
                        newValue: appointmentDescription(for: newAppointment),
                        isCritical: newAppointment.isCritical
                    )
                }

                return nil
            case (nil, nil):
                return nil
            }
        }
    }

    private static func stableMedicationKey(for medication: ProtocolDocument.ParsedMedicationLine) -> String {
        medication.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func keyedMedicationMap(
        from medications: [ProtocolDocument.ParsedMedicationLine]
    ) -> [String: ProtocolDocument.ParsedMedicationLine] {
        medications.reduce(into: [:]) { partialResult, medication in
            partialResult[stableMedicationKey(for: medication)] = medication
        }
    }

    private static func stableAppointmentKey(for appointment: AppointmentItem) -> String {
        let normalizedTitle = appointment.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedKind = appointment.kind.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return "\(normalizedKind)|\(normalizedTitle)"
    }

    private static func keyedAppointmentMap(from appointments: [AppointmentItem]) -> [String: AppointmentItem] {
        appointments.reduce(into: [:]) { partialResult, appointment in
            partialResult[stableAppointmentKey(for: appointment)] = appointment
        }
    }

    private static func appointmentDescription(for appointment: AppointmentItem) -> String {
        let time = appointment.scheduledTimeText ?? "Time TBD"
        let location = appointment.locationText?.isEmpty == false ? appointment.locationText! : "Location TBD"
        return "\(time) • \(location)"
    }
}
